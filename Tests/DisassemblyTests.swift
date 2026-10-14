// 拆分按真实阶段返还同种材料，消耗一次植株，保持钱包与免费领取额度。
import Foundation
import Testing

@Suite(.serialized)
struct DisassemblyTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func everySpeciesReturnsTheRequiredMaterialCountsAndSurvivesReopening() async throws {
        for species in SucculentSpecies.allCases {
            let stages: [(SucculentStage, Int)]
            switch species.morphology {
            case .crassulaceaeType: stages = [(.juvenile, 3), (.adult, 5), (.prime, 8), (.oldStem, 12), (.cluster, 15)]
            case .stonecropType: stages = [(.grassCluster, 5), (.grassClump, 10), (.grassOverflow, 15)]
            case .guanyinType: stages = [(.offsetCluster, 3), (.offsetOldStem, 5)]
            case .haworthiaType: stages = [.jadeFan, .zebraHaworthia].contains(species) ? [(.offsetOldStem, 5)] : []
            case .cactusType: stages = [(.cactusYoung, 3), (.cactusAdult, 5), (.cactusCluster, 8), (.cactusOverflow, 12)]
            case .moneyStackType: stages = [(.moneyYoung, 5), (.moneyAdult, 10), (.moneyOldStem, 15), (.moneyMultipleHeads, 20)]
            case .motherOfThousandsType: stages = [(.motherAdult, 10), (.motherPrime, 20), (.motherOldStem, 35), (.motherCluster, 50)]
            case .conophytumType: stages = []
            case .yuzhuiType: stages = [(.grassSprout, 3), (.grassCluster, 5), (.grassClump, 8), (.grassOverflow, 12)]
            }
            for (stage, count) in stages {
                let directory = try temporaryDirectory()
                defer { try? FileManager.default.removeItem(at: directory) }
                let url = directory.appendingPathComponent("garden.json")
                let plant = plant(species, stage)
                var state = SucculentGarden()
                state.money = 23
                state.claimedToday = 5
                state.claimDate = date
                let existing = SucculentLeaf(id: UUID(), claimedAt: date, species: .huangli)
                state.leaves = [existing]
                state.plants = [plant]
                state.slots = [plant.id, nil, nil]
                try JSONEncoder().encode(state).write(to: url)
                let store = SucculentStore(fileURL: url)
                let result = try await store.disassemble(plantID: plant.id, at: date)
                #expect(result.money == state.money && result.claimedToday == 5 && result.claimDate == date)
                #expect(result.plants.isEmpty && result.slots == [nil, nil, nil])
                #expect(result.leaves.count == count + 1 && result.leaves.first == existing)
                #expect(result.leaves.dropFirst().allSatisfy { $0.species == species && $0.claimedAt == date })
                #expect(Set(result.leaves.map(\.id)).count == result.leaves.count)
                #expect(try await SucculentStore(fileURL: url).read() == result)
                let bytes = try Data(contentsOf: url)
                await #expect(throws: GardenError.self) { try await store.disassemble(plantID: plant.id, at: date) }
                #expect(try Data(contentsOf: url) == bytes)
            }
        }
    }

    @Test
    func initialPlantsAndRawLeavesCannotBeDisassembledOrRewritten() async throws {
        for species in SucculentSpecies.allCases {
            let directory = try temporaryDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appendingPathComponent("garden.json")
            let plant = plant(species, species.initialStage)
            let leaf = SucculentLeaf(id: UUID(), claimedAt: date, species: species)
            var state = SucculentGarden()
            state.plants = [plant]
            state.leaves = [leaf]
            try JSONEncoder().encode(state).write(to: url)
            let bytes = try Data(contentsOf: url)
            let store = SucculentStore(fileURL: url)
            await #expect(throws: GardenError.self) { try await store.disassemble(plantID: plant.id, at: date) }
            await #expect(throws: GardenError.self) { try await store.disassemble(plantID: leaf.id, at: date) }
            #expect(try Data(contentsOf: url) == bytes)
        }
    }

    @Test
    func grownYuzhuiReturnsThreeLeavesAndEachDragOnlyConsumesOne() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let leaf = try #require((try await store.claimLeaf(species: .yuzhui, at: date)).leaves.last)
        let planted = try await store.sow(leafID: leaf.id, in: 0, at: date)
        let id = try #require(planted.plant(in: 0)).id
        let changed = try await store.changeRate(to: 10, at: date)
        let later = date.addingTimeInterval(8640)
        let divided = try await store.disassemble(plantID: id, at: later)
        #expect(divided.leaves.count == 3 && divided.plants.isEmpty)
        #expect(divided.money == changed.money && divided.claimedToday == changed.claimedToday)
        let first = divided.leaves[0]
        let newSeed = try await store.sow(leafID: first.id, in: 2, at: later)
        #expect(newSeed.leaves.count == 2 && newSeed.plant(in: 2)?.species == .yuzhui)
        #expect(newSeed.plant(in: 2)?.stage(at: later, rate: 10) == .sprout)
        await #expect(throws: GardenError.self) { try await store.sow(leafID: first.id, in: 1, at: later) }
        #expect(try await SucculentStore(fileURL: url).read() == newSeed)
    }

    @Test
    func simultaneousDisassemblyOnlyPaysMaterialsOnce() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let plant = plant(.snowStonecrop, .grassCluster)
        var state = SucculentGarden()
        state.plants = [plant]
        try JSONEncoder().encode(state).write(to: url)
        let store = SucculentStore(fileURL: url)
        let successes = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<2 {
                group.addTask {
                    do { _ = try await store.disassemble(plantID: plant.id, at: date); return true }
                    catch { return false }
                }
            }
            var count = 0
            for await success in group { if success { count += 1 } }
            return count
        }
        let result = try await store.read()
        #expect(successes == 1 && result.plants.isEmpty && result.leaves.count == 5)
        #expect(result.leaves.allSatisfy { $0.species == .snowStonecrop && $0.species.propagationTitle == "枝条" })
    }

    private func plant(_ species: SucculentSpecies, _ stage: SucculentStage) -> SucculentPlant {
        SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: species.startSeconds(for: stage), growthUpdatedAt: date, species: species)
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
