// 多肉 Widget 只读 App Group；时间线提前安排阶段切换，选择按钮打开主页面对应花盆。
import AppIntents
import Foundation
import SwiftUI
import WidgetKit
import OSLog

enum GardenPotChoice: Int, AppEnum {
    case first = 0, second = 1, third = 2
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "花盆")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .first: "花盆 1", .second: "花盆 2", .third: "花盆 3"
    ]
}

struct GardenWidgetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "多肉花园"
    static let description = IntentDescription("选择小号组件显示的花盆，中号显示三个花盆。")
    @Parameter(title: "小号显示", default: .first) var pot: GardenPotChoice
}

struct GardenEntry: TimelineEntry {
    let date: Date
    let garden: SucculentGarden
    let smallSlot: Int
    var errorMessage: String?
}

struct GardenTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GardenEntry {
        var sample = SucculentGarden()
        sample.plants = (0..<3).map { _ in
            SucculentPlant(id: UUID(), acquiredAt: .now,
                           growthSeconds: SucculentStage.adult.startSeconds, growthUpdatedAt: .now)
        }
        sample.slots = sample.plants.map { $0.id }
        return GardenEntry(date: .now, garden: sample, smallSlot: 0)
    }

    func snapshot(for configuration: GardenWidgetConfiguration, in context: Context) async -> GardenEntry {
        if context.isPreview { return placeholder(in: context) }
        return await readEntry(configuration: configuration)
    }

    func timeline(for configuration: GardenWidgetConfiguration, in context: Context) async -> Timeline<GardenEntry> {
        let entry = await readEntry(configuration: configuration)
        var dates = [entry.date, entry.date.addingTimeInterval(86_400)]
        let selected = Set(entry.garden.slots.compactMap { $0 })
        for plant in entry.garden.plants where selected.contains(plant.id) {
            dates.append(contentsOf: plant.transitionDates(after: entry.date, rate: entry.garden.effectiveRate(for: plant.species)))
        }
        let entries = Set(dates).sorted().map {
            GardenEntry(date: $0, garden: entry.garden, smallSlot: entry.smallSlot, errorMessage: entry.errorMessage)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func readEntry(configuration: GardenWidgetConfiguration) async -> GardenEntry {
        do {
            let garden = try await SucculentStore.shared.read()
            return GardenEntry(date: .now, garden: garden, smallSlot: configuration.pot.rawValue)
        } catch {
            Logger(subsystem: "local.littlecomponent.app.widget", category: "GardenTimeline")
                .error("共享花园读取失败：\(error.localizedDescription, privacy: .public)")
            return GardenEntry(date: .now, garden: SucculentGarden(), smallSlot: configuration.pot.rawValue,
                               errorMessage: "花园暂时无法读取")
        }
    }
}

struct SucculentGardenWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "SucculentGardenWidget", intent: GardenWidgetConfiguration.self,
                               provider: GardenTimelineProvider()) { entry in
            SucculentWidgetView(entry: entry)
        }
        .configurationDisplayName("多肉花园")
        .description("种下繁殖材料，等它慢慢长大。小号一盆，中号三盆。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SucculentWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GardenEntry

    var body: some View { SucculentWidgetContent(entry: entry, family: family) }
}

// 把系统family传给同一份内容，便于离屏检查两种实际布局。
struct SucculentWidgetContent: View {
    let entry: GardenEntry
    let family: WidgetFamily

    var body: some View {
        VStack(spacing: 2) {
            if let error = entry.errorMessage {
                Text(error).font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 10) {
                    ForEach(family == .systemSmall ? [entry.smallSlot] : [0, 1, 2], id: \.self) { slot in
                        SucculentSlotContent(plant: entry.garden.plant(in: slot), date: entry.date,
                                             rate: entry.garden.plant(in: slot).map { entry.garden.effectiveRate(for: $0.species) } ?? entry.garden.growthRate,
                                             artSize: family == .systemSmall ? 82 : 78, isWidget: true)
                            .frame(maxWidth: .infinity)
                            .overlay(alignment: .topTrailing) {
                                Link(destination: GardenRoute.url(for: slot)) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 11, weight: .medium))
                                        .frame(width: 22, height: 22)
                                        .background(.quaternary, in: Circle())
                                }
                                .buttonStyle(.plain)
                                .help("选择花盆 \(slot + 1) 的多肉")
                                .accessibilityLabel("选择花盆 \(slot + 1) 的多肉")
                            }
                    }
                }
            }
        }
        .containerBackground(for: .widget) { Color(nsColor: .windowBackgroundColor) }
    }
}
