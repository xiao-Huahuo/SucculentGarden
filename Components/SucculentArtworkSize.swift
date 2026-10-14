// 用4cm小盆比较植株大小；数值是游戏所选盆栽的尺度，不是物种的最大尺寸。
import Foundation

enum SucculentArtworkSize {
    static let potDiameter: CGFloat = 4
    static let previewSpan: CGFloat = 8

    static func centimeters(species: SucculentSpecies, stage: SucculentStage, isLeaf: Bool) -> CGSize {
        if SucculentExpansionCatalog.entries[species] != nil {
            return SucculentExpansionSize.centimeters(species: species, stage: stage, isMaterial: isLeaf)
        }
        if species == .guanyin {
            let sizes: [CGSize] = [(1.2, 1.7), (2.5, 2.3), (4.0, 3.4), (6.0, 4.2), (6.0, 4.8)].map(CGSize.init)
            return sizes[isLeaf ? 0 : species.stages.firstIndex(of: stage)!]
        }
        if species == .lithops {
            // 库存仅作小幅放大便于辨认；盆中是微小颗粒，不与小苗同尺寸。
            if isLeaf { return CGSize(width: 0.2, height: 0.2) }
            let sizes: [CGSize] = [(0.05, 0.05), (0.6, 0.7), (1.3, 1.3), (2.5, 2.3), (3.0, 2.5)].map(CGSize.init)
            return sizes[isLeaf ? 0 : species.stages.firstIndex(of: stage)!]
        }
        if species.morphology != .crassulaceaeType {
            if species == .yuzhui {
                if isLeaf { return CGSize(width: 1.5, height: 1.5) }
                if stage == .sprout { return CGSize(width: 1.8, height: 1.5) }
            }
            let sizes: [CGSize]
            switch species {
            case .goldenStonecrop:
                sizes = [(1.2, 2.0), (1.2, 1.6), (2.6, 2.2), (4.4, 3.3), (6.4, 4.8)].map(CGSize.init)
            case .snowStonecrop:
                sizes = [(1.2, 2.5), (1.2, 2.3), (2.8, 2.5), (4.5, 3.1), (6.4, 5.2)].map(CGSize.init)
            case .jixingMeiren:
                sizes = [(1.1, 2.5), (1.1, 2.4), (2.7, 2.4), (4.5, 3.1), (6.0, 4.7)].map(CGSize.init)
            default: // 玉坠的肉叶与叶串比三种小型地被草大。
                sizes = [(1.8, 4.5), (1.8, 4.6), (3.8, 4.2), (5.0, 4.5), (6.8, 6.0)].map(CGSize.init)
            }
            return sizes[isLeaf ? 0 : SucculentStage.stonecropStages.firstIndex(of: stage)! + 1]
        }
        if isLeaf {
            let length: CGFloat
            switch species {
            case .huangli: length = 2.0
            case .taodan, .whiteMoon: length = 2.2
            case .chihuahua, .orangeMonroe: length = 2.5
            case .blueBird: length = 2.8
            case .ruby: length = 1.6
            default: length = 1.8
            }
            return CGSize(width: length, height: length)
        }
        switch stage {
        case .sprout: return CGSize(width: 1.8, height: 1.8)
        case .juvenile: return CGSize(width: 2.8, height: 3.2)
        case .adult: return CGSize(width: 4, height: 4.8)
        case .prime: return CGSize(width: 6, height: 6.5)
        case .oldStem: return CGSize(width: 6.2, height: 7)
        case .cluster: return CGSize(width: 6.8, height: 7)
        default: return CGSize(width: 6.2, height: 7)
        }
    }

    static func previewPointsPerCentimeter(in size: CGSize) -> CGFloat {
        min(size.width, size.height) / previewSpan
    }

    static func plantedPointsPerCentimeter(artSize: CGFloat) -> CGFloat {
        let pot = SucculentArtworkLayout.assets["SucculentPot"]!
        let placement = pot.placement(in: CGSize(width: artSize * 0.65, height: 32), planted: false)
        return pot.bounds.width * placement.scale / potDiameter
    }
}
