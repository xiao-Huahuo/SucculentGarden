// 观音莲小苗、生石花种子沿用单份材料库存；所有操作都使用测试临时目录。
import Foundation
import Testing

@Suite(.serialized)
struct NewMorphologyTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func newMaterialsShareClaimsAndStartGrowingOnlyAfterPlanting() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let bought = try await store.buy(stage: .juvenile, at: date)
        _ = try await store.assign(plantID: try #require(bought.plants.last).id, to: 0)
        let existing = try #require((try await store.read()).plant(in: 0))
        for species in [SucculentSpecies.guanyin, .lithops, .huangli, .snowStonecrop, .yuzhui] {
            let state = try await store.claimLeaf(species: species, at: date)
            #expect(state.plant(in: 0)?.id == existing.id && state.plants.count == 1)
        }
        let collected = try await store.read()
        #expect(collected.money == 7 && collected.claimedToday == 5)
        let bytes = try Data(contentsOf: url)
        await #expect(throws: GardenError.self) { try await store.claimLeaf(species: .guanyin, at: date) }
        await #expect(throws: GardenError.self) { try await store.claimLeaf(species: .lithops, at: date) }
        #expect(try Data(contentsOf: url) == bytes)
        let later = date.addingTimeInterval(30 * 86_400)
        for (slot, material) in collected.leaves.prefix(2).enumerated() {
            let planted = try await store.sow(leafID: material.id, in: slot, at: later)
            let plant = try #require(planted.plant(in: slot))
            #expect(plant.species == material.species && plant.growthSeconds == 0)
            #expect(plant.stage(at: later, rate: planted.effectiveRate(for: plant.species)) == material.species.initialStage)
            #expect(planted.unplacedPlants.contains { $0.id == existing.id })
            await #expect(throws: GardenError.self) { try await store.sow(leafID: material.id, in: 2, at: later) }
        }
        let reopened = try await SucculentStore(fileURL: url).read()
        #expect(reopened.leaves.count == 3 && reopened.plants.count == 3 && reopened.money == 7)
        #expect(reopened.plant(in: 0)?.species == .guanyin && reopened.plant(in: 1)?.species == .lithops)
    }

    @Test
    func stagesHaveDistinctNamesFixedPricesAndOnlyGuanyinColoniesSplit() {
        #expect(SucculentSpecies.guanyin.stages.map(\.title) == ["小苗", "幼年", "成年", "群生", "老桩"])
        #expect(SucculentSpecies.lithops.stages.map(\.title) == ["种子", "萌芽", "幼年", "成年", "老桩"])
        #expect(SucculentSpecies.guanyin.propagationTitle == "小苗" && SucculentSpecies.guanyin.propagationQuantity == "1株")
        #expect(SucculentSpecies.lithops.propagationTitle == "种子" && SucculentSpecies.lithops.propagationQuantity == "1粒")
        for species in [SucculentSpecies.guanyin, .lithops] {
            #expect(species.stages.map { species.purchasePrice(for: $0) } == [nil, 3, 10, 20, 50])
            #expect(species.stages.map(\.salePrice) == [1, 2, 5, 10, 20])
            #expect(species.stages.map { species.startSeconds(for: $0) / 86_400 } == [0, 1, 4, 9, 19])
            #expect(species.stages.allSatisfy { SucculentArtworkLayout.assets[species.assetName(stage: $0)] != nil })
            #expect(species.assetName(stage: species.initialStage, isLeaf: true) == species.assetName(stage: species.initialStage))
        }
        #expect(SucculentSpecies.guanyin.stages.map { SucculentSpecies.guanyin.disassemblyCount(for: $0) } == [nil, nil, nil, 3, 5])
        #expect(SucculentSpecies.lithops.stages.allSatisfy { SucculentSpecies.lithops.disassemblyCount(for: $0) == nil })
    }

    @Test
    func unsupportedSplitsAndBuyingInitialMaterialsCannotRewriteData() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        for species in [SucculentSpecies.guanyin, .lithops] {
            for stage in species.stages where species.disassemblyCount(for: stage) == nil {
                let url = directory.appendingPathComponent("\(species.rawValue)-\(stage.rawValue).json")
                var state = SucculentGarden()
                let plant = SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: species.startSeconds(for: stage), growthUpdatedAt: date, species: species)
                state.plants = [plant]
                let bytes = try JSONEncoder().encode(state)
                try bytes.write(to: url)
                let store = SucculentStore(fileURL: url)
                await #expect(throws: GardenError.self) { try await store.disassemble(plantID: plant.id, at: date) }
                await #expect(throws: GardenError.self) { try await store.buy(stage: species.initialStage, species: species, at: date) }
                #expect(try Data(contentsOf: url) == bytes)
            }
        }
    }

    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
