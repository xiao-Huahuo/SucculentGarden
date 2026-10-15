// 年龄通过增叶增枝体现；同品种素材的单叶绘画尺度应在预览中保持一致。
import Foundation
import Testing

struct WoodyPlantLeafScaleTests {
    @Test
    func agingAddsLeavesInsteadOfMagnifyingTheWholeDrawing() {
        let frame = CGSize(width: 156, height: 140)
        let unit = SucculentArtworkSize.previewPointsPerCentimeter(in: frame)
        for kind in [SucculentSpecies.elephantBush, .elephantBushRainbow, .jadeTree, .spiralGrass] {
            var reference: CGFloat?
            for phase in kind.stages {
                let name = kind.assetName(stage: phase)
                let layout = SucculentArtworkLayout.assets[name]!
                let cm = SucculentArtworkSize.centimeters(species: kind, stage: phase, isLeaf: false)
                let placement = layout.placement(in: frame, planted: false,
                    maximumSize: CGSize(width: cm.width * unit, height: cm.height * unit))
                let visibleLeafLength = placement.scale * (layout.referenceLeafLength ?? 1)
                if let reference {
                    #expect(abs(visibleLeafLength / reference - 1) < 0.05,
                            "\(kind.title)\(kind.stageTitle(for: phase))不应放大单片叶")
                } else { reference = visibleLeafLength }
            }
        }
    }

    @Test
    func rootsRemainWithinTheMeasuredTerracottaSoilOpening() {
        for kind in SucculentSpecies.allCases {
            for phase in kind.stages {
                let layout = SucculentArtworkLayout.assets[kind.assetName(stage: phase)]!
                guard let left = layout.rootMinX, let right = layout.rootMaxX else { continue }
                let frame = CGSize(width: 78, height: 93)
                let cm = SucculentArtworkSize.centimeters(species: kind, stage: phase, isLeaf: false)
                let unit = SucculentArtworkSize.plantedPointsPerCentimeter(artSize: 78)
                let placement = layout.placement(in: frame, planted: true,
                    maximumSize: CGSize(width: cm.width * unit, height: cm.height * unit))
                #expect((right - left) * placement.scale <= 26.001)
                #expect(abs((left + right) / 2 * placement.scale + placement.offset.width - frame.width / 2) < 0.001)
            }
        }
    }
}
