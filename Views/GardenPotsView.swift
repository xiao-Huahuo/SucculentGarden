// 花盆页上方为商店，下方为拥有的盆；操作归属右下当前花园，盆和植物分开购买。
import SwiftUI

struct GardenPotsView: View {
    let model: GardenModel
    let garden: SucculentGarden

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("花盆商店").font(.headline)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                ForEach(GardenPotKind.allCases) { kind in
                    VStack(spacing: 8) {
                        FlowerpotArtwork(kind: kind).frame(width: 150, height: 90)
                        Text(kind.title).font(.headline)
                        Text("占\(kind.space)格 · 可种\(kind.capacity)株").font(.caption).foregroundStyle(.secondary)
                        Button("购买 · $\(kind.price)") { Task { await model.buyPot(kind) } }
                            .buttonStyle(.borderedProminent).disabled(model.isBusy || garden.money < kind.price)
                    }.frame(maxWidth: .infinity)
                }
            }
            Text("我的花盆").font(.headline)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                ForEach(garden.pots.sorted { a, b in
                    let left = garden.layout(containing: a.id) != nil, right = garden.layout(containing: b.id) != nil
                    return left == right ? a.number < b.number : left
                }) { pot in
                    VStack(spacing: 8) {
                        FlowerpotArtwork(kind: pot.kind).frame(width: 150, height: 90)
                        Text("\(pot.title) · \(pot.kind.title)").font(.headline)
                        Text(garden.layout(containing: pot.id)?.name ?? "库存")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("\(pot.plants.compactMap { $0 }.count)／\(pot.kind.capacity)株").font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).contentShape(Rectangle())
                    .draggable(GardenDragItem(kind: .pot, id: pot.id))
                    .overlay(alignment: .topTrailing) {
                        Menu { actions(pot) } label: { Image(systemName: "ellipsis") }
                            .menuStyle(.borderlessButton).fixedSize().accessibilityLabel("\(pot.title)操作")
                    }
                    .contextMenu { actions(pot) }
                }
            }
        }
    }

    @ViewBuilder private func actions(_ pot: GardenPot) -> some View {
        if garden.layout(containing: pot.id) != nil {
            Button("查看所在花园") { model.openPot(pot.id) }
            Button("撤下", role: .destructive) { Task { await model.withdrawPot(pot.id) } }
        } else {
            Button("上架到\(model.currentLayout?.name ?? "当前花园")") { Task { await model.placePot(pot.id) } }
                .disabled(model.layoutIsAmbiguous)
        }
    }
}
