// 验证组件链接选择正确花盆；不读取或修改真实花园数据。
import Foundation
import Testing

@MainActor
struct GardenNavigationTests {
    @Test
    func inventoryActionsOpenTheRightShopModeWithoutChangingTheGarden() {
        let model = GardenModel()
        model.garden = SucculentGarden()
        model.selectedSlot = 2
        let saved = model.garden
        model.section = .leaves
        model.search = "过滤掉所有商品"
        model.shopStage = .cluster
        model.shopStages[.taodan] = .prime
        model.shopStages[.chihuahua] = .adult
        model.shopMorphology = .stonecropType
        model.openShop(stage: .sprout)
        #expect(model.section == .shop && model.shopStage == .sprout)
        #expect(SucculentSpecies.allCases.allSatisfy { model.shopStage(for: $0) == $0.initialStage })
        #expect(model.search.isEmpty && model.selectedSlot == 2)
        #expect(model.shopMorphology == nil)
        model.section = .collection
        model.search = "黄丽"
        model.openShop()
        #expect(model.section == .shop && model.shopStage == .juvenile)
        #expect(model.search.isEmpty && model.garden == saved)
        #expect(SucculentSpecies.allCases.allSatisfy { model.shopStage(for: $0) == $0.stages[1] })
        model.shopStages[.orangeMonroe] = .cluster
        #expect(model.shopStage(for: .orangeMonroe) == .cluster)
        #expect(model.shopStage(for: .huangli) == .juvenile)
    }

    @Test
    func morphologyAndSearchFilterTogetherWithoutChangingTheGardenOrStages() {
        let model = GardenModel()
        model.garden = SucculentGarden()
        model.selectedSlot = 2
        model.shopStages[.whiteMoon] = .cluster
        let saved = model.garden
        #expect(SucculentSpecies.allCases.filter { $0.morphology == .crassulaceaeType }.count == 33)
        #expect(SucculentMorphology.allCases.map(\.title) == ["景天科型", "万年草型", "玉坠型", "观音莲型", "肉锥型", "十二卷型", "仙人掌型", "钱串型", "不死鸟型"])
        model.shopMorphology = .stonecropType
        #expect(model.shopSpecies == [.goldenStonecrop, .snowStonecrop, .jixingMeiren, .blueChalk, .ballPine])
        model.shopStages[.goldenStonecrop] = .grassOverflow
        #expect(model.shopStage(for: .goldenStonecrop) == .grassOverflow)
        #expect(model.shopStage(for: .snowStonecrop) == .grassCluster)
        model.shopMorphology = .yuzhuiType
        #expect(model.shopSpecies == [.yuzhui, .fireFestival, .gollumJade])
        model.shopMorphology = .crassulaceaeType
        #expect(model.shopSpecies.count == 33)
        #expect(!model.shopSpecies.contains(.goldenStonecrop))
        model.search = "白月影"
        #expect(model.shopSpecies == [.whiteMoon])
        model.shopMorphology = nil
        #expect(model.shopSpecies == [.whiteMoon])
        model.search = "没有这个品种"
        #expect(model.shopSpecies.isEmpty)
        #expect(model.shopStage(for: .whiteMoon) == .cluster)
        #expect(model.garden == saved && model.selectedSlot == 2)
        model.openShop()
        #expect(model.shopMorphology == nil && model.shopSpecies == SucculentSpecies.allCases)
    }

    @Test
    func linksSelectEveryPotOnFirstOpenAndWhileRunning() {
        let model = GardenModel()
        for slot in 0..<3 {
            model.section = .shop
            model.search = "不存在的品种"
            model.collectionMorphology = .stonecropType
            model.handle(GardenRoute.url(for: slot))
            #expect(model.selectedSlot == slot)
            #expect(model.section == .collection && model.search.isEmpty)
            #expect(model.collectionMorphology == nil)
        }
        #expect(model.garden == nil)
    }

    @Test
    func invalidLinksDoNotChangeTheCurrentSelection() throws {
        let model = GardenModel()
        model.openSlot(1)
        model.search = "黄丽"
        for value in ["https://garden?slot=0", "littlecomponent://other?slot=0",
                      "littlecomponent://garden", "littlecomponent://garden?slot=-1",
                      "littlecomponent://garden?slot=3", "littlecomponent://garden?slot=abc"] {
            model.handle(try #require(URL(string: value)))
            #expect(model.selectedSlot == 1 && model.section == .collection)
            #expect(model.search == "黄丽")
        }
    }
}
