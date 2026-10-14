import Foundation
import Testing

struct GrowthDisplayTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func intervalsUseTheAppliedRateAndTheSpeciesProfile() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SucculentStore(fileURL: directory.appendingPathComponent("garden.json"))
        for rate in [1.0, 10, 100, 1000, 0.25] {
            let state = try await store.changeRate(to: rate, at: date)
            let seconds = GardenGrowthTime.interval(species: .yuzhui, from: .sprout, to: .grassSprout, rate: state.growthRate)
            #expect(abs(seconds - 86_400 / rate) < 0.001)
        }
        #expect(GardenGrowthTime.text(86_400) == "1天")
        #expect(GardenGrowthTime.text(86_400 / 10) == "2小时24分")
        #expect(GardenGrowthTime.text(86_400 / 1000) == "1分27秒")
        #expect(GardenGrowthTime.interval(species: .yuzhui, from: .grassSprout, to: .grassCluster, rate: 1) == 86_400)
        #expect(GardenGrowthTime.interval(species: .goldenStonecrop, from: .grassCluster, to: .grassClump, rate: 10) == 3 * 86_400 / 10)
    }

    @Test
    func countdownTicksAndSwitchesToTheNextStageWithoutCountingUp() {
        let plant = SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: 0, growthUpdatedAt: date, species: .yuzhui)
        let boundary = date.addingTimeInterval(86_400)
        #expect(GardenGrowthTime.remaining(for: plant, at: boundary.addingTimeInterval(-2), rate: 1) == 2)
        #expect(GardenGrowthTime.remaining(for: plant, at: boundary.addingTimeInterval(-1), rate: 1) == 1)
        #expect(plant.stage(at: boundary, rate: 1) == .grassSprout)
        #expect(GardenGrowthTime.remaining(for: plant, at: boundary, rate: 1) == 86_400)
        #expect(GardenGrowthTime.remaining(for: plant, at: date.addingTimeInterval(10 * 86_400), rate: 1) == nil)
        #expect(GardenGrowthTime.remaining(for: plant, at: date, rate: 10) == 8640)
    }
}
