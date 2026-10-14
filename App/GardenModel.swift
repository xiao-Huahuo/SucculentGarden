// 主窗口共享状态：文件保存成功后再更新界面，并通知 Widget 重新读取同一份花园。
import Foundation
import Observation
import WidgetKit
import OSLog

@MainActor @Observable
final class GardenModel {
    var garden: SucculentGarden?
    var errorMessage: String?
    var notice: GardenNotice?
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
    private let store: SucculentStore

    init(store: SucculentStore = .shared) { self.store = store }

    func load() async {
        await perform { try await self.store.read(createIfMissing: true) }
    }

    func claimLeaf(_ species: SucculentSpecies = .huangli) async {
        await perform(success: { _, after in
            "已领取\(species.title)\(species.propagationTitle)，今日剩余\(after.remainingClaims(at: .now))次"
        }) { try await self.store.claimLeaf(species: species) }
    }

    func sow(_ id: UUID, in slot: Int) async {
        let title = garden?.leaves.first { $0.id == id }?.species.title ?? "多肉"
        await perform(success: { _, _ in "已将\(title)种入花盆\(slot + 1)" }) {
            try await self.store.sow(leafID: id, in: slot)
        }
    }

    func buy(_ stage: SucculentStage, species: SucculentSpecies = .huangli) async {
        let verb = species.purchasePrice(for: stage) == 0 ? "领取" : "购买"
        await perform(success: { _, _ in "已\(verb)\(species.title)（\(species.stageTitle(for: stage))），已放入我的多肉" }) {
            try await self.store.buy(stage: stage, species: species)
        }
    }

    func assign(_ id: UUID, to slot: Int) async {
        let title = plantTitle(id)
        await perform(success: { _, _ in "已将\(title)放入花盆\(slot + 1)" }) {
            try await self.store.assign(plantID: id, to: slot)
        }
    }

    func clear(_ slot: Int) async {
        let title = garden?.plant(in: slot)?.species.title ?? "多肉"
        await perform(success: { _, _ in "\(title)已移回收藏，花盆\(slot + 1)已清空" }) {
            try await self.store.clear(slot: slot)
        }
    }

    func sell(_ id: UUID) async {
        let title = plantTitle(id)
        await perform(success: { before, after in "已出售\(title)，获得 $\(after.money - (before?.money ?? after.money))" }) {
            try await self.store.sell(plantID: id)
        }
    }

    func disassemble(_ id: UUID) async {
        let title = plantTitle(id)
        await perform(success: { before, after in "已拆分\(title)，获得\(after.leaves.count - (before?.leaves.count ?? 0))份繁殖材料" }) {
            try await self.store.disassemble(plantID: id)
        }
    }

    func harvest(_ id: UUID) async {
        let title = plantTitle(id)
        await perform(success: { before, after in "已摘取\(title)小芽\(after.leaves.count - (before?.leaves.count ?? 0))个，母株保留" }) {
            try await self.store.harvest(plantID: id)
        }
    }

    func discardLeaf(_ id: UUID) async {
        let species = garden?.leaves.first { $0.id == id }?.species
        await perform(success: { _, _ in "已丢弃一份\(species.map { $0.title + $0.propagationTitle } ?? "繁殖材料")" }) {
            try await self.store.discardLeaf(leafID: id)
        }
    }

    func discardLeaves(_ species: SucculentSpecies) async {
        await perform(success: { before, after in
            let count = (before?.leaves.count ?? 0) - after.leaves.count
            return "已丢弃\(species.title)\(species.propagationTitle)\(species.propagationQuantity(count: count))"
        }) { try await self.store.discardLeaves(species: species) }
    }

    func changeRate(_ rate: Double) async {
        await perform(success: { _, after in "成长倍率已设为\(after.growthRate.formatted())×" }) {
            try await self.store.changeRate(to: rate)
        }
    }

    func changeMultipliers(_ multipliers: GardenGrowthMultipliers, message: String = "时间乘数已保存，成长间隔已更新") async {
        await perform(success: { _, _ in message }) {
            try await self.store.changeMultipliers(to: multipliers)
        }
    }

    func dismissNotice(_ id: UUID) {
        guard notice?.id == id else { return }
        notice = nil
    }

    private func plantTitle(_ id: UUID) -> String {
        garden?.plants.first { $0.id == id }?.species.title ?? "多肉"
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
        garden.collectionPlants.filter {
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

    private func perform(success: ((SucculentGarden?, SucculentGarden) -> String)? = nil,
                         _ action: () async throws -> SucculentGarden) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let before = garden
            let after = try await action()
            garden = after
            errorMessage = nil
            if let success { notice = GardenNotice(message: success(before, after)) }
            else { notice = nil }
            WidgetCenter.shared.reloadTimelines(ofKind: "SucculentGardenWidget")
        } catch {
            errorMessage = error.localizedDescription
            notice = GardenNotice(message: error.localizedDescription, isError: true)
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
