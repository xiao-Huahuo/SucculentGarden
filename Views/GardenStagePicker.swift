// 商店统一切换展示时期，收藏筛选实际时期；未选形态时以1～6标记序号。
import SwiftUI

struct GardenStagePicker: View {
    @Bindable var model: GardenModel

    private var selection: Binding<Int?> {
        Binding(get: { model.section == .shop ? model.shopStageIndex : model.collectionStageIndex },
                set: { if model.section == .shop { model.shopStageIndex = $0 } else { model.collectionStageIndex = $0 } })
    }

    var body: some View {
        Picker("阶段", selection: selection) {
            Text(model.section == .shop ? "单独选择" : "全部阶段").tag(nil as Int?)
            ForEach(Array(model.stageTitles(for: model.section).enumerated()), id: \.offset) { index, title in
                Text(title).tag(Optional(index))
            }
        }
        .pickerStyle(.menu)
        .fixedSize()
        .accessibilityLabel(model.section == .shop ? "统一选择商品阶段" : "按多肉阶段筛选")
        .accessibilityIdentifier("garden.stage.selector")
    }
}
