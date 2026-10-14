// 新品种用隔离存档验证全局领取额度、购买入库和种植后的时间倍率。
import Foundation
import Testing

@Suite(.serialized)
struct FenestrariaTests {
    @Test
    func purchasesAndSeedlingsKeepExistingPotsAndShareTheClaimLimit() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        var original = SucculentGarden()
        let existing = SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: 400,
                                     growthUpdatedAt: date, species: .huangli)
        original.plants = [existing]
        original.slots = [existing.id, nil, nil]
        original.money = 30
        original.claimDate = date
        original.claimedToday = 4
        try JSONEncoder().encode(original).write(to: url)
        let store = SucculentStore(fileURL: url)
        let purchased = try await store.buy(stage: .offsetAdult, species: .fenestraria, at: date)
        #expect(purchased.money == 20 && purchased.slots == original.slots)
        #expect(purchased.plants.first == existing && purchased.unplacedPlants.last?.species == .fenestraria)
        let claimed = try await store.claimLeaf(species: .fenestraria, at: date)
        let material = try #require(claimed.leaves.last)
        #expect(material.species == .fenestraria && claimed.claimedToday == 5 && claimed.money == 20)
        let bytes = try Data(contentsOf: url)
        await #expect(throws: GardenError.self) { try await store.claimLeaf(species: .iceLantern, at: date) }
        #expect(try Data(contentsOf: url) == bytes)
        let planted = try await store.sow(leafID: material.id, in: 1, at: date)
        #expect(planted.plant(in: 0) == existing && planted.plant(in: 1)?.species == .fenestraria)
        #expect(planted.leaves.isEmpty && planted.plants.count == 3 && planted.money == 20)
        #expect(try await SucculentStore(fileURL: url).read(at: date) == planted)
    }

    @Test
    func growthUsesTheTypeAndSpeciesTimeMultipliersAndKeepsAllFivePictures() {
        let species = SucculentSpecies.fenestraria
        let garden = SucculentGarden()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let plant = SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: 0,
                                   growthUpdatedAt: date, species: species)
        #expect(species.morphology == .haworthiaType && species.propagationTitle == "小苗")
        #expect(plant.transitionDates(after: date, rate: garden.effectiveRate(for: species))
            .map { $0.timeIntervalSince(date) / 86_400 } == [3, 12, 27, 57])
        #expect(plant.stage(at: date.addingTimeInterval(3 * 86_400), rate: garden.effectiveRate(for: species)) == .offsetJuvenile)
        #expect(species.stages.allSatisfy { species.disassemblyCount(for: $0) == nil })
        #expect(Set(species.stages.map { species.assetName(stage: $0) }).count == 5)
        #expect(species.assetName(stage: species.initialStage, isLeaf: true) == "FenestrariaStage0")
        #expect(species.stages.allSatisfy { SucculentAtlasLayout.frames[species.assetName(stage: $0)]?.sourceName == "FenestrariaAtlas" })
    }
}
