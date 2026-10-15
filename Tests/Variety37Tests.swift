// 新增品种与旧千佛手共享叶片额度；隔离文件验证品种、倍率和进度保存。
import Foundation
import Testing

@Suite(.serialized)
struct Variety37Tests {
    @Test
    func newVarietiesKeepRosetteMechanismsAndDistinctArtwork() {
        for species in [SucculentSpecies.cheese, .topsyTurvy, .tangyuan] {
            #expect(species.morphology == .crassulaceaeType)
            #expect(species.stages == [.sprout, .juvenile, .adult, .prime, .oldStem, .cluster])
            #expect(species.stages.map { species.purchasePrice(for: $0) } == [nil, 3, 10, 20, 50, 100])
            #expect(species.stages.map { species.disassemblyCount(for: $0) } == [nil, 3, 5, 8, 12, 15])
            let names = [species.assetName(stage: .sprout, isLeaf: true)] + species.stages.map { species.assetName(stage: $0) }
            #expect(Set(names).count == 7)
            for name in names {
                let frame = SucculentAtlasLayout.frames[name]
                let source = species == .cheese
                    ? (name.hasSuffix("Stage5") ? "CheeseCluster44Atlas" : "Cheese44Atlas")
                    : (name.hasSuffix("Stage5") ? "RosetteClusters40Atlas" : species.assetPrefix + "Atlas")
                #expect(frame?.sourceName == source)
                #expect((frame?.layout.bounds.width ?? 0) > 0)
            }
        }
        #expect(SucculentSpecies.allCases.filter { $0 == .thousandBuddha }.count == 1)
        #expect(SucculentSpecies.topsyTurvy.defaultTimeMultiplier == 0.85)
    }

    @Test
    func newLeavesShareQuotaWithExistingSpeciesAndSurviveReopening() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let species: [SucculentSpecies] = [.cheese, .topsyTurvy, .tangyuan, .thousandBuddha, .huangli]
        for (index, choice) in species.enumerated() {
            let inventory = try await store.claimLeaf(species: choice, at: date)
            let leaf = try #require(inventory.leaves.last)
            let planted = try await store.sow(leafID: leaf.id, in: index % 3, at: date)
            #expect(planted.plants.last?.species == choice)
            #expect(planted.leaves.isEmpty)
        }
        let before = try await store.read()
        await #expect(throws: GardenError.self) { try await store.claimLeaf(species: .cheese, at: date) }
        #expect(before.claimedToday == 5 && before.money == 10)
        #expect(before.plants.map(\.species) == species)
        #expect(try await SucculentStore(fileURL: url).read() == before)
    }

    @Test
    func stackedLeavesConsumeOnlyOneAndKeepTheirOriginalIDs() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        for species in [SucculentSpecies.cheese, .topsyTurvy, .cheese, .topsyTurvy, .cheese] {
            _ = try await store.claimLeaf(species: species, at: date)
        }
        let original = try await store.read()
        #expect(original.leafStacks.map(\.species) == [.cheese, .topsyTurvy])
        #expect(original.leafStacks.map(\.count) == [3, 2])
        let selectedID = try #require(original.leafStacks.first?.firstLeafID)
        let once = try await store.sow(leafID: selectedID, in: 0, at: date)
        #expect(once.leafStacks.map(\.count) == [2, 2])
        #expect(once.leaves.map(\.id) == original.leaves.filter { $0.id != selectedID }.map(\.id))
        #expect(once.claimedToday == 5 && once.money == original.money)
        await #expect(throws: GardenError.self) { try await store.sow(leafID: selectedID, in: 1, at: date) }
        for _ in 0..<2 {
            let current = try await store.read()
            let stack = try #require(current.leafStacks.first { $0.species == .cheese })
            _ = try await store.sow(leafID: stack.firstLeafID, in: 0, at: date)
        }
        let reopened = try await SucculentStore(fileURL: url).read()
        #expect(reopened.leafStacks.map(\.species) == [.topsyTurvy])
        #expect(reopened.leafStacks.first?.count == 2)
        #expect(reopened.plants.count == 3)
        #expect(SucculentSpecies.lithops.propagationQuantity(count: 12) == "12粒")
        #expect(SucculentSpecies.guanyin.propagationQuantity(count: 5) == "5株")
    }

}
