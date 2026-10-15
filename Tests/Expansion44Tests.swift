// 全部新品种使用独立临时存档验证领取、种植、购买与重开；不触碰真实库存。
import Foundation
import Testing

@Suite(.serialized)
struct Expansion44Tests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func everyNewMaterialSharesQuotaAndPersistsItsSpeciesWithoutReplacingAnotherPot() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let additions = Array(SucculentSpecies.allCases.suffix(43))
        #expect(Set(SucculentSpecies.allCases.map(\.title)).count == 115)
        for species in additions {
            let url = directory.appendingPathComponent(species.rawValue + ".json")
            var initial = SucculentGarden()
            let existing = SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: 200,
                                         growthUpdatedAt: date, species: .huangli)
            initial.plants = [existing]
            initial.slots = [existing.id, nil, nil]
            initial.money = 200
            initial.claimedToday = 4
            initial.claimDate = date
            try JSONEncoder().encode(initial).write(to: url)
            let store = SucculentStore(fileURL: url)
            let claimed = try await store.claimLeaf(species: species, at: date)
            let material = try #require(claimed.leaves.last)
            #expect(material.species == species && claimed.claimedToday == 5 && claimed.money == 200)
            let planted = try await store.sow(leafID: material.id, in: 1, at: date)
            #expect(planted.plant(in: 0) == existing && planted.plant(in: 1)?.species == species)
            #expect(planted.leaves.isEmpty && planted.claimedToday == 5)
            let slots = planted.slots
            let bought = try await store.buy(stage: species.stages[1], species: species, at: date)
            #expect(bought.slots == slots && bought.plants.count == 3 && bought.money == 197)
            #expect(bought.unplacedPlants.last?.species == species)
            #expect(try await SucculentStore(fileURL: url).read(at: date) == bought)
            let bytes = try Data(contentsOf: url)
            await #expect(throws: GardenError.self) { try await store.claimLeaf(species: .huangli, at: date) }
            #expect(try Data(contentsOf: url) == bytes)
        }
    }

    @Test
    func newJadesCannotSplitAndColoredBranchesAndButterflyBudsKeepTheirSharedRules() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        for species in [SucculentSpecies.himeJade, .eagleClaw] {
            for stage in species.stages {
                var state = SucculentGarden()
                state.plants = [plant(species, stage)]
                let bytes = try JSONEncoder().encode(state)
                try bytes.write(to: url)
                await #expect(throws: GardenError.cannotDisassemble) {
                    try await store.disassemble(plantID: state.plants[0].id, at: date)
                }
                #expect(try Data(contentsOf: url) == bytes)
            }
        }
        var state = SucculentGarden()
        let bear = plant(.blueBearPaw, .moneyMultipleHeads)
        let butterfly = plant(.butterflyMother, .motherCluster)
        state.plants = [bear, butterfly]
        state.slots = [bear.id, butterfly.id, nil]
        state.claimDate = date
        state.claimedToday = 5
        state.growthRate = 100
        try JSONEncoder().encode(state).write(to: url)
        let split = try await store.disassemble(plantID: bear.id, at: date)
        #expect(split.leaves.count == 20 && split.leaves.allSatisfy { $0.species == .blueBearPaw })
        #expect(split.slots == [nil, butterfly.id, nil] && split.claimedToday == 5)
        let harvested = try await store.harvest(plantID: butterfly.id, at: date)
        #expect(harvested.leaves.count == 70 && harvested.plants.count == 1 && harvested.claimedToday == 5)
        #expect(harvested.leaves.filter { $0.species == .butterflyMother }.count == 50)
        #expect(harvested.plant(in: 1)?.id == butterfly.id)
        await #expect(throws: GardenError.self) { try await store.harvest(plantID: butterfly.id, at: date.addingTimeInterval(86_399)) }
        #expect(try await SucculentStore(fileURL: url).read(at: date) == harvested)
    }

    private func plant(_ species: SucculentSpecies, _ stage: SucculentStage) -> SucculentPlant {
        SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: species.startSeconds(for: stage),
                       growthUpdatedAt: date, species: species)
    }

    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
