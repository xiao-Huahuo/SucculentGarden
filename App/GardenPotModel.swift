// 右下当前花园控制所有摆盆/种植入口；系统实际组件清单在前台刷新，不依赖固定三个槽。
import Foundation

extension GardenModel {
    func refreshWidgets() async {
        do {
            configuredWidgets = try await GardenWidgetBinding.configured()
            widgetReadError = nil
        } catch { widgetReadError = "暂时无法读取桌面组件，请点击刷新。" }
    }

    func createLayout(_ size: GardenLayoutSize) async {
        await perform(success: { _, _ in "已创建独立花园，请在桌面组件的编辑菜单中选择它" }) {
            let state = try await self.store.createLayout(size: size)
            if let layout = state.layouts.last {
                self.selectedLayoutID = layout.id
                self.selectedPotID = nil
            }
            return state
        }
    }

    func selectLayout(_ id: UUID) {
        guard let layout = garden?.layout(id: id) else { return }
        selectedLayoutID = id
        selectedPotID = layout.pots.first
    }

    func openPot(_ id: UUID) {
        if let layout = garden?.layout(containing: id) { selectedLayoutID = layout.id }
        selectedPotID = id
        section = .collection
        search = ""
        collectionMorphology = nil
        collectionStageIndex = nil
    }

    func buyPot(_ kind: GardenPotKind) async {
        await perform(success: { _, _ in "已购买\(kind.title)，花盆已放入库存" }) { try await self.store.buyPot(kind: kind) }
    }

    func placePot(_ id: UUID, before otherID: UUID? = nil) async {
        guard let layout = currentLayout, !layoutIsAmbiguous else { return }
        await perform(success: { _, _ in "花盆已放入\(layout.name)" }) {
            let state = try await self.store.placePot(id: id, in: layout.id, before: otherID)
            self.selectedPotID = id
            return state
        }
    }

    func withdrawPot(_ id: UUID) async {
        let empty = garden?.pot(id: id)?.isEmpty == true
        await perform(success: { _, _ in empty ? "空花盆已撤回库存" : "盆内多肉已移回收藏并暂停成长，花盆保留" }) {
            try await self.store.withdrawPot(id: id)
        }
    }

    func removePlant(_ id: UUID) async {
        await perform(success: { _, _ in "多肉已移回收藏并暂停成长，花盆保留" }) { try await self.store.removePlant(id: id) }
    }

    func plant(_ item: GardenDragItem, in potID: UUID, position: Int? = nil) async {
        guard !layoutIsAmbiguous else { return }
        await perform(success: { _, _ in "多肉已放入花盆，开始继续成长" }) {
            switch item.kind {
            case .leaf: try await self.store.sow(leafID: item.id, inPot: potID, position: position)
            case .plant: try await self.store.assign(plantID: item.id, toPot: potID, position: position)
            case .pot: throw GardenError.invalidPotPosition
            }
        }
    }
}
