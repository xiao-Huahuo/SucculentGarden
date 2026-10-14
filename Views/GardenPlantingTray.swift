// 主页面真正的拖放接收区；与 Widget 共用植株内容，保存成功后才显示新苗。
import SwiftUI

struct GardenPlantingTray: View {
    let model: GardenModel
    let garden: SucculentGarden
    let date: Date
    static let width: CGFloat = 360
    static let scrollClearance: CGFloat = 240

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("桌面花盆").font(.caption.weight(.medium))
                Spacer()
                Text("花盆 \(model.selectedSlot + 1)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
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
                        .dropDestination(for: GardenDragItem.self) { items, _ in
                            guard !model.isBusy, let item = items.first else { return false }
                            switch item.kind {
                            case .leaf:
                                guard garden.leaves.contains(where: { $0.id == item.id }) else { return false }
                                Task { await model.sow(item.id, in: slot) }
                            case .plant:
                                guard garden.plants.contains(where: { $0.id == item.id }) else { return false }
                                Task { await model.assign(item.id, to: slot) }
                            }
                            model.selectedSlot = slot
                            return true
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
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
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
