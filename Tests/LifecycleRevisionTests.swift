// 改名保留原档位数值；钱串新增时期的旧存档升级使用隔离文件。
import Foundation
import Testing

@Suite(.serialized)
struct LifecycleRevisionTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func lateNamesChangeWithoutChangingTimePricesOrAmounts() {
        #expect(SucculentStage.oldStem.rawValue == 4 && SucculentStage.cluster.rawValue == 5)
        #expect(SucculentStage.motherOldStem.rawValue == 33 && SucculentStage.motherCluster.rawValue == 34)
        for species in SucculentSpecies.allCases where [.crassulaceaeType, .motherOfThousandsType].contains(species.morphology) {
            let stages = species.stages
            #expect(species.stageTitle(for: stages[4]) == "老桩")
            #expect(species.stageTitle(for: stages[5]) == "群生")
            #expect(stages.map { species.startSeconds(for: $0) / 86_400 } == [0, 1, 4, 9, 19, 39])
            #expect(stages.map { species.purchasePrice(for: $0) } == [nil, 3, 10, 20, 50, 100])
            #expect(stages.map(\.salePrice) == [1, 2, 5, 10, 20, 50])
            let counts: [Int?] = species.morphology == .crassulaceaeType ? [nil, 3, 5, 8, 12, 15] : [nil, nil, 10, 20, 35, 50]
            #expect(stages.map { species.disassemblyCount(for: $0) } == counts)
        }
    }

    @Test
    func moneyStackHasFiveStagesAndConfirmedParameters() {
        for species in [SucculentSpecies.moneyStack, .deerAntler, .bearPaw] {
            #expect(species.stages.map { species.stageTitle(for: $0) } == ["小苗", "幼年", "成年", "老桩", "多头"])
            #expect(species.stages.map { species.startSeconds(for: $0) / 86_400 } == [0, 1, 4, 9, 19])
            #expect(species.stages.map { species.purchasePrice(for: $0) } == [nil, 3, 10, 20, 50])
            #expect(species.stages.map(\.salePrice) == [1, 2, 5, 10, 20])
            #expect(species.stages.map { species.disassemblyCount(for: $0) } == [nil, 5, 10, 15, 20])
            #expect(species.propagationTitle == "枝条" && species.usesStemCutting)
        }
        #expect(SucculentSpecies.moneyStack.matureStage.rawValue == 35)
    }

    @Test
    func moneyMaturityIsPreservedAndOtherPlantsAreNotRecalculatedDuringUpgrade() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        var old = SucculentGarden()
        old.version = 6
        old.money = 47
        old.growthRate = 10
        old.claimedToday = 3
        old.claimDate = date
        old.leaves = [SucculentLeaf(id: UUID(), claimedAt: date, species: .bearPaw)]
        let species: [SucculentSpecies] = [.moneyStack, .deerAntler, .bearPaw, .huangli, .broadMother]
        old.plants = species.enumerated().map { index, species in
            SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: Double(index < 3 ? 9 : 22) * 86_400,
                           growthUpdatedAt: date, species: species)
        }
        old.slots = old.plants.prefix(3).map(\.id)
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: url)
        let store = SucculentStore(fileURL: url)
        let migrated = try await store.read(at: date)
        #expect(migrated.version == 8)
        #expect(migrated.money == 47 && migrated.claimedToday == 3 && migrated.claimDate == old.claimDate)
        #expect(migrated.slots == old.slots && migrated.leaves == old.leaves)
        #expect(migrated.plants.map(\.id) == old.plants.map(\.id))
        for plant in migrated.plants.prefix(3) {
            #expect(plant.growthSeconds == 19 * 86_400)
            #expect(plant.species.stageTitle(for: plant.stage(at: date, rate: 0)) == "多头")
        }
        for (before, after) in zip(old.plants.suffix(2), migrated.plants.suffix(2)) {
            #expect(after.id == before.id && after.species == before.species)
            #expect(after.age(at: date, rate: migrated.effectiveRate(for: after.species)) == before.age(at: date, rate: old.effectiveRate(for: before.species)))
            #expect(after.isGrowing == (migrated.pot(containing: after.id) != nil))
        }
        #expect(try Data(contentsOf: url) == bytes)
        let saved = try await store.read(createIfMissing: true, at: date)
        #expect(try await SucculentStore(fileURL: url).read(at: date) == saved)
    }
}
