// 时间倍率与迁移使用隔离 JSON，核对阶段、进度、未来时间线和持久化，不触碰真实存档。
import Foundation
import Testing

@Suite(.serialized)
struct GrowthMultiplierTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)
    private let day = 86_400.0

    @Test
    func defaultsMultiplyTimeAndEverySpeciesHasAnIntervalProfile() {
        let garden = SucculentGarden()
        for (type, x) in [(SucculentMorphology.crassulaceaeType, 1.0), (.stonecropType, 0.5), (.yuzhuiType, 0.75), (.guanyinType, 0.75), (.conophytumType, 2)] {
            #expect(garden.growthMultipliers.x(for: type) == x)
        }
        #expect(garden.growthMultipliers.y(for: .huangli) == 1)
        #expect(garden.growthMultipliers.y(for: .chihuahua) == 1.25)
        #expect(garden.growthMultipliers.y(for: .lithops) == 3)
        for species in SucculentSpecies.allCases {
            let plant = plant(species)
            let rate = garden.effectiveRate(for: species)
            let dates = plant.transitionDates(after: date, rate: rate)
            for (index, transition) in dates.enumerated() {
                let stage = species.stages[index + 1]
                let expected = species.startSeconds(for: stage) * garden.growthMultipliers.x(for: species.morphology) * garden.growthMultipliers.y(for: species)
                #expect(abs(transition.timeIntervalSince(date) - expected) < 0.001)
                #expect(plant.stage(at: transition.addingTimeInterval(-1), rate: rate) == species.stages[index])
                #expect(plant.stage(at: transition, rate: rate) == stage)
            }
        }
    }

    @Test
    func editedMultipliersOnlyAffectSelectedTypesAndSpecies() {
        var garden = SucculentGarden()
        garden.growthRate = 10
        garden.growthMultipliers.morphology[SucculentMorphology.crassulaceaeType.rawValue] = 2
        garden.growthMultipliers.species[SucculentSpecies.huangli.rawValue] = 3
        #expect(garden.effectiveRate(for: .huangli) == 10.0 / 6)
        #expect(garden.effectiveRate(for: .chihuahua) == 10.0 / 2.5)
        #expect(garden.effectiveRate(for: .snowStonecrop) == 20)
        let interval = GardenGrowthTime.interval(species: .huangli, from: .sprout, to: .juvenile, rate: garden.effectiveRate(for: .huangli))
        #expect(interval == day * 6 / 10)
        #expect(GardenGrowthTime.remaining(for: plant(.huangli), at: date, rate: garden.effectiveRate(for: .huangli)) == interval)
    }

    @Test
    func changingBothLayersAndGlobalRatePreservesProgressAndWallet() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let raw = try #require((try await store.claimLeaf(species: .guanyin, at: date)).leaves.last)
        _ = try await store.sow(leafID: raw.id, in: 1, at: date)
        let changeDate = date.addingTimeInterval(day * 0.375)
        var settings = GardenGrowthMultipliers()
        settings.morphology[SucculentMorphology.guanyinType.rawValue] = 1.5
        settings.species[SucculentSpecies.guanyin.rawValue] = 2
        let changed = try await store.changeMultipliers(to: settings, at: changeDate)
        let before = try #require(changed.plant(in: 1))
        #expect(before.growthSeconds == day / 2)
        #expect(changed.money == 10 && changed.claimedToday == 1 && changed.growthRate == 1)
        let later = changeDate.addingTimeInterval(day / 2)
        let faster = try await store.changeRate(to: 10, at: later)
        let after = try #require(faster.plant(in: 1))
        #expect(abs(after.growthSeconds - day * 2 / 3) < 0.001)
        #expect(faster.growthMultipliers == settings)
        #expect(try await SucculentStore(fileURL: url).read() == faster)
        let remaining = try #require(GardenGrowthTime.remaining(for: after, at: later, rate: faster.effectiveRate(for: .guanyin)))
        #expect(abs(remaining - day / 10) < 0.001)
        let reset = try await store.changeMultipliers(to: .init(), at: later)
        #expect(reset.plants == faster.plants && reset.slots == faster.slots)
        #expect(reset.growthMultipliers.x(for: .guanyinType) == 0.75)
    }

    @Test
    func schemaFourUpgradeSettlesOldOfflineTimeBeforeApplyingNewMultipliers() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        var old = SucculentGarden()
        old.version = 4
        old.plants = [plant(.snowStonecrop), plant(.chihuahua), plant(.yuzhui)]
        old.slots = old.plants.map { $0.id }
        old.money = 37
        old.claimDate = date
        old.claimedToday = 5
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
        object.removeValue(forKey: "growthMultipliers")
        let bytes = try JSONSerialization.data(withJSONObject: object)
        try bytes.write(to: url)
        let upgradeDate = date.addingTimeInterval(day / 2)
        let store = SucculentStore(fileURL: url)
        let preview = try await store.read(at: upgradeDate)
        #expect(try Data(contentsOf: url) == bytes)
        #expect(preview.version == 8 && preview.slots == old.slots && preview.money == 37 && preview.claimedToday == 5)
        for (previous, migrated) in zip(old.plants, preview.plants) {
            #expect(previous.id == migrated.id && migrated.growthUpdatedAt == upgradeDate)
            #expect(migrated.growthSeconds == day / 2)
            #expect(migrated.stage(at: upgradeDate, rate: preview.effectiveRate(for: migrated.species)) == previous.stage(at: upgradeDate, rate: old.growthRate))
        }
        let saved = try await store.read(createIfMissing: true, at: upgradeDate)
        let reopened = try await SucculentStore(fileURL: url).read()
        #expect(saved == preview && reopened == saved)
        #expect(saved.plant(in: 0)?.transitionDates(after: upgradeDate, rate: saved.effectiveRate(for: .snowStonecrop)).first == upgradeDate.addingTimeInterval(day / 4))
    }

    @Test
    func invalidMultipliersCannotRewriteStorage() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        _ = try await store.read(createIfMissing: true)
        let bytes = try Data(contentsOf: url)
        for value in [0.0, -1, .infinity, .nan, 101] {
            var settings = GardenGrowthMultipliers()
            settings.species[SucculentSpecies.huangli.rawValue] = value
            await #expect(throws: GardenError.self) { try await store.changeMultipliers(to: settings, at: date) }
            #expect(try Data(contentsOf: url) == bytes)
        }
        var unknown = GardenGrowthMultipliers()
        unknown.morphology["unknown"] = 1
        await #expect(throws: GardenError.self) { try await store.changeMultipliers(to: unknown, at: date) }
        #expect(try Data(contentsOf: url) == bytes)
    }

    private func plant(_ species: SucculentSpecies) -> SucculentPlant {
        .init(id: UUID(), acquiredAt: date, growthSeconds: 0, growthUpdatedAt: date, species: species)
    }

    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
