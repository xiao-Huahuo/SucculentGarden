// 主窗口共享状态：文件保存成功后再更新界面，并通知 Widget 重新读取同一份花园。
import Foundation
import Observation
import WidgetKit
import OSLog

@MainActor @Observable
final class GardenModel {
    var garden: SucculentGarden?
    var errorMessage: String?
    var isBusy = false
    var selectedSlot = 0
    var section: GardenSection = .shop
    var search = ""
    var shopStage: SucculentStage = .juvenile
    var shopStages: [SucculentSpecies: SucculentStage] = [:]
    var shopStageIndex: Int?
    var collectionStageIndex: Int?
    var shopMorphology: SucculentMorphology? {
        didSet {
            if let index = shopStageIndex, let type = shopMorphology, index >= type.stages.count { shopStageIndex = nil }
        }
    }
    var collectionMorphology: SucculentMorphology? {
        didSet {
            if let index = collectionStageIndex, let type = collectionMorphology, index >= type.stages.count { collectionStageIndex = nil }
        }
    }
    private let store = SucculentStore.shared

    func load() async {
        await perform { try await self.store.read(createIfMissing: true) }
    }

    func claimLeaf(_ species: SucculentSpecies = .huangli) async {
        await perform { try await self.store.claimLeaf(species: species) }
    }

    func sow(_ id: UUID, in slot: Int) async {
        await perform { try await self.store.sow(leafID: id, in: slot) }
    }

    func buy(_ stage: SucculentStage, species: SucculentSpecies = .huangli) async {
        let slot = selectedSlot
        await perform { try await self.store.buy(stage: stage, species: species, in: slot) }
    }

    func assign(_ id: UUID, to slot: Int) async {
        await perform { try await self.store.assign(plantID: id, to: slot) }
    }

    func clear(_ slot: Int) async {
        await perform { try await self.store.clear(slot: slot) }
    }

    func sell(_ id: UUID) async {
        await perform { try await self.store.sell(plantID: id) }
    }

    func disassemble(_ id: UUID) async {
        await perform { try await self.store.disassemble(plantID: id) }
    }

    func harvest(_ id: UUID) async {
        await perform { try await self.store.harvest(plantID: id) }
    }

    func changeRate(_ rate: Double) async {
        await perform { try await self.store.changeRate(to: rate) }
    }

    func changeMultipliers(_ multipliers: GardenGrowthMultipliers) async {
        await perform { try await self.store.changeMultipliers(to: multipliers) }
    }

    func openSlot(_ slot: Int) {
        guard (0..<3).contains(slot) else { return }
        selectedSlot = slot
        section = .collection
        search = ""
        collectionMorphology = nil
        collectionStageIndex = nil
    }

    func openShop(stage: SucculentStage = .juvenile) {
        shopStage = stage
        shopStages.removeAll()
        shopStageIndex = nil
        search = ""
        shopMorphology = nil
        section = .shop
    }

    func shopStage(for species: SucculentSpecies) -> SucculentStage {
        if let index = shopStageIndex, species.stages.indices.contains(index) { return species.stages[index] }
        if let chosen = shopStages[species], species.stages.contains(chosen) { return chosen }
        if species.stages.contains(shopStage) { return shopStage }
        return shopStage == .sprout ? species.initialStage : species.stages[1]
    }

    var shopSpecies: [SucculentSpecies] {
        SucculentSpecies.allCases.filter {
            (shopMorphology == nil || $0.morphology == shopMorphology) &&
            (shopStageIndex == nil || $0.stages.indices.contains(shopStageIndex!)) &&
            (search.isEmpty || $0.title.localizedStandardContains(search))
        }
    }

    func stageTitles(for section: GardenSection) -> [String] {
        let type = section == .shop ? shopMorphology : collectionMorphology
        guard let type else { return (1...6).map(String.init) }
        return type.stages.map { type.representativeSpecies.stageTitle(for: $0) }
    }

    func selectShopStage(_ stage: SucculentStage, for species: SucculentSpecies) {
        // 单独修改一张卡片时退出统一时期，其他卡片保留刚才的统一选择。
        if let index = shopStageIndex {
            for kind in shopSpecies { shopStages[kind] = kind.stages[index] }
            shopStageIndex = nil
        }
        shopStages[species] = stage
    }

    func collectionPlants(in garden: SucculentGarden, at date: Date) -> [SucculentPlant] {
        garden.unplacedPlants.filter {
            let stage = $0.stage(at: date, rate: garden.effectiveRate(for: $0.species))
            return (collectionMorphology == nil || $0.species.morphology == collectionMorphology) &&
                (collectionStageIndex == nil || $0.species.stages.firstIndex(of: stage) == collectionStageIndex) &&
                (search.isEmpty || "\($0.species.title) \($0.species.stageTitle(for: stage))".localizedStandardContains(search))
        }
    }

    func handle(_ url: URL) {
        guard let slot = GardenRoute.slot(from: url) else { return }
        openSlot(slot)
        Logger(subsystem: "local.littlecomponent.app", category: "GardenNavigation")
            .info("组件链接已选择花盆 \(slot + 1)")
    }

    private func perform(_ action: () async throws -> SucculentGarden) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            garden = try await action()
            errorMessage = nil
            WidgetCenter.shared.reloadTimelines(ofKind: "SucculentGardenWidget")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum GardenSection: String, CaseIterable, Identifiable {
    case shop = "商店", collection = "我的多肉", leaves = "我的叶片", settings = "设置"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .shop: "storefront"
        case .collection: "leaf"
        case .leaves: "tray"
        case .settings: "slider.horizontal.3"
        }
    }
}
