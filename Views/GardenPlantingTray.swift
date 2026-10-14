// 主页面真正的拖放接收区；与 Widget 共用植株内容，保存成功后才显示新苗。
import SwiftUI

struct GardenPlantingTray: View {
    let model: GardenModel
    let garden: SucculentGarden
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("桌面花盆").font(.headline)
                Spacer()
                Text("正在设置花盆 \(model.selectedSlot + 1)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { slot in
                    slotContent(slot)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { model.selectedSlot = slot }
                        .overlay(alignment: .topTrailing) {
                            Button {
                                model.openSlot(slot)
                            } label: {
                                Image(systemName: "arrow.up.right").frame(width: 22, height: 22)
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
            HStack {
                Text("拖入繁殖材料开始种植，拖动多肉可换盆。")
                Spacer()
                Text("成长 \(garden.growthRate.formatted())×")
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
    }

    @ViewBuilder private func slotContent(_ slot: Int) -> some View {
        if let plant = garden.plant(in: slot) {
            SucculentSlotContent(plant: plant, date: date, rate: garden.effectiveRate(for: plant.species), artSize: 96, showsCountdown: true)
                .contentShape(Rectangle())
                .draggable(GardenDragItem(kind: .plant, id: plant.id))
        } else {
            SucculentSlotContent(plant: nil, date: date, rate: garden.growthRate, artSize: 96)
        }
    }
}
