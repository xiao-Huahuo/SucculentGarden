// 验证真实文件持久化、并发点击和每日箴言，不修改用户的 Widget 数据。
import Foundation
import Testing

@Suite(.serialized)
struct MuyuTests {
    @Test
    func everyTapIsSavedAndRestored() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let store = MuyuStore(fileURL: url)
        var previous = try await store.read()
        #expect(previous.merit == 0 && previous.fortune == 0)

        for _ in 0..<30 {
            let current = try await store.tap()
            #expect(current.merit == previous.merit + 1)
            #expect((1...3).contains(current.fortune - previous.fortune))
            #expect((-18.0...18.0).contains(current.popupX))
            #expect((46.0...52.0).contains(abs(current.popupY)))
            #expect(current.dailySeed == previous.dailySeed)
            previous = current
        }

        let restored = try await MuyuStore(fileURL: url).read()
        #expect(restored == previous)
    }

    @Test
    func concurrentTapsDoNotLoseMerit() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = MuyuStore(fileURL: directory.appendingPathComponent("progress.json"))
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<50 {
                group.addTask { _ = try await store.tap() }
            }
            try await group.waitForAll()
        }
        let progress = try await store.read()
        #expect(progress.merit == 50)
        #expect((50...150).contains(progress.fortune))
    }

    @Test
    func damagedDataIsPreserved() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let damaged = Data("damaged-json".utf8)
        try damaged.write(to: url)
        let store = MuyuStore(fileURL: url)
        var rejected = false
        do { _ = try await store.tap() } catch { rejected = true }
        #expect(rejected)
        #expect(try Data(contentsOf: url) == damaged)
    }

    @Test
    func oneHundredSayingsStayStableForTheDay() throws {
        let catalog = try ProverbCatalog.bundled()
        #expect(catalog.sayings.count == 100)
        #expect(Set(catalog.sayings).count == 100)
        #expect(catalog.sayings.allSatisfy { saying in
            !saying.unicodeScalars.contains { $0.properties.isEmojiPresentation }
        })

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Shanghai"))
        let morning = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 11, hour: 1)))
        let evening = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 11, hour: 23)))
        #expect(catalog.saying(for: morning, seed: 1234, calendar: calendar) ==
                catalog.saying(for: evening, seed: 1234, calendar: calendar))

        let selections = try (0..<100).map { offset in
            let date = try #require(calendar.date(byAdding: .day, value: offset, to: morning))
            return catalog.saying(for: date, seed: 1234, calendar: calendar)
        }
        #expect(Set(selections).count > 30)
        #expect(selections.allSatisfy { catalog.sayings.contains($0) })
    }

    @Test
    func legacyPrivateProgressMigratesByteForByteAndNeverResets() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let legacy = directory.appendingPathComponent("private.json")
        let shared = directory.appendingPathComponent("shared.json")
        var progress = MuyuProgress(dailySeed: 1234)
        progress.merit = 29
        progress.fortune = 55
        progress.lastTap = Date(timeIntervalSince1970: 1_790_000_000)
        let bytes = try JSONEncoder().encode(progress)
        try bytes.write(to: legacy)
        let store = MuyuStore(fileURL: shared, legacyFileURL: legacy)
        #expect(try await store.read() == progress)
        #expect(try Data(contentsOf: shared) == bytes && Data(contentsOf: legacy) == bytes)
        let tapped = try await store.tap()
        #expect(tapped.merit == 30 && (1...3).contains(tapped.fortune - progress.fortune))
        #expect(tapped.dailySeed == progress.dailySeed)
        #expect(try Data(contentsOf: legacy) == bytes)
        #expect(try await MuyuStore(fileURL: shared, legacyFileURL: legacy).read() == tapped)

        let damaged = directory.appendingPathComponent("damaged-private.json")
        let emptyShared = directory.appendingPathComponent("new-shared.json")
        try Data("bad-json".utf8).write(to: damaged)
        await #expect(throws: (any Error).self) { try await MuyuStore(fileURL: emptyShared, legacyFileURL: damaged).read() }
        #expect(!FileManager.default.fileExists(atPath: emptyShared.path))
        #expect(try Data(contentsOf: damaged) == Data("bad-json".utf8))
    }

    @Test
    func independentWritersDoNotLoseSharedMerit() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("shared.json")
        let first = MuyuStore(fileURL: url)
        let second = MuyuStore(fileURL: url)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<60 {
                group.addTask { _ = try await (index.isMultiple(of: 2) ? first : second).tap() }
            }
            try await group.waitForAll()
        }
        let progress = try await MuyuStore(fileURL: url).read()
        #expect(progress.merit == 60 && (60...180).contains(progress.fortune))
    }

    @Test
    func midnightScheduleSurvivesDayChangesAndDaylightSaving() throws {
        for zone in ["Asia/Shanghai", "America/New_York"] {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = try #require(TimeZone(identifier: zone))
            let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 23, minute: 59, second: 59)))
            let dates = MuyuTimelineSchedule.dates(from: now, calendar: calendar)
            #expect(dates.count == 8 && dates == dates.sorted() && Set(dates).count == 8)
            #expect(dates[1] == MuyuTimelineSchedule.nextMidnight(after: now, calendar: calendar))
            for (offset, value) in dates.dropFirst().enumerated() {
                #expect(calendar.component(.hour, from: value) == 0)
                #expect(calendar.component(.day, from: value) == 8 + offset)
            }
            let afterMidnight = MuyuTimelineSchedule.dates(from: dates[1], calendar: calendar)
            #expect(afterMidnight[0] == dates[1] && afterMidnight[1] == dates[2])
            if zone == "America/New_York" { #expect(dates[2].timeIntervalSince(dates[1]) == 23 * 3600) }
        }
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
