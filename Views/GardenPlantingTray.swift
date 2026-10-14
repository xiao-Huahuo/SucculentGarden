// 主页面真正的拖放接收区；与 Widget 共用植株内容，保存成功后才显示新苗。
import SwiftUI
import OSLog

struct GardenPlantingTray: View {
    let model: GardenModel
    let garden: SucculentGarden
    let date: Date
    @State private var targetedSlot: Int?
    private let logger = Logger(subsystem: "local.littlecomponent.app", category: "GardenDrop")

    var body: some View {
        VStack(alignment: .leading, spacing: GardenPlantingLayout.spacing) {
            HStack {
                Text("桌面花盆").font(.caption.weight(.medium))
                Spacer()
                Text("花盆 \(model.selectedSlot + 1)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: GardenPlantingLayout.spacing) {
                ForEach(0..<3, id: \.self) { slot in
                    slotContent(slot)
                        .padding(6)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { model.selectedSlot = slot }
                        .overlay(alignment: .topTrailing) {
                            Button {
                                model.openSlot(slot)
                            } label: {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .medium))
                                    .frame(width: 22, height: 22)
                                    .background(.quaternary, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .padding(5)
                            .help("选择花盆 \(slot + 1) 的多肉")
                            .accessibilityLabel("选择花盆 \(slot + 1) 的多肉")
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(targetedSlot == slot ? Color.accentColor.opacity(0.12) : .clear)
                        }
                        .contextMenu {
                            Button("选择多肉") { model.openSlot(slot) }
                            if garden.plant(in: slot) != nil {
                                Button("移回收藏") { Task { await model.clear(slot) } }
                            }
                        }
                        .accessibilityIdentifier("garden.slot.\(slot)")
                }
            }
        }
        .padding(GardenPlantingLayout.padding)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        // 在玻璃合成层外注册整个浮层的接收区，再按实际落点选择三盆之一。
        .dropDestination(for: GardenDragItem.self, isEnabled: !model.isBusy) { items, session in
            guard let item = items.first,
                  let slot = GardenPlantingLayout.slot(at: session.location.x, width: session.size.width),
                  let current = model.garden else { return }
            let owned = item.kind == .leaf ? current.leaves.contains { $0.id == item.id } : current.plants.contains { $0.id == item.id }
            guard owned else { return }
            logger.info("接收花盆拖放：花盆\(slot + 1)，类型\(item.kind.rawValue, privacy: .public)")
            model.selectedSlot = slot
            Task {
                switch item.kind {
                case .leaf: await model.sow(item.id, in: slot)
                case .plant: await model.assign(item.id, to: slot)
                }
            }
        }
        .onDropSessionUpdated { session in
            switch session.phase {
            case .entering, .active:
                targetedSlot = GardenPlantingLayout.slot(at: session.location.x, width: session.size.width)
            default: targetedSlot = nil
            }
        }
    }

    @ViewBuilder private func slotContent(_ slot: Int) -> some View {
        if let plant = garden.plant(in: slot) {
            SucculentSlotContent(plant: plant, date: date, rate: garden.effectiveRate(for: plant.species), artSize: 78, showsCountdown: true, showsPlantName: true)
                .contentShape(Rectangle())
                .draggable(GardenDragItem(kind: .plant, id: plant.id))
        } else {
            SucculentSlotContent(plant: nil, date: date, rate: garden.growthRate, artSize: 78)
        }
    }
}
