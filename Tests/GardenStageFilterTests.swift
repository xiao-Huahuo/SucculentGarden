// 全局时期按每个形态的阶段序号映射；收藏按实际成长筛选，不写真实存档。
import Foundation
import Testing

@MainActor
struct GardenStageFilterTests {
    @Test
    func genericSixthStageHidesShorterSpeciesAndTypedMenusHaveTheRightNames() {
        let model = GardenModel()
        #expect(model.stageTitles(for: .shop) == ["1", "2", "3", "4", "5", "6"])
        model.shopStageIndex = 5
        #expect(model.shopSpecies.count == 33)
        #expect(model.shopSpecies.allSatisfy { $0.stages.count == 6 && model.shopStage(for: $0) == $0.stages[5] })
        model.shopMorphology = .moneyStackType
        #expect(model.shopStageIndex == nil)
        #expect(model.stageTitles(for: .shop) == ["小苗", "幼年", "成年", "老桩", "多头"])
        model.shopStageIndex = 4
        #expect(model.shopSpecies == [.moneyStack, .deerAntler, .bearPaw])
        #expect(model.shopSpecies.allSatisfy { model.shopStage(for: $0) == .moneyMultipleHeads })
        model.shopMorphology = .stonecropType
        #expect(model.shopStageIndex == nil && model.stageTitles(for: .shop).count == 4)
        model.shopMorphology = .haworthiaType
        #expect(model.stageTitles(for: .shop) == ["小苗", "幼年", "成年", "壮年", "老桩"])
        model.shopMorphology = nil
        #expect(model.stageTitles(for: .shop) == ["1", "2", "3", "4", "5", "6"])
    }

    @Test
    func individualChoiceKeepsOtherGloballySelectedCardsAndNavigationClearsTheFilter() {
        let model = GardenModel()
        model.shopStageIndex = 3
        model.selectShopStage(.juvenile, for: .huangli)
        #expect(model.shopStageIndex == nil && model.shopStage(for: .huangli) == .juvenile)
        for species in SucculentSpecies.allCases where species != .huangli {
            #expect(model.shopStage(for: species) == species.stages[3])
        }
        model.shopStageIndex = 5
        model.openShop(stage: .sprout)
        #expect(model.shopStageIndex == nil && model.shopStages.isEmpty)
        #expect(model.shopSpecies.allSatisfy { model.shopStage(for: $0) == $0.initialStage })
        model.collectionStageIndex = 5
        model.openSlot(2)
        #expect(model.collectionStageIndex == nil && model.selectedSlot == 2)
    }

    @Test
    func collectionFiltersActualCurrentStagesTogetherWithMorphologySearchAndPlacement() {
        let model = GardenModel()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        var garden = SucculentGarden()
        garden.plants = [SucculentSpecies.huangli, .moneyStack, .goldenStonecrop, .broadMother].map {
            SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: $0.startSeconds(for: $0.matureStage),
                           growthUpdatedAt: date, species: $0)
        }
        garden.slots[0] = garden.plants[1].id
        model.collectionStageIndex = 5
        #expect(model.collectionPlants(in: garden, at: date).map(\.species) == [.huangli, .broadMother])
        model.collectionMorphology = .moneyStackType
        #expect(model.collectionStageIndex == nil && model.collectionPlants(in: garden, at: date).isEmpty)
        garden.slots[0] = nil
        model.collectionStageIndex = 4
        #expect(model.collectionPlants(in: garden, at: date).map(\.species) == [.moneyStack])
        model.search = "熊童子"
        #expect(model.collectionPlants(in: garden, at: date).isEmpty)
        model.search = ""
        model.collectionMorphology = nil
        model.collectionStageIndex = nil
        #expect(model.collectionPlants(in: garden, at: date) == garden.plants)
        #expect(model.garden == nil)
    }
}
