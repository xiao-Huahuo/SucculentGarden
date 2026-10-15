// 用户指出的成年尺度与长指叶形态回归；实际叶型另用原生阶段对照图检查。
import Foundation
import Testing

struct Artwork44RegressionTests {
    @Test
    func adultZebraHasTheSameFourCentimeterSpreadAsAdultRosettes() {
        let size = SucculentArtworkSize.centimeters(species: .zebraHaworthia, stage: .offsetAdult, isLeaf: false)
        #expect(size.width >= 4 && size.height >= 4.8)
    }

    @Test
    func buddhaKeepsLongOutwardFingersInsteadOfNarrowHangingChains() {
        for stage in [SucculentStage.adult, .prime, .oldStem, .cluster] {
            let layout = SucculentArtworkLayout.assets[SucculentSpecies.thousandBuddha.assetName(stage: stage)]!
            #expect(layout.bounds.width / layout.bounds.height >= 0.6)
            #expect((layout.plantingAnchorY ?? layout.bounds.maxY) == layout.bounds.maxY)
        }
    }
}
