// 新型材料、晚期分头与不死鸟摘芽；临时文件隔离，绝不消耗用户库存。
import Foundation
import Testing

@Suite(.serialized)
struct ExpansionMechanismTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func catalogContainsAllAdditionsAndKeepsExistingVarietiesUnique() {
        #expect(SucculentExpansionCatalog.entries.count == 100)
        #expect(SucculentSpecies.allCases.count == 115)
        #expect(SucculentSpecies.allCases.filter { $0.title == "白月影" }.count == 1)
        #expect(SucculentSpecies.allCases.filter { $0.title == "千佛手" }.count == 1)
        #expect(SucculentSpecies.jadeFan.title == "玉扇")
        #expect(SucculentSpecies.cobwebHouseleek.title == "蛛丝卷绢")
        #expect(SucculentSpecies.allCases.filter { $0.morphology == .haworthiaType }.count == 15)
        #expect(SucculentSpecies.allCases.filter { $0.morphology == .cactusType }.count == 6)
        #expect(SucculentSpecies.fireFestival.morphology == .yuzhuiType)
        #expect(SucculentSpecies.gollumJade.morphology == .yuzhuiType)
    }

    @Test
    func materialsUseTheGlobalLimitAndPlantAsTheirOwnSpecies() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SucculentStore(fileURL: directory.appendingPathComponent("garden.json"))
        for species in [SucculentSpecies.iceLantern, .smallCactusBall, .moneyStack, .broadMother, .tubeMother] {
            let claimed = try await store.claimLeaf(species: species, at: date)
            let material = try #require(claimed.leaves.last)
            let state = try await store.sow(leafID: material.id, in: 0, at: date)
            #expect(state.plant(in: 0)?.species == species && state.leaves.isEmpty)
            #expect(state.money == 10)
        }
        await #expect(throws: GardenError.self) { try await store.claimLeaf(species: .narrowMother, at: date) }
        let saved = try await store.read()
        #expect(saved.claimedToday == 5 && saved.plants.count == 5)
        #expect(SucculentSpecies.iceLantern.propagationTitle == "小苗")
        #expect(SucculentSpecies.smallCactusBall.propagationTitle == "芽块")
        #expect(SucculentSpecies.bearPaw.propagationTitle == "枝条")
        #expect(SucculentSpecies.broadMother.propagationTitle == "小芽")
    }

    @Test
    func jadeRosettesCannotSplitAndHardLeafExceptionsKeepTheirOldRule() {
        for species in SucculentSpecies.allCases where species.morphology == .haworthiaType {
            #expect(species.stages.map { species.stageTitle(for: $0) } == ["小苗", "幼年", "成年", "壮年", "老桩"])
            let finalCount: Int? = [.jadeFan, .zebraHaworthia].contains(species) ? 5 : nil
            #expect(species.stages.map { species.disassemblyCount(for: $0) } == [nil, nil, nil, nil, finalCount])
        }
        #expect(SucculentSpecies.guanyin.disassemblyCount(for: .offsetCluster) == 3)
    }

    @Test
    func cactusBudIsTheOnlyFreeStageAndLaterSplitsUseBudBlocks() {
        let species = SucculentSpecies.smallCactusBall
        #expect(species.stages.map(\.title) == ["芽块", "幼年", "成年", "群生", "爆盆"])
        #expect(species.stages.map { species.purchasePrice(for: $0) } == [nil, 3, 10, 20, 50])
        #expect(species.stages.map(\.salePrice) == [1, 1, 2, 5, 10])
        #expect(species.stages.map { species.startSeconds(for: $0) / 86_400 } == [0, 1, 2, 5, 10])
        #expect(species.stages.map { species.disassemblyCount(for: $0) } == [nil, 3, 5, 8, 12])
    }

    @Test
    func harvestPreservesMotherAndSlotsAndDoesNotUseClaimQuota() async throws {
        for species in [SucculentSpecies.broadMother, .tubeMother, .narrowMother] {
            for (stage, count) in [(SucculentStage.motherAdult, 10), (.motherPrime, 20), (.motherOldStem, 35), (.motherCluster, 50)] {
                let directory = try directory()
                defer { try? FileManager.default.removeItem(at: directory) }
                let url = directory.appendingPathComponent("garden.json")
                let original = planted(species, stage)
                try JSONEncoder().encode(original).write(to: url)
                let store = SucculentStore(fileURL: url)
                let id = original.plants[0].id
                let harvested = try await store.harvest(plantID: id, at: date)
                #expect(harvested.plants.count == 1 && harvested.slots == original.slots)
                #expect(harvested.plants[0].growthSeconds == original.plants[0].growthSeconds)
                #expect(harvested.plants[0].lastHarvestedAt == date)
                #expect(harvested.leaves.count == count && Set(harvested.leaves.map(\.id)).count == count)
                #expect(harvested.leaves.allSatisfy { $0.species == species })
                #expect(harvested.claimedToday == 5 && harvested.claimDate == original.claimDate && harvested.money == 23)
                #expect(try await SucculentStore(fileURL: url).read() == harvested)
                let removed = try await store.disassemble(plantID: id, at: date)
                #expect(removed.plants.isEmpty && removed.slots == [nil, nil, nil])
                #expect(removed.leaves.count == count * 2 && removed.claimedToday == 5 && removed.money == 23)
            }
        }
    }

    @Test
    func harvestCooldownSurvivesReopeningAndIgnoresGrowthSpeed() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let original = planted(.broadMother, .motherCluster)
        try JSONEncoder().encode(original).write(to: url)
        let store = SucculentStore(fileURL: url)
        let id = original.plants[0].id
        _ = try await store.harvest(plantID: id, at: date)
        _ = try await store.changeRate(to: 1000, at: date)
        let bytes = try Data(contentsOf: url)
        await #expect(throws: GardenError.self) { try await store.harvest(plantID: id, at: date.addingTimeInterval(86_399)) }
        #expect(try Data(contentsOf: url) == bytes)
        let second = try await SucculentStore(fileURL: url).harvest(plantID: id, at: date.addingTimeInterval(86_400))
        #expect(second.leaves.count == 100 && second.plants.count == 1 && second.claimedToday == 5)
        #expect(second.plants[0].nextHarvestDate() == date.addingTimeInterval(172_800))
    }

    @Test
    func concurrentHarvestOnlyReturnsOneBatchAndEarlyPlantsAreRejected() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let original = planted(.broadMother, .motherAdult)
        try JSONEncoder().encode(original).write(to: url)
        let store = SucculentStore(fileURL: url)
        let id = original.plants[0].id
        let successes = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<2 { group.addTask {
                do { _ = try await store.harvest(plantID: id, at: date); return true }
                catch { return false }
            } }
            var count = 0
            for await success in group { if success { count += 1 } }
            return count
        }
        let result = try await store.read()
        #expect(successes == 1 && result.leaves.count == 10)
        for (species, stage) in [(SucculentSpecies.broadMother, SucculentStage.motherYoung), (.iceLantern, .offsetOldStem)] {
            let state = planted(species, stage)
            try JSONEncoder().encode(state).write(to: url)
            let bytes = try Data(contentsOf: url)
            await #expect(throws: GardenError.self) { try await store.harvest(plantID: state.plants[0].id, at: date) }
            #expect(try Data(contentsOf: url) == bytes)
        }
    }

    @Test
    func versionFiveMigrationDoesNotRecalculateExistingProgressOrMoney() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        var old = planted(.yuzhui, .grassCluster)
        old.version = 5
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: url)
        let store = SucculentStore(fileURL: url)
        let migrated = try await store.read(at: date.addingTimeInterval(100 * 86_400))
        #expect(migrated.version == 9 && migrated.plants == old.plants && migrated.money == old.money)
        #expect(migrated.slots == old.slots && migrated.claimedToday == old.claimedToday)
        #expect(try Data(contentsOf: url) == bytes)
        #expect(try await store.read(createIfMissing: true) == migrated)
    }

    private func planted(_ species: SucculentSpecies, _ stage: SucculentStage) -> SucculentGarden {
        var state = SucculentGarden()
        let plant = SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: species.startSeconds(for: stage), growthUpdatedAt: date, species: species)
        state.plants = [plant]
        state.slots = [plant.id, nil, nil]
        state.money = 23
        state.claimedToday = 5
        state.claimDate = date
        return state
    }

    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
