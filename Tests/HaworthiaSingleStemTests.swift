// 玉露取消多头后各期不再拆分；使用独立临时文件验证禁止操作不改库存。
import Foundation
import Testing

@Suite(.serialized)
struct HaworthiaSingleStemTests {
    @Test
    func singleHeadJadesCannotBeDisassembledAtAnyAge() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let species = SucculentSpecies.allCases.filter {
            $0.morphology == .haworthiaType && ![.jadeFan, .zebraHaworthia].contains($0)
        }
        #expect(species.count == 11)
        for kind in species {
            for stage in kind.stages {
                #expect(kind.disassemblyCount(for: stage) == nil)
                var garden = SucculentGarden()
                garden.claimedToday = 5
                garden.claimDate = date
                garden.money = 31
                let plant = SucculentPlant(id: UUID(), acquiredAt: date,
                    growthSeconds: kind.startSeconds(for: stage), growthUpdatedAt: date, species: kind)
                garden.plants = [plant]
                garden.slots[0] = plant.id
                let bytes = try JSONEncoder().encode(garden)
                try bytes.write(to: url)
                let store = SucculentStore(fileURL: url)
                await #expect(throws: GardenError.cannotDisassemble) {
                    try await store.disassemble(plantID: plant.id, at: date)
                }
                #expect(try Data(contentsOf: url) == bytes)
                #expect(try await store.read(at: date) == garden)
            }
        }
    }
}
