// Widget只读唯一的桌面花园；小号选普通盆，中号按花盆宽度展示全部三格。
import Foundation
import SwiftUI
import WidgetKit
import OSLog

struct GardenEntry: TimelineEntry {
    let date: Date
    let garden: SucculentGarden
    let smallChoice: GardenPotChoice
    var errorMessage: String?
}

struct GardenTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GardenEntry {
        var sample = SucculentGarden()
        sample.plants = (0..<3).map { _ in
            SucculentPlant(id: UUID(), acquiredAt: .now, growthSeconds: SucculentStage.adult.startSeconds, growthUpdatedAt: .now)
        }
        sample.slots = sample.plants.map { $0.id }
        return GardenEntry(date: .now, garden: sample, smallChoice: .first)
    }

    func snapshot(for configuration: GardenWidgetConfiguration, in context: Context) async -> GardenEntry {
        if context.isPreview { return placeholder(in: context) }
        return await readEntry(configuration: configuration)
    }

    func timeline(for configuration: GardenWidgetConfiguration, in context: Context) async -> Timeline<GardenEntry> {
        let entry = await readEntry(configuration: configuration)
        var dates = [entry.date, entry.date.addingTimeInterval(86_400)]
        let pots = entry.garden.layout(id: GardenLayout.originalID)?.pots ?? []
        let selected = Set(pots.compactMap { entry.garden.pot(id: $0) }.flatMap(\.plants).compactMap { $0 })
        for plant in entry.garden.plants where selected.contains(plant.id) {
            dates.append(contentsOf: plant.transitionDates(after: entry.date, rate: entry.garden.effectiveRate(for: plant.species)))
        }
        let entries = Set(dates).sorted().map {
            GardenEntry(date: $0, garden: entry.garden, smallChoice: entry.smallChoice, errorMessage: entry.errorMessage)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func readEntry(configuration: GardenWidgetConfiguration) async -> GardenEntry {
        do {
            let garden = try await SucculentStore.shared.read()
            return GardenEntry(date: .now, garden: garden, smallChoice: configuration.pot)
        } catch {
            Logger(subsystem: "local.littlecomponent.app.widget", category: "GardenTimeline")
                .error("共享花园读取失败：\(error.localizedDescription, privacy: .public)")
            return GardenEntry(date: .now, garden: SucculentGarden(), smallChoice: configuration.pot,
                               errorMessage: "花园暂时无法读取，请打开主页面检查。")
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
        .description("只放一块多肉花园组件。小号普通盆，中号可组合普通盆、宽盆或长盆；重复添加会共用花园。")
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

    private var layout: GardenLayout? { entry.garden.layout(id: GardenLayout.originalID) }
    private var smallPot: GardenPot? { entry.garden.smallWidgetPot(choice: entry.smallChoice) }

    var body: some View {
        Group {
            if let error = entry.errorMessage {
                Link(destination: GardenRoute.url(layoutID: GardenLayout.originalID)) {
                    Text(error).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }.buttonStyle(.plain)
            } else if family == .systemSmall {
                if let pot = smallPot {
                    GardenPotContent(pot: pot, garden: entry.garden, date: entry.date, isWidget: true)
                        .overlay(alignment: .topTrailing) {
                            Link(destination: GardenRoute.url(layoutID: GardenLayout.originalID, potID: pot.id)) {
                                Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .medium))
                                    .frame(width: 22, height: 22).background(.quaternary, in: Circle())
                            }.buttonStyle(.plain).accessibilityLabel("选择\(pot.title)的多肉")
                        }
                        .widgetURL(GardenRoute.url(layoutID: GardenLayout.originalID, potID: pot.id))
                } else {
                    Link(destination: GardenRoute.url(layoutID: GardenLayout.originalID)) {
                        Text("小号只能显示普通盆，请到主页面摆放一只。")
                            .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }.buttonStyle(.plain)
                }
            } else if let layout {
                GeometryReader { geometry in
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(layout.pots.compactMap { entry.garden.pot(id: $0) }) { pot in
                            GardenPotContent(pot: pot, garden: entry.garden, date: entry.date, isWidget: true)
                                .frame(width: geometry.size.width * CGFloat(pot.kind.space) / CGFloat(layout.size.space))
                                .overlay(alignment: .topTrailing) {
                                    Link(destination: GardenRoute.url(layoutID: GardenLayout.originalID, potID: pot.id)) {
                                        Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .medium))
                                            .frame(width: 22, height: 22).background(.quaternary, in: Circle())
                                    }.buttonStyle(.plain).accessibilityLabel("选择\(pot.title)的多肉")
                                }
                        }
                        if layout.pots.compactMap({ entry.garden.pot(id: $0) }).reduce(0, { $0 + $1.kind.space }) < layout.size.space {
                            Link(destination: GardenRoute.url(layoutID: GardenLayout.originalID)) {
                                Label("放置花盆", systemImage: "plus").font(.caption).foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }.buttonStyle(.plain)
                        }
                    }
                }
                .widgetURL(GardenRoute.url(layoutID: GardenLayout.originalID, potID: layout.pots.first))
            }
        }
        .containerBackground(for: .widget) { Color(nsColor: .windowBackgroundColor) }
    }
}
