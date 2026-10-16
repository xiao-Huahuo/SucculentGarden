// 品种贯穿领取、叶插、购买、移动与读回；只操作隔离临时文件。
import Foundation
import Testing

@Suite(.serialized)
struct SucculentSpeciesTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func mixedSpeciesShareTheDailyLimitAndCuttingsKeepTheirSpecies() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let choices: [SucculentSpecies] = [.blueBird, .ruby, .jilongyue, .babyFinger, .whiteMoon]
        for (index, species) in choices.enumerated() {
            let inventory = try await store.claimLeaf(species: species, at: date)
            let leaf = try #require(inventory.leaves.last)
            #expect(leaf.species == species)
            _ = try await store.sow(leafID: leaf.id, in: index % 3, at: date)
        }
        let saved = try await SucculentStore(fileURL: url).read()
        #expect(saved.claimedToday == 5 && saved.remainingClaims(at: date) == 0)
        #expect(saved.money == 10 && saved.leaves.isEmpty)
        #expect(saved.plants.map(\.species) == choices)
        for species in SucculentSpecies.allCases {
            await #expect(throws: GardenError.self) { try await store.claimLeaf(species: species, at: date) }
        }
        #expect(try await store.read() == saved)
    }

    @Test
    func purchasesMovesAndSalesKeepSpeciesAndExistingPrices() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        for species in SucculentSpecies.allCases where species.morphology != .yuzhuiType {
            let url = directory.appendingPathComponent("\(species.rawValue).json")
            let store = SucculentStore(fileURL: url)
            let bought = try await store.buy(stage: species.stages[1], species: species, at: date)
            let plant = try #require(bought.plants.last)
            #expect(plant.species == species && bought.money == 7)
            let moved = try await store.assign(plantID: plant.id, to: 2)
            #expect(moved.slots == [nil, nil, plant.id])
            #expect(try await SucculentStore(fileURL: url).read() == moved)
            let sold = try await store.sell(plantID: plant.id, at: date)
            #expect(sold.money == (species.morphology == .cactusType ? 8 : 9) && sold.plants.isEmpty)
            #expect(try await SucculentStore(fileURL: url).read() == sold)
        }
    }

    @Test
    func everySpeciesSurvivesLeafCuttingGrowthAndReopeningAcrossDays() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        for (index, species) in SucculentSpecies.allCases.enumerated() {
            let day = try #require(calendar.date(byAdding: .day, value: index / 5, to: date))
            let inventory = try await store.claimLeaf(species: species, at: day, calendar: calendar)
            let leaf = try #require(inventory.leaves.last)
            #expect(leaf.species == species && inventory.claimedToday == index % 5 + 1)
            let planted = try await store.sow(leafID: leaf.id, in: index % 3, at: day)
            let restored = try await SucculentStore(fileURL: url).read()
            #expect(restored == planted && restored.leaves.isEmpty)
            let plant = try #require(restored.plant(in: index % 3))
            #expect(plant.species == species && plant.stage(at: day, rate: 1) == species.initialStage)
            #expect(plant.stage(at: day.addingTimeInterval(86_400), rate: 1) == species.stages[1])
            await #expect(throws: GardenError.self) { try await store.sow(leafID: leaf.id, in: 0, at: day) }
        }
        let saved = try await SucculentStore(fileURL: url).read()
        #expect(saved.plants.map(\.species) == SucculentSpecies.allCases)
        #expect(saved.version == 9 && saved.money == 10)
    }

    @Test
    func oldVersionTwoGetsHuangliWithoutChangingBusinessRecords() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        _ = try await store.claimLeaf(at: date)
        var previous = try await store.buy(stage: .juvenile, at: date)
        previous.version = 2
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(previous)) as? [String: Any])
        for key in ["leaves", "plants"] {
            var records = try #require(object[key] as? [[String: Any]])
            for index in records.indices { records[index].removeValue(forKey: "species") }
            object[key] = records
        }
        let original = try JSONSerialization.data(withJSONObject: object)
        try original.write(to: url)
        let restored = try await store.read()
        #expect(try Data(contentsOf: url) == original)
        previous.version = 9
        #expect(restored == previous)
        #expect(restored.leaves.allSatisfy { $0.species == .huangli })
        #expect(restored.plants.allSatisfy { $0.species == .huangli })
        #expect(try await store.read(createIfMissing: true) == restored)
        #expect(try await SucculentStore(fileURL: url).read() == restored)
    }

    @Test
    func invalidOrMissingSpeciesInNewFilesCannotBeRewritten() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let state = try await store.claimLeaf(species: .orangeMonroe, at: date)
        let base = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        for value in ["unknown-species", "missing"] {
            var object = base
            var leaves = try #require(object["leaves"] as? [[String: Any]])
            if value == "missing" { leaves[0].removeValue(forKey: "species") }
            else { leaves[0]["species"] = value }
            object["leaves"] = leaves
            let bad = try JSONSerialization.data(withJSONObject: object)
            try bad.write(to: url)
            var rejected = false
            do { _ = try await store.claimLeaf(at: date) } catch { rejected = true }
            #expect(rejected)
            #expect(try Data(contentsOf: url) == bad)
        }
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
