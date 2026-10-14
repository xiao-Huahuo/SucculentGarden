// 购买与替换只操作隔离文件；收藏排序和盆栽标识从实际盆位推导。
import Foundation
import Testing

@MainActor @Suite(.serialized)
struct CollectionPlacementTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func paidPurchaseNeverChangesEmptyOrOccupiedPots() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let leaf = try #require((try await store.claimLeaf(at: date)).leaves.first)
        let initial = try await store.sow(leafID: leaf.id, in: 1, at: date)
        let purchase = try await store.buy(stage: .juvenile, species: .taodan, at: date)
        #expect(purchase.slots == initial.slots)
        #expect(purchase.money == initial.money - 3)
        #expect(purchase.unplacedPlants.last?.species == .taodan)
        let another = try await store.buy(stage: .juvenile, at: date)
        #expect(another.slots == initial.slots && another.unplacedPlants.count == 2)
        #expect(try await SucculentStore(fileURL: url).read() == another)
    }

    @Test
    func collectionShowsPottedPlantsFirstAndReplacementChangesMembership() async throws {
        var garden = SucculentGarden()
        garden.plants = [SucculentSpecies.huangli, .taodan, .orangeMonroe, .yuzhui].map { species in
            SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: species.startSeconds(for: species.stages[1]), growthUpdatedAt: date, species: species)
        }
        garden.slots = [garden.plants[2].id, garden.plants[1].id, nil]
        let model = GardenModel()
        #expect(model.collectionPlants(in: garden, at: date).map(\.id) == [garden.plants[2].id, garden.plants[1].id, garden.plants[0].id, garden.plants[3].id])
        garden.slots[0] = garden.plants[3].id
        #expect(model.collectionPlants(in: garden, at: date).map(\.id) == [garden.plants[3].id, garden.plants[1].id, garden.plants[0].id, garden.plants[2].id])
        model.collectionMorphology = .crassulaceaeType
        #expect(model.collectionPlants(in: garden, at: date).map(\.species) == [.taodan,.huangli,.orangeMonroe])
    }

    @Test
    func replacingAndMovingPersistExactlyOnePotMarkerPerPlant() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        for slot in 0..<3 {
            let leaf = try #require((try await store.claimLeaf(at: date)).leaves.last)
            _ = try await store.sow(leafID: leaf.id, in: slot, at: date)
        }
        let before = try await store.read()
        let purchase = try await store.buy(stage: .juvenile, species: .taodan, at: date)
        let incoming = try #require(purchase.plants.last).id
        let replacedID = try #require(before.slots[1])
        let model = GardenModel(store: store)
        await model.load()
        await model.assign(incoming, to: 1)
        let replaced = try #require(model.garden)
        #expect(replaced.slots == [before.slots[0], incoming, before.slots[2]])
        #expect(replaced.slot(containing: replacedID) == nil)
        #expect(replaced.slot(containing: incoming) == 1)
        #expect(replaced.plants.count == purchase.plants.count)
        #expect(model.collectionPlants(in: replaced, at: date).prefix(3).map(\.id) == replaced.slots.compactMap { $0 })
        await model.assign(incoming, to: 2)
        let moved = try #require(model.garden)
        #expect(moved.slots == [before.slots[0], nil, incoming])
        #expect(moved.slot(containing: incoming) == 2)
        #expect(moved.plants.count == purchase.plants.count && moved.money == purchase.money)
        #expect(try await SucculentStore(fileURL: url).read() == moved)
    }

    @Test
    func dropLocationRoutesToEachPotAndRejectsInvalidCoordinates() {
        #expect(GardenPlantingLayout.slot(at: 50, width: 360) == 0)
        #expect(GardenPlantingLayout.slot(at: 180, width: 360) == 1)
        #expect(GardenPlantingLayout.slot(at: 320, width: 360) == 2)
        #expect(GardenPlantingLayout.slot(at: 0, width: 360) == 0)
        #expect(GardenPlantingLayout.slot(at: 360, width: 360) == 2)
        #expect(GardenPlantingLayout.slot(at: -1, width: 360) == nil)
        #expect(GardenPlantingLayout.slot(at: 361, width: 360) == nil)
        #expect(GardenPlantingLayout.slot(at: .nan, width: 360) == nil)
        #expect(GardenPlantingLayout.slot(at: 1, width: 20) == nil)
    }

}
