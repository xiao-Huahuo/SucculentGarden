// 右下唯一桌面花园控制摆盆与种植入口。
import Foundation

extension GardenModel {
    func openPot(_ id: UUID) {
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
        await perform(success: { _, _ in "花盆已放入桌面花园" }) {
            let state = try await self.store.placePot(id: id, in: GardenLayout.originalID, before: otherID)
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
        await perform(success: { _, _ in "多肉已放入花盆，开始继续成长" }) {
            switch item.kind {
            case .leaf: try await self.store.sow(leafID: item.id, inPot: potID, position: position)
            case .plant: try await self.store.assign(plantID: item.id, toPot: potID, position: position)
            case .pot: throw GardenError.invalidPotPosition
            }
        }
    }
}
