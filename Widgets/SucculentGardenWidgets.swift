// 木鱼球 Widget：读取持久化状态，并提前提供未来七天的每日箴言时间线。
import Foundation
import SwiftUI
import WidgetKit
import OSLog

struct MuyuEntry: TimelineEntry {
    let date: Date
    let progress: MuyuProgress?
    let saying: String
    var errorMessage: String?
}

private struct MuyuProvider: TimelineProvider {
    func placeholder(in context: Context) -> MuyuEntry {
        MuyuEntry(date: .now, progress: MuyuProgress(dailySeed: 1), saying: "心安之处，便是归途。")
    }

    func getSnapshot(in context: Context, completion: @escaping (MuyuEntry) -> Void) {
        let reply = WidgetReply(completion)
        Task { reply.call(await entries()[0]) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MuyuEntry>) -> Void) {
        let reply = WidgetReply(completion)
        Task {
            let entries = await entries()
            reply.call(Timeline(entries: entries, policy: .after(MuyuTimelineSchedule.nextMidnight(after: entries[0].date))))
        }
    }

    private func entries() async -> [MuyuEntry] {
        let now = Date.now
        do {
            let progress = try await MuyuStore.shared.read()
            let catalog = try ProverbCatalog.bundled()
            let error = await MuyuStore.shared.lastError
            let calendar = Calendar.autoupdatingCurrent
            let dates = MuyuTimelineSchedule.dates(from: now, calendar: calendar)
            return dates.map { date in
                MuyuEntry(date: date, progress: progress,
                          saying: catalog.saying(for: date, seed: progress.dailySeed, calendar: calendar),
                          errorMessage: error)
            }
        } catch {
            Logger(subsystem: "local.littlecomponent.app.widget", category: "MuyuProvider")
                .error("木鱼球数据读取失败：\(error.localizedDescription, privacy: .public)")
            return [MuyuEntry(date: now, progress: nil, saying: "", errorMessage: "数据暂时无法读取")]
        }
    }
}

struct MuyuBallWidget: Widget {
    var body: some WidgetConfiguration {
        // 保留已有实例的 kind 和尺寸；系统会把同一 kind 的尺寸一起刷新。
        StaticConfiguration(kind: "LittleComponentWidget", provider: MuyuProvider()) { entry in
            MuyuWidgetView(entry: entry)
        }
        .configurationDisplayName("木鱼球")
        .description("敲一圈木鱼球，积一分功德，添一点福缘。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// WidgetKit 的旧回调 API 允许异步完成，但未标记 Sendable；不可变包装仅交给一个 Task 调用一次。
private struct WidgetReply<Value>: @unchecked Sendable {
    private let completion: (Value) -> Void

    init(_ completion: @escaping (Value) -> Void) {
        self.completion = completion
    }

    func call(_ value: Value) { completion(value) }
}

@main
struct SucculentGardenWidgetBundle: WidgetBundle {
    var body: some Widget {
        MuyuBallWidget()
        SucculentGardenWidget()
    }
}
