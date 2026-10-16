// 玉坠五期、免费小草与旧四期升级；只使用隔离临时文件。
import Foundation
import Testing

@Suite(.serialized)
struct YuzhuiTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 86_400

    @Test
    func leafSproutsAndFreeSmallPlantsFollowFiveStages() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        #expect(SucculentSpecies.yuzhui.morphology == .yuzhuiType)
        #expect(SucculentSpecies.yuzhui.propagationTitle == "叶片")
        #expect(SucculentSpecies.yuzhui.stages.map(\.title) == ["叶插小芽", "小草", "群生", "草丛", "爆盆"])
        let leaf = try #require((try await store.claimLeaf(species: .yuzhui, at: date)).leaves.last)
        let planted = try await store.sow(leafID: leaf.id, in: 0, at: date)
        let plant = try #require(planted.plant(in: 0))
        for (index, days) in [0.0, 1, 2, 5, 10].enumerated() {
            let boundary = date.addingTimeInterval(days * day)
            #expect(plant.stage(at: boundary, rate: 1) == SucculentSpecies.yuzhui.stages[index])
            if index > 0 { #expect(plant.stage(at: boundary.addingTimeInterval(-1), rate: 1) == SucculentSpecies.yuzhui.stages[index - 1]) }
        }
        #expect(plant.transitionDates(after: date, rate: 1) == [1.0, 2, 5, 10].map { date.addingTimeInterval($0 * day) })
        let free = try await store.buy(stage: .grassSprout, species: .yuzhui, at: date)
        #expect(free.money == 10 && free.claimedToday == 2)
        let received = try #require(free.unplacedPlants.last)
        #expect(free.slots == planted.slots && received.stage(at: date, rate: 1) == .grassSprout)
        #expect(!received.isGrowing && received.transitionDates(after: date, rate: 1).isEmpty)
        #expect(try await SucculentStore(fileURL: url).read() == free)
    }

    @Test
    func freePlantsShareTheFiveClaimsAndCannotBypassTheLimit() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        _ = try await store.claimLeaf(species: .yuzhui, at: date)
        _ = try await store.buy(stage: .grassSprout, species: .yuzhui, at: date)
        _ = try await store.claimLeaf(species: .snowStonecrop, at: date)
        _ = try await store.claimLeaf(at: date)
        let fifth = try await store.buy(stage: .grassSprout, species: .yuzhui, at: date)
        #expect(fifth.claimedToday == 5 && fifth.money == 10)
        let bytes = try Data(contentsOf: url)
        await #expect(throws: GardenError.self) { try await store.buy(stage: .grassSprout, species: .yuzhui, at: date) }
        await #expect(throws: GardenError.self) { try await store.claimLeaf(species: .yuzhui, at: date) }
        #expect(try Data(contentsOf: url) == bytes)
        let nextDay = try await store.buy(stage: .grassSprout, species: .yuzhui, at: date.addingTimeInterval(day))
        #expect(nextDay.claimedToday == 1 && nextDay.plants.count == 3 && nextDay.money == 10)
    }

    @Test
    func freeSmallPlantGoesToCollectionAndLeavesOccupiedPotsAlone() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SucculentStore(fileURL: directory.appendingPathComponent("garden.json"))
        for slot in 0..<3 {
            let bought = try await store.buy(stage: .juvenile, at: date)
            _ = try await store.assign(plantID: try #require(bought.plants.last).id, to: slot)
        }
        let before = try await store.read()
        let received = try await store.buy(stage: .grassSprout, species: .yuzhui, at: date)
        #expect(received.slots == before.slots)
        #expect(received.money == before.money && received.claimedToday == before.claimedToday + 1)
        #expect(received.unplacedPlants.count == 1 && received.unplacedPlants.first?.species == .yuzhui)
        #expect(received.plants.count == before.plants.count + 1)
        #expect(try await store.read() == received)
    }

    @Test
    func oldYuzhuiStagesAndPartialGrowthSurviveMigrationAndReopening() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        var old = SucculentGarden()
        old.version = 3
        old.money = 27
        old.claimDate = date
        old.claimedToday = 4
        old.leaves = [SucculentLeaf(id: UUID(), claimedAt: date, species: .yuzhui)]
        old.plants = [0.0, 0.5, 1, 2, 4, 6, 9].map {
            SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: $0 * day, growthUpdatedAt: date, species: .yuzhui)
        }
        old.slots = Array(old.plants.prefix(3).map { Optional($0.id) })
        try JSONEncoder().encode(old).write(to: url)
        let original = try Data(contentsOf: url)
        let store = SucculentStore(fileURL: url)
        let migrated = try await store.read()
        #expect(try Data(contentsOf: url) == original)
        #expect(migrated.version == 8 && migrated.money == old.money && migrated.leaves == old.leaves)
        #expect(migrated.claimDate == old.claimDate && migrated.claimedToday == 4 && migrated.slots == old.slots)
        for (before, after) in zip(old.plants, migrated.plants) {
            #expect(after.id == before.id && after.growthUpdatedAt == before.growthUpdatedAt)
            #expect(after.growthSeconds == before.growthSeconds + day)
            for elapsed in [0.0, 0.4, 2, 30] {
                let age = min(9 * day, before.growthSeconds + (after.isGrowing ? elapsed * day : 0))
                let stage = SucculentStage.at(growthSeconds: age, stages: SucculentStage.stonecropStages)
                #expect(after.stage(at: date.addingTimeInterval(elapsed * day), rate: 1) == stage)
            }
        }
        #expect(try await store.read(createIfMissing: true) == migrated)
        #expect(try await SucculentStore(fileURL: url).read() == migrated)
    }

    @Test
    func paidStagesKeepTheirPricesAndSales() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        var funded = SucculentGarden()
        funded.money = 100 // 明确隔离的测试资金，不接触真实钱包。
        try JSONEncoder().encode(funded).write(to: url)
        let store = SucculentStore(fileURL: url)
        for (stage, buy, sell) in [(SucculentStage.grassCluster, 3, 2), (.grassClump, 10, 5), (.grassOverflow, 20, 10)] {
            let before = try await store.read()
            let bought = try await store.buy(stage: stage, species: .yuzhui, at: date)
            let plant = try #require(bought.plants.last)
            #expect(bought.money == before.money - buy && plant.stage(at: date, rate: 1) == stage)
            let sold = try await store.sell(plantID: plant.id, at: date)
            #expect(sold.money == bought.money + sell && sold.claimedToday == 0)
            await #expect(throws: GardenError.self) { try await store.sell(plantID: plant.id, at: date) }
        }
        let leaf = try #require((try await store.claimLeaf(species: .yuzhui, at: date)).leaves.last)
        let seed = try await store.sow(leafID: leaf.id, in: 0, at: date)
        let seedID = try #require(seed.plant(in: 0)).id
        #expect((try await store.sell(plantID: seedID, at: date)).money == seed.money + 1)
        let free = try await store.buy(stage: .grassSprout, species: .yuzhui, at: date)
        let freeID = try #require(free.unplacedPlants.last).id
        #expect((try await store.sell(plantID: freeID, at: date)).money == free.money + 1)
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
