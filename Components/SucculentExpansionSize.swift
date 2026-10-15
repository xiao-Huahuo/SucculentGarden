// 新品种沿用4cm盆栽比较基准，按直立/垂枝/莲座形态设置画面尺度；不是物种最大尺寸。
import Foundation

enum SucculentExpansionSize {
    static func centimeters(species: SucculentSpecies, stage: SucculentStage, isMaterial: Bool) -> CGSize {
        let type = species.morphology
        // 图集标注代表叶长；不同阶段的绘画DPI不同，按同一叶长显示以增叶体现成长。
        if !isMaterial, [.elephantBush, .elephantBushRainbow, .jadeTree, .spiralGrass].contains(species),
           let layout = SucculentArtworkLayout.assets[species.assetName(stage: stage)],
           let reference = layout.referenceLeafLength {
            let leafCentimeters: CGFloat = species == .spiralGrass ? 6 : species == .jadeTree ? 0.55 : 0.3
            let scale = leafCentimeters / reference
            return CGSize(width: layout.bounds.width * scale, height: layout.bounds.height * scale)
        }
        if species == .fenestraria {
            // 叶片约3cm高；随成长增加叶量与丛宽，不套用大型莲座的高度。
            let sizes: [(CGFloat, CGFloat)] = [(0.9, 0.9), (1.8, 1.6), (2.8, 2.5), (4, 3), (4.8, 3.2)]
            let size = sizes[isMaterial ? 0 : species.stages.firstIndex(of: stage)!]
            return CGSize(width: size.0, height: size.1)
        }
        if species == .zebraHaworthia {
            let sizes: [(CGFloat, CGFloat)] = [(0.6, 0.9), (1.3, 1.8), (4, 5.2), (6, 6.5), (6.2, 7)]
            let size = sizes[isMaterial ? 0 : species.stages.firstIndex(of: stage)!]
            return CGSize(width: size.0, height: size.1)
        }
        if species == .thousandBuddha && !isMaterial {
            // 长指叶保持展开幅度；叶层紧密，靠温和增加茎高表现后续成长。
            let sizes: [(CGFloat, CGFloat)] = [(1.5, 1.5), (2.2, 3), (4.2, 4.8), (4.5, 5.4), (4.8, 6.2), (6.4, 6.4)]
            let size = sizes[species.stages.firstIndex(of: stage)!]
            return CGSize(width: size.0, height: size.1)
        }
        if species == .bunnyMonilaria {
            if isMaterial { return CGSize(width: 0.2, height: 0.2) }
            let sizes: [(CGFloat, CGFloat)] = [(0.05, 0.05), (0.6, 1), (0.8, 2), (2.6, 3.6), (4.2, 4.5)]
            let size = sizes[species.stages.firstIndex(of: stage)!]
            return CGSize(width: size.0, height: size.1)
        }
        if [.anacampseros, .anacampserosRainbow, .needleStonecrop].contains(species) {
            if isMaterial {
                return species == .needleStonecrop ? CGSize(width: 1, height: 2) : CGSize(width: 0.8, height: 0.8)
            }
            let sizes: [(CGFloat, CGFloat)] = species == .needleStonecrop
                ? [(0.9, 1.2), (2.4, 2.1), (4, 2.8), (6, 3.4)]
                : [(1, 1), (1.8, 2), (2.8, 3.2), (4.4, 4.2), (4.8, 5), (6, 5.4)]
            let size = sizes[species.stages.firstIndex(of: stage)!]
            return CGSize(width: size.0, height: size.1)
        }
        if isMaterial {
            switch type {
            case .conophytumType: return CGSize(width: 0.2, height: 0.2)
            case .guanyinType, .haworthiaType: return CGSize(width: 1.2, height: 1.5)
            case .cactusType: return CGSize(width: 1.2, height: 1.6)
            case .stonecropType, .moneyStackType: return CGSize(width: 1.4, height: 2.6)
            case .motherOfThousandsType: return CGSize(width: 0.7, height: 1.0)
            default: return CGSize(width: 1.8, height: 1.8)
            }
        }
        // 蓝姬莲群生轮廓较扁宽，株径略增才能让多头比壮年单头更饱满。
        if species == .blueJilian && stage == .cluster { return CGSize(width: 7.2, height: 7) }
        let values: [(CGFloat, CGFloat)]
        switch type {
        case .crassulaceaeType:
            if [.otome, .jellyBean, .thousandBuddha, .mingyue, .blueElf, .laul].contains(species) {
                values = [(1.5, 1.5), (2.2, 3), (3.4, 4.6), (4.6, 6), (5.8, 7), (6, 6.6)]
            } else {
                values = [(1.8, 1.8), (2.8, 3.2), (4, 4.8), (6, 6.5), (6.2, 7), (6.8, 7)]
            }
        case .stonecropType:
            values = species == .blueChalk ? [(1.5, 2.2), (3.2, 3.6), (4.8, 5), (6.5, 6.2)] : [(1.4, 1.8), (3, 2.8), (4.6, 4), (6.2, 5.2)]
        case .yuzhuiType:
            values = [(1.5, 1.5), (1.8, 2.5), (3.4, 4.4), (4.8, 5.8), (6.4, 7)]
        case .guanyinType, .haworthiaType:
            values = [(1.2, 1.5), (2.5, 2.4), (4, 3.5), (6, 4.5), (6.2, 4.8)]
        case .conophytumType:
            values = [(0.05, 0.05), (0.6, 0.7), (1.3, 1.3), (2.5, 2.3), (3, 2.5)]
        case .cactusType:
            values = species == .nineTailFox ? [(1.2, 1.8), (1.5, 2.8), (2.8, 4.2), (4.4, 5.2), (6.2, 6.6)] : [(1.2, 1.6), (2, 2.6), (3.5, 4.5), (5, 5.8), (6.4, 7)]
        case .moneyStackType:
            values = [(1.4, 2), (3.2, 3.8), (4.8, 5.2), (5.4, 6), (6.4, 6.4)]
        case .motherOfThousandsType:
            values = [(0.8, 1.2), (1.8, 2.7), (3.2, 4.6), (4.6, 6.2), (5.8, 7), (6, 6.6)]
        }
        let value = values[species.stages.firstIndex(of: stage)!]
        return CGSize(width: value.0, height: value.1)
    }
}
