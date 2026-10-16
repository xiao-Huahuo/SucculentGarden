// 使用隔离临时目录和受控时间验收经济与成长规则，不写入用户花园或修改系统时间。
import Foundation
import Testing

@Suite(.serialized)
struct SucculentTests {
    private let start = Date(timeIntervalSince1970: 1_791_806_400)
    private let day: TimeInterval = 86_400

    @Test
    func initialWalletAndReadOnlyWidgetRead() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let state = try await store.read()
        #expect(state.money == 10 && state.leaves.isEmpty && state.plants.isEmpty)
        #expect(state.slots == [nil, nil, nil])
        #expect(!FileManager.default.fileExists(atPath: url.path))
        _ = try await store.read(createIfMissing: true)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test
    func fiveDailyClaimsPersistAndResetAtLocalMidnight() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Shanghai"))
        let late = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 23, minute: 59)))
        for _ in 0..<5 { _ = try await store.claimLeaf(at: late, calendar: calendar) }
        var rejected = false
        do { _ = try await store.claimLeaf(at: late, calendar: calendar) } catch { rejected = true }
        #expect(rejected)
        let reopened = SucculentStore(fileURL: url)
        let before = try await reopened.read()
        #expect(before.leaves.count == 5 && before.money == 10)
        #expect(before.remainingClaims(at: late, calendar: calendar) == 0)
        let next = try await reopened.claimLeaf(at: late.addingTimeInterval(120), calendar: calendar)
        #expect(next.claimedToday == 1 && next.leaves.count == 6)
        #expect(next.remainingClaims(at: late.addingTimeInterval(120), calendar: calendar) == 4)
    }

    @Test
    func concurrentClaimsCannotExceedFive() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SucculentStore(fileURL: directory.appendingPathComponent("garden.json"))
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    do { _ = try await store.claimLeaf(at: start); return true } catch { return false }
                }
            }
            var successes = 0
            for await success in group { if success { successes += 1 } }
            #expect(successes == 5)
        }
        let state = try await store.read()
        #expect(state.leaves.count == 5 && state.claimedToday == 5)
    }

    @Test
    func leafDoesNotGrowUntilSownAndCannotBeSownTwice() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SucculentStore(fileURL: directory.appendingPathComponent("garden.json"))
        let inventory = try await store.claimLeaf(at: start)
        let leaf = try #require(inventory.leaves.first)
        #expect(inventory.plants.isEmpty)
        let plantingDate = start.addingTimeInterval(100 * day)
        let planted = try await store.sow(leafID: leaf.id, in: 1, at: plantingDate)
        let plant = try #require(planted.plant(in: 1))
        #expect(planted.leaves.isEmpty && planted.money == 10)
        #expect(plant.stage(at: plantingDate, rate: 1) == .sprout)
        var rejected = false
        do { _ = try await store.sow(leafID: leaf.id, in: 2, at: plantingDate) } catch { rejected = true }
        #expect(rejected)
        #expect(try await store.read() == planted)
    }

    @Test
    func cumulativeGrowthAndOfflineReopen() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let state = try await store.claimLeaf(at: start)
        let planted = try await store.sow(leafID: try #require(state.leaves.first).id, in: 0, at: start)
        let restored = try await SucculentStore(fileURL: url).read()
        #expect(restored == planted)
        let plant = try #require(restored.plants.first)
        let boundaries: [(Double, SucculentStage)] = [(1, .juvenile), (4, .adult), (9, .prime), (19, .oldStem), (39, .cluster)]
        for (days, stage) in boundaries {
            #expect(plant.stage(at: start.addingTimeInterval(days * day), rate: 1) == stage)
            #expect(plant.stage(at: start.addingTimeInterval(days * day - 1), rate: 1).rawValue == stage.rawValue - 1)
        }
        #expect(plant.stage(at: start.addingTimeInterval(400 * day), rate: 1) == .cluster)
    }

    @Test
    func rateChangePreservesPastProgressAndFutureTimeline() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SucculentStore(fileURL: directory.appendingPathComponent("garden.json"))
        let leaf = try #require((try await store.claimLeaf(at: start)).leaves.first)
        _ = try await store.sow(leafID: leaf.id, in: 0, at: start)
        let changedAt = start.addingTimeInterval(day / 2)
        let changed = try await store.changeRate(to: 2, at: changedAt)
        let plant = try #require(changed.plants.first)
        #expect(plant.age(at: changedAt, rate: changed.growthRate) == day / 2)
        let transition = try #require(plant.transitionDates(after: changedAt, rate: 2).first)
        #expect(transition == start.addingTimeInterval(day * 0.75))
        #expect(plant.stage(at: transition, rate: 2) == .juvenile)
        let slowed = try await store.changeRate(to: 0.25, at: transition)
        #expect(try #require(slowed.plants.first).stage(at: transition, rate: 0.25) == .juvenile)
        for bad in [0.0, -1.0, 1001.0, Double.infinity] {
            var rejected = false
            do { _ = try await store.changeRate(to: bad) } catch { rejected = true }
            #expect(rejected)
        }
        #expect(try await store.read() == slowed)
    }

    @Test
    func purchaseAndSaleUseEverySpecifiedPrice() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SucculentStore(fileURL: directory.appendingPathComponent("garden.json"))
        // 通过正常叶插成长与出售筹集测试资金，仍只操作临时目录。
        for slot in 0..<3 {
            let leaf = try #require((try await store.claimLeaf(at: start)).leaves.last)
            _ = try await store.sow(leafID: leaf.id, in: slot, at: start)
        }
        let matureDate = start.addingTimeInterval(39 * day)
        for plant in try await store.read().plants { _ = try await store.sell(plantID: plant.id, at: matureDate) }
        var previous = try await store.read()
        #expect(previous.money == 160)
        let cases: [(SucculentStage, Int, Int)] = [(.juvenile, 3, 2), (.adult, 10, 5), (.prime, 20, 10), (.oldStem, 50, 20), (.cluster, 100, 50)]
        for (stage, buy, sell) in cases {
            let bought = try await store.buy(stage: stage, at: matureDate)
            #expect(bought.money == previous.money - buy)
            let plant = try #require(bought.plants.last)
            #expect(plant.stage(at: matureDate, rate: 1) == stage)
            let sold = try await store.sell(plantID: plant.id, at: matureDate)
            #expect(sold.money == bought.money + sell)
            #expect(sold.plants.isEmpty)
            previous = sold
        }
    }

    @Test
    func placingInAnotherPotMovesItRatherThanCopies() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SucculentStore(fileURL: directory.appendingPathComponent("garden.json"))
        let leaf = try #require((try await store.claimLeaf(at: start)).leaves.first)
        let planted = try await store.sow(leafID: leaf.id, in: 0, at: start)
        let id = try #require(planted.plants.first).id
        #expect(planted.unplacedPlants.isEmpty)
        let moved = try await store.assign(plantID: id, to: 1)
        #expect(moved.slots == [nil, id, nil])
        #expect(moved.plants == planted.plants)
        #expect(moved.unplacedPlants.isEmpty)
        #expect(try await store.assign(plantID: id, to: 1) == moved)
        let returned = try await store.clear(slot: 1, at: start)
        #expect(returned.slots == [nil, nil, nil])
        #expect(returned.unplacedPlants.map(\.id) == planted.plants.map(\.id) && returned.unplacedPlants.allSatisfy { !$0.isGrowing && $0.growthSeconds == 0 })
        let purchase = try await store.buy(stage: .juvenile, at: start)
        let replaced = try await store.assign(plantID: try #require(purchase.plants.last).id, to: 0)
        let assigned = try await store.assign(plantID: id, to: 0)
        #expect(assigned.unplacedPlants.map(\.id) == replaced.plants.filter { $0.id != id }.map(\.id) && assigned.unplacedPlants.allSatisfy { !$0.isGrowing })
    }

    @Test
    func repeatedMovesKeepOnePlantAndSaleOnlyPaysOnce() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let leaf = try #require((try await store.claimLeaf(at: start)).leaves.first)
        let planted = try await store.sow(leafID: leaf.id, in: 0, at: start)
        let id = try #require(planted.plants.first).id
        _ = try await store.assign(plantID: id, to: 1)
        _ = try await store.assign(plantID: id, to: 2)
        let moved = try await SucculentStore(fileURL: url).read()
        #expect(moved.plants.count == 1 && moved.slots == [nil, nil, id])
        let sold = try await store.sell(plantID: id, at: start)
        #expect(sold.money == 11 && sold.slots == [nil, nil, nil] && sold.plants.isEmpty)
        var rejected = false
        do { _ = try await store.sell(plantID: id, at: start) } catch { rejected = true }
        #expect(rejected)
        #expect(try await store.read() == sold)
    }

    @Test
    func legacyDuplicatePlacementMigratesWithoutLosingData() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let leaf = try #require((try await store.claimLeaf(at: start)).leaves.first)
        var old = try await store.sow(leafID: leaf.id, in: 0, at: start)
        let id = try #require(old.plants.first).id
        old.version = 1
        old.slots = [id, id, id]
        let original = try JSONEncoder().encode(old)
        try original.write(to: url)
        let readOnly = try await store.read(at: start)
        #expect(try Data(contentsOf: url) == original)
        #expect(readOnly.version == 8 && readOnly.slots == [nil, nil, id])
        #expect(readOnly.plants == old.plants && readOnly.money == old.money)
        #expect(readOnly.leaves == old.leaves && readOnly.claimDate == old.claimDate)
        #expect(readOnly.claimedToday == old.claimedToday && readOnly.growthRate == old.growthRate)
        #expect(try await store.read(createIfMissing: true, at: start) == readOnly)
        #expect(try await SucculentStore(fileURL: url).read() == readOnly)
        var duplicate = readOnly
        duplicate.slots[0] = id
        #expect(throws: GardenError.self) { try duplicate.validate() }
    }

    @Test
    func replacementAndClearingKeepCollectionAndFailuresPreserveFile() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let first = try await store.buy(stage: .juvenile, at: start)
        _ = try await store.assign(plantID: try #require(first.plants.last).id, to: 0)
        let second = try await store.buy(stage: .juvenile, at: start)
        _ = try await store.assign(plantID: try #require(second.plants.last).id, to: 0)
        let cleared = try await store.clear(slot: 0)
        #expect(cleared.plants.count == 2 && cleared.money == 4 && cleared.plant(in: 0) == nil)
        let before = try Data(contentsOf: url)
        var insufficient = false
        do { _ = try await store.buy(stage: .cluster) } catch { insufficient = true }
        #expect(insufficient)
        var leafPurchase = false
        do { _ = try await store.buy(stage: .sprout) } catch { leafPurchase = true }
        #expect(leafPurchase)
        #expect(try Data(contentsOf: url) == before)
        let damaged = Data("invalid-garden-json".utf8)
        try damaged.write(to: url)
        var rejected = false
        do { _ = try await store.claimLeaf() } catch { rejected = true }
        #expect(rejected)
        #expect(try Data(contentsOf: url) == damaged)
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
