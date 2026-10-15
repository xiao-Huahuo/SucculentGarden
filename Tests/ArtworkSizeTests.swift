// 实际素材轮廓的尺度回归：小草不撑满槽位，4/6cm株径与盆径保持一致。
import Foundation
import Testing

struct ArtworkSizeTests {
    @Test
    func layeredBuddhaGrowsUpwardAtModerateIntervalsAndKeepsItsBaseOnSoil() {
        var previousHeight: CGFloat = 0
        for stage in [SucculentStage.adult, .prime, .oldStem, .cluster] {
            let layout = SucculentArtworkLayout.assets[SucculentSpecies.thousandBuddha.assetName(stage: stage)]!
            let frame = CGSize(width: 78, height: 93)
            let position = layout.placement(in: frame, planted: true)
            let anchor = layout.plantingAnchorY ?? layout.bounds.maxY
            #expect(abs(anchor * position.scale + position.offset.height - 70) < 0.001)
            let size = SucculentArtworkSize.centimeters(species: .thousandBuddha, stage: stage, isLeaf: false)
            #expect(size.height > previousHeight && size.height <= 6.4 && size.width >= 4)
            previousHeight = size.height
        }
    }

    @Test
    func miniatureShootsAreAboutOneThirdOfPreviousWidgetSizeAndStayRooted() {
        for species in [SucculentSpecies.goldenStonecrop, .snowStonecrop, .jixingMeiren] {
            let layout = SucculentArtworkLayout.assets[species.assetName(stage: .grassSprout)]!
            let unit = SucculentArtworkSize.plantedPointsPerCentimeter(artSize: 78)
            // 旧参考株冠约为盆口九成；换俯视陶盆后仍按盆径比较，避免把相机缩放当植株变小。
            let previous = layout.placement(in: CGSize(width: unit * SucculentArtworkSize.potDiameter * 0.9, height: 93), planted: true)
            let size = SucculentArtworkSize.centimeters(species: species, stage: .grassSprout, isLeaf: false)
            let placement = layout.placement(in: CGSize(width: 78, height: 93), planted: true,
                                             maximumSize: CGSize(width: size.width * unit, height: size.height * unit))
            #expect((0.28...0.38).contains(placement.scale / previous.scale))
            #expect(layout.bounds.width * placement.scale <= 13)
            #expect(layout.bounds.height * placement.scale <= 26)
            #expect(abs(layout.bounds.maxY * placement.scale + placement.offset.height - 70) < 0.001)
        }
    }

    @Test
    func fourAndSixCentimeterRosettesKeepTheirDiameterRelativeToTheSamePot() {
        for species in [SucculentSpecies.huangli, .taodan, .chihuahua, .orangeMonroe, .blueBird, .ruby, .jilongyue, .babyFinger, .whiteMoon] {
            for artSize: CGFloat in [78, 82, 96] {
                let unit = SucculentArtworkSize.plantedPointsPerCentimeter(artSize: artSize)
                var widths: [CGFloat] = []
                for stage in [SucculentStage.adult, .prime] {
                    let layout = SucculentArtworkLayout.assets[species.assetName(stage: stage)]!
                    let size = SucculentArtworkSize.centimeters(species: species, stage: stage, isLeaf: false)
                    let position = layout.placement(in: CGSize(width: artSize, height: artSize + 15), planted: true,
                                                     maximumSize: CGSize(width: size.width * unit, height: size.height * unit))
                    let diameter = layout.bounds.width * position.scale / unit
                    #expect(abs(diameter - (stage == .adult ? 4 : 6)) < 0.001)
                    widths.append(layout.bounds.width * position.scale)
                }
                #expect(abs(widths[1] / widths[0] - 1.5) < 0.001)
            }
        }
    }

    @Test
    func allStagesFitTheSceneAndRootFootprintWhileGrowthRemainsVisible() {
        for species in SucculentSpecies.allCases {
            for artSize: CGFloat in [78, 82, 96] {
                let unit = SucculentArtworkSize.plantedPointsPerCentimeter(artSize: artSize)
                let frame = CGSize(width: artSize, height: artSize + 15)
                var previousArea: CGFloat = 0
                for stage in species.stages {
                    let layout = SucculentArtworkLayout.assets[species.assetName(stage: stage)]!
                    let cm = SucculentArtworkSize.centimeters(species: species, stage: stage, isLeaf: false)
                    let position = layout.placement(in: frame, planted: true,
                                                     maximumSize: CGSize(width: cm.width * unit, height: cm.height * unit))
                    let visible = CGRect(x: layout.bounds.minX * position.scale + position.offset.width,
                                         y: layout.bounds.minY * position.scale + position.offset.height,
                                         width: layout.bounds.width * position.scale,
                                         height: layout.bounds.height * position.scale)
                    #expect(visible.minX >= -0.001 && visible.minY >= -0.001)
                    #expect(visible.maxX <= frame.width + 0.001 && visible.maxY <= frame.height + 0.001)
                    let anchor = layout.plantingAnchorY ?? layout.bounds.maxY
                    #expect(abs(anchor * position.scale + position.offset.height - (frame.height - 23)) < 0.001)
                    if let left = layout.rootMinX, let right = layout.rootMaxX {
                        #expect((right - left) * position.scale <= 26.001)
                    }
                    // 用户指定单头老桩，轮廓可更紧凑；不以叶冠外接面积代表成长。
                    if ![.oldStem, .motherOldStem, species.matureStage].contains(stage) {
                        #expect(visible.width * visible.height > previousArea, "\(species.title)：\(species.stageTitle(for: stage))，画幅\(artSize)")
                    }
                    previousArea = visible.width * visible.height
                }
            }
        }
    }

    @Test
    func previewMaterialsUseTheSameScaleAndYuzhuiKeepsItsLargerLeaves() {
        for frame in [CGSize(width: 156, height: 140), CGSize(width: 118, height: 112), CGSize(width: 90, height: 60)] {
            let unit = SucculentArtworkSize.previewPointsPerCentimeter(in: frame)
            for species in SucculentSpecies.allCases {
                let layout = SucculentArtworkLayout.assets[species.assetName(stage: species.initialStage, isLeaf: true)]!
                let cm = SucculentArtworkSize.centimeters(species: species, stage: species.initialStage, isLeaf: true)
                let position = layout.placement(in: frame, planted: false,
                                                 maximumSize: CGSize(width: cm.width * unit, height: cm.height * unit))
                #expect(layout.bounds.width * position.scale <= cm.width * unit + 0.001)
                #expect(layout.bounds.height * position.scale <= cm.height * unit + 0.001)
            }
        }
        let small = SucculentArtworkSize.centimeters(species: .jixingMeiren, stage: .grassSprout, isLeaf: false)
        let large = SucculentArtworkSize.centimeters(species: .yuzhui, stage: .grassSprout, isLeaf: false)
        #expect(large.width > small.width && large.height > small.height)
    }
}
