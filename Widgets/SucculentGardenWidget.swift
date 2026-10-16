// 每块组件只读取配置所选的独立花园；重复绑定、尺寸不匹配不会误展示其他组件的盆。
import Foundation
import SwiftUI
import WidgetKit
import OSLog

struct GardenEntry: TimelineEntry {
    let date: Date
    let garden: SucculentGarden
    let layoutID: UUID?
    var errorMessage: String?
}

struct GardenTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GardenEntry {
        var sample = SucculentGarden()
        let count = context.family == .systemSmall ? 1 : 3
        sample.plants = (0..<count).map { _ in
            SucculentPlant(id: UUID(), acquiredAt: .now, growthSeconds: SucculentStage.adult.startSeconds, growthUpdatedAt: .now)
        }
        sample.slots = sample.plants.map { $0.id } + Array(repeating: nil, count: 3 - count)
        if count == 1 {
            sample.layouts = [GardenLayout(id: GardenLayout.originalID, name: "小号花园", size: .small, pots: [GardenPot.originalIDs[0]])]
        }
        return GardenEntry(date: .now, garden: sample, layoutID: GardenLayout.originalID)
    }

    func snapshot(for configuration: GardenWidgetConfiguration, in context: Context) async -> GardenEntry {
        if context.isPreview { return placeholder(in: context) }
        return await readEntry(configuration: configuration, family: context.family)
    }

    func timeline(for configuration: GardenWidgetConfiguration, in context: Context) async -> Timeline<GardenEntry> {
        let entry = await readEntry(configuration: configuration, family: context.family)
        var dates = [entry.date, entry.date.addingTimeInterval(86_400)]
        let pots = entry.layoutID.flatMap { entry.garden.layout(id: $0) }?.pots ?? []
        let selected = Set(pots.compactMap { entry.garden.pot(id: $0) }.flatMap(\.plants).compactMap { $0 })
        for plant in entry.garden.plants where selected.contains(plant.id) {
            dates.append(contentsOf: plant.transitionDates(after: entry.date, rate: entry.garden.effectiveRate(for: plant.species)))
        }
        let entries = Set(dates).sorted().map {
            GardenEntry(date: $0, garden: entry.garden, layoutID: entry.layoutID, errorMessage: entry.errorMessage)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func readEntry(configuration: GardenWidgetConfiguration, family: WidgetFamily) async -> GardenEntry {
        let selected = configuration.layout.flatMap { UUID(uuidString: $0.id) } ?? (family == .systemMedium ? GardenLayout.originalID : nil)
        do {
            let garden = try await SucculentStore.shared.read()
            let bindings = try await GardenWidgetBinding.configured()
            let size: GardenLayoutSize = family == .systemSmall ? .small : .medium
            let message = GardenWidgetBinding.problem(layoutID: selected, size: size, garden: garden, bindings: bindings)
            return GardenEntry(date: .now, garden: garden, layoutID: selected, errorMessage: message)
        } catch {
            Logger(subsystem: "local.littlecomponent.app.widget", category: "GardenTimeline")
                .error("共享花园读取失败：\(error.localizedDescription, privacy: .public)")
            return GardenEntry(date: .now, garden: SucculentGarden(), layoutID: selected, errorMessage: "花园暂时无法读取，请打开主页面检查。")
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
        .description("每块组件各有一座花园。小号单盆，中号可组合普通盆、宽盆或长盆。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SucculentWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GardenEntry
    var body: some View { SucculentWidgetContent(entry: entry, family: family) }
}

struct SucculentWidgetContent: View {
    let entry: GardenEntry
    let family: WidgetFamily

    var body: some View {
        Group {
            if let error = entry.errorMessage {
                Link(destination: GardenRoute.url(layoutID: entry.layoutID ?? GardenLayout.originalID)) {
                    Text(error).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }.buttonStyle(.plain)
            } else if let id = entry.layoutID, let layout = entry.garden.layout(id: id) {
                GeometryReader { geometry in
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(layout.pots.compactMap { entry.garden.pot(id: $0) }) { pot in
                            GardenPotContent(pot: pot, garden: entry.garden, date: entry.date, isWidget: true)
                                .frame(width: geometry.size.width * CGFloat(pot.kind.space) / CGFloat(layout.size.space))
                                .overlay(alignment: .topTrailing) {
                                    Link(destination: GardenRoute.url(layoutID: id, potID: pot.id)) {
                                        Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .medium))
                                            .frame(width: 22, height: 22).background(.quaternary, in: Circle())
                                    }.buttonStyle(.plain).accessibilityLabel("选择\(pot.title)的多肉")
                                }
                        }
                        if layout.pots.compactMap({ entry.garden.pot(id: $0) }).reduce(0, { $0 + $1.kind.space }) < layout.size.space {
                            Link(destination: GardenRoute.url(layoutID: id)) {
                                Label("放置花盆", systemImage: "plus").font(.caption).foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }.buttonStyle(.plain)
                        }
                    }
                }
                .widgetURL(GardenRoute.url(layoutID: id, potID: layout.pots.first))
            }
        }
        .containerBackground(for: .widget) { Color(nsColor: .windowBackgroundColor) }
    }
}
