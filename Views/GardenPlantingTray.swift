// 整个玻璃浮层接收拖放，再以当前独立花园及盆面根点定位；不依赖系统桌面拖放。
import SwiftUI
import OSLog

struct GardenPlantingTray: View {
    let model: GardenModel
    let garden: SucculentGarden
    let date: Date
    @State private var targetedPot: UUID?

    private var layout: GardenLayout { model.currentLayout ?? garden.layouts[0] }
    private var pots: [GardenPot] { layout.pots.compactMap { garden.pot(id: $0) } }
    private var bodyHeight: CGFloat {
        104 + (pots.map { $0.kind == .ordinary ? 44 : CGFloat(max(1, $0.plants.compactMap { $0 }.count)) * 26 }.max() ?? 30)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                layoutPicker
                Spacer(minLength: 0)
                Menu {
                    Button("新建小号花园") { Task { await model.createLayout(.small) } }
                    Button("新建中号花园") { Task { await model.createLayout(.medium) } }
                } label: { Image(systemName: "plus") }.menuStyle(.borderlessButton).fixedSize()
                    .accessibilityLabel("新建独立花园")
                Button { Task { await model.refreshWidgets() } } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.plain).accessibilityLabel("刷新桌面组件清单")
            }
            .font(.caption)
            if let error = model.widgetReadError { Text(error).font(.caption2).foregroundStyle(.secondary) }
            if model.layoutIsAmbiguous {
                Text("此花园绑定了多个组件。请编辑桌面组件，为每块选择不同花园。")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                GeometryReader { geometry in
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(pots) { pot in
                            GardenPotContent(pot: pot, garden: garden, date: date, showsCountdown: true)
                                .frame(width: geometry.size.width * CGFloat(pot.kind.space) / CGFloat(layout.size.space))
                                .contentShape(Rectangle())
                                .onTapGesture { model.selectedPotID = pot.id }
                                .overlay(alignment: .topTrailing) {
                                    Button { model.openPot(pot.id) } label: {
                                        Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .medium))
                                            .frame(width: 22, height: 22).background(.quaternary, in: Circle())
                                    }.buttonStyle(.plain).accessibilityLabel("选择\(pot.title)的多肉")
                                }
                                .background {
                                    RoundedRectangle(cornerRadius: 12).fill(targetedPot == pot.id ? Color.accentColor.opacity(0.12) : .clear)
                                }
                                .contextMenu {
                                    Button("选择多肉") { model.openPot(pot.id) }
                                    ForEach(pot.plants.compactMap { garden.plant(id: $0) }) { plant in
                                        Button("撤下\(plant.species.title)") { Task { await model.removePlant(plant.id) } }
                                    }
                                    Divider()
                                    Button("撤下", role: .destructive) { Task { await model.withdrawPot(pot.id) } }
                                }
                                .accessibilityIdentifier("garden.pot.\(pot.number)")
                        }
                        if pots.reduce(0, { $0 + $1.kind.space }) < layout.size.space {
                            Button { model.section = .pots } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus").font(.title2.weight(.light))
                                    Text("放置花盆").font(.caption)
                                }.foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
                            }.buttonStyle(.plain).accessibilityLabel("前往花盆商店和库存")
                        }
                    }
                }.frame(height: bodyHeight)
            }
        }
        .padding(GardenPlantingLayout.padding)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .dropDestination(for: GardenDragItem.self, isEnabled: !model.isBusy && !model.layoutIsAmbiguous) { items, session in
            guard let item = items.first, let current = model.garden else { return }
            let width = session.size.width - GardenPlantingLayout.padding * 2
            let point = CGPoint(x: session.location.x - GardenPlantingLayout.padding,
                                y: session.location.y - GardenPlantingLayout.padding - 24)
            let frames = GardenPotGeometry.frames(layout: layout, garden: current, width: width)
            let hit = frames.first { point.x >= $0.rect.minX && point.x < $0.rect.maxX }
            Task {
                if item.kind == .pot { await model.placePot(item.id, before: hit?.pot.id) }
                else if let hit {
                    let local = CGPoint(x: point.x - hit.rect.minX, y: point.y)
                    let position = GardenPotGeometry.nearestPosition(kind: hit.pot.kind, point: local, width: hit.rect.width, height: 100)
                    await model.plant(item, in: hit.pot.id, position: position)
                } else { model.notice = GardenNotice(message: "请先在这个花园放置花盆，再种入多肉。", isError: true) }
            }
        }
        .onDropSessionUpdated { session in
            let x = session.location.x - GardenPlantingLayout.padding
            targetedPot = GardenPotGeometry.frames(layout: layout, garden: garden, width: session.size.width - GardenPlantingLayout.padding * 2)
                .first { x >= $0.rect.minX && x < $0.rect.maxX }?.pot.id
            if session.phase != .entering && session.phase != .active { targetedPot = nil }
        }
        .disabled(model.isBusy)
    }

    private var layoutPicker: some View {
        Menu {
            if !model.configuredWidgets.isEmpty {
                Section("桌面上的组件") {
                    ForEach(model.configuredWidgets) { binding in
                        if let id = binding.layoutID, let layout = garden.layout(id: id) {
                            Button("\(layout.name) · 组件\(Int(binding.id).map { $0 + 1 } ?? 1)") { model.selectLayout(id) }
                        } else {
                            Button("未配置的\(binding.size.title)组件：创建花园") { Task { await model.createLayout(binding.size) } }
                        }
                    }
                }
            }
            Section("全部花园") {
                ForEach(garden.layouts) { layout in
                    Button(layout.name) { model.selectLayout(layout.id) }
                }
            }
        } label: { Text(layout.name).fontWeight(.medium).lineLimit(1) }
        .menuStyle(.borderlessButton).fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("切换独立花园，当前\(layout.name)")
    }
}
