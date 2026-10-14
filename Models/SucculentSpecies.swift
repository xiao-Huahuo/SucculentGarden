// 持久化使用稳定品种 ID；旧版无品种字段的数据只在迁移时归为黄丽。
import Foundation

enum SucculentSpecies: String, Codable, CaseIterable, Identifiable, Sendable {
    case huangli, taodan, chihuahua, orangeMonroe
    case blueBird, ruby, jilongyue, babyFinger, whiteMoon
    case goldenStonecrop, snowStonecrop, jixingMeiren, yuzhui
    case guanyin, lithops
    case qiuli, tiya, blueStoneLotus, blueJilian, otome, jellyBean
    case thousandBuddha, mingyue, orion, markus, ellen, laul
    case iceJade, chocolateBrick, peachPride, ebony, blueElf, waterPeach
    case onslow, blueApple, paleSnow, blueChalk, ballPine, fireFestival
    case gollumJade, mountainRose, cobwebHouseleek, maughanii, splitRock, grassJade
    case iceLantern, blackSkinJade, redLineJade, blueMirrorJade, whiteLotusJade, goldenJade
    case sakuraCrystal, zebraHaworthia, jadeFan, crystalRetusa, moonRetusa, fortuneHand
    case smallCactusBall, fairyCastle, goldFinger, whiteBird, nineTailFox, moneyStack
    case deerAntler, bearPaw, broadMother, tubeMother, narrowMother
    case cheese, topsyTurvy, tangyuan
    case fenestraria

    var id: String { rawValue }
    var morphology: SucculentMorphology {
        switch self {
        case .goldenStonecrop, .snowStonecrop, .jixingMeiren: .stonecropType
        case .yuzhui: .yuzhuiType
        case .guanyin: .guanyinType
        case .lithops: .conophytumType
        default: SucculentExpansionCatalog.entries[self]?.morphology ?? .crassulaceaeType
        }
    }
    var stages: [SucculentStage] { morphology.stages }
    var initialStage: SucculentStage { stages[0] }
    var matureStage: SucculentStage { stages[stages.count - 1] }
    var usesStemCutting: Bool { morphology == .stonecropType || morphology == .moneyStackType }
    var propagationTitle: String {
        switch morphology {
        case .guanyinType, .haworthiaType: "小苗"
        case .conophytumType: "种子"
        case .cactusType: "芽块"
        case .motherOfThousandsType: "小芽"
        default: usesStemCutting ? "枝条" : "叶片"
        }
    }
    var propagationQuantity: String { propagationQuantity(count: 1) }

    func propagationQuantity(count: Int) -> String {
        switch morphology {
        case .guanyinType, .haworthiaType: "\(count)株"
        case .conophytumType: "\(count)粒"
        case .cactusType: "\(count)块"
        case .motherOfThousandsType: "\(count)芽"
        default: usesStemCutting ? "\(count)枝" : "\(count)片"
        }
    }

    func startSeconds(for stage: SucculentStage) -> TimeInterval {
        if morphology == .yuzhuiType {
            return [0.0, 1, 2, 5, 10][stages.firstIndex(of: stage)!] * 86_400
        }
        return stage.startSeconds
    }

    func purchasePrice(for stage: SucculentStage) -> Int? {
        morphology == .yuzhuiType && stage == .grassSprout ? 0 : stage.purchasePrice
    }

    func disassemblyCount(for stage: SucculentStage) -> Int? {
        switch morphology {
        case .crassulaceaeType:
            switch stage {
            case .juvenile: 3
            case .adult: 5
            case .prime: 8
            case .oldStem: 12
            case .cluster: 15
            default: nil
            }
        case .stonecropType:
            switch stage {
            case .grassCluster: 5
            case .grassClump: 10
            case .grassOverflow: 15
            default: nil
            }
        case .guanyinType:
            switch stage {
            case .offsetCluster: 3
            case .offsetOldStem: 5
            default: nil
            }
        case .haworthiaType:
            [.jadeFan, .zebraHaworthia].contains(self) && stage == .offsetOldStem ? 5 : nil
        case .cactusType:
            switch stage {
            case .cactusYoung: 3
            case .cactusAdult: 5
            case .cactusCluster: 8
            case .cactusOverflow: 12
            default: nil
            }
        case .moneyStackType:
            switch stage {
            case .moneyYoung: 5
            case .moneyAdult: 10
            case .moneyOldStem: 15
            case .moneyMultipleHeads: 20
            default: nil
            }
        case .motherOfThousandsType: harvestCount(for: stage)
        case .conophytumType: nil
        case .yuzhuiType:
            switch stage {
            case .grassSprout: 3
            case .grassCluster: 5
            case .grassClump: 8
            case .grassOverflow: 12
            default: nil
            }
        }
    }
    func harvestCount(for stage: SucculentStage) -> Int? {
        guard morphology == .motherOfThousandsType else { return nil }
        switch stage {
        case .motherAdult: return 10
        case .motherPrime: return 20
        case .motherOldStem: return 35
        case .motherCluster: return 50
        default: return nil
        }
    }

    func stageTitle(for stage: SucculentStage) -> String {
        guard SucculentExpansionCatalog.entries[self] != nil else { return stage.title }
        if morphology == .haworthiaType && stage == .offsetCluster { return "壮年" }
        switch stage {
        case .adult: return "成年"
        case .prime: return "壮年"
        case .grassSprout: return "小苗"
        case .grassClump: return "丛生"
        default: return stage.title
        }
    }

    var title: String {
        switch self {
        case .huangli: "黄丽"
        case .taodan: "桃蛋"
        case .chihuahua: "吉娃娃"
        case .orangeMonroe: "橙梦露"
        case .blueBird: "蓝鸟"
        case .ruby: "红宝石"
        case .jilongyue: "姬胧月"
        case .babyFinger: "婴儿手指"
        case .whiteMoon: "白月影"
        case .goldenStonecrop: "黄金万年草"
        case .snowStonecrop: "薄雪万年草"
        case .jixingMeiren: "姬星美人"
        case .yuzhui: "玉坠"
        case .guanyin: "观音莲"
        case .lithops: "生石花"
        default: SucculentExpansionCatalog.entries[self]!.title
        }
    }

    var assetPrefix: String {
        switch self {
        case .huangli: "Huangli"
        case .taodan: "Taodan"
        case .chihuahua: "Chihuahua"
        case .orangeMonroe: "OrangeMonroe"
        case .blueBird: "BlueBird"
        case .ruby: "Ruby"
        case .jilongyue: "Jilongyue"
        case .babyFinger: "BabyFinger"
        case .whiteMoon: "WhiteMoon"
        case .goldenStonecrop: "GoldenStonecrop"
        case .snowStonecrop: "SnowStonecrop"
        case .jixingMeiren: "JixingMeiren"
        case .yuzhui: "Yuzhui"
        case .guanyin: "Guanyin"
        case .lithops: "Lithops"
        default: rawValue.prefix(1).uppercased() + rawValue.dropFirst()
        }
    }

    func assetName(stage: SucculentStage, isLeaf: Bool = false) -> String {
        if SucculentExpansionCatalog.entries[self] != nil {
            if isLeaf {
                switch morphology {
                case .guanyinType, .haworthiaType, .conophytumType, .cactusType: return assetPrefix + "Stage0"
                case .motherOfThousandsType: return assetPrefix + "Bud"
                default: return assetPrefix + (usesStemCutting ? "Cutting" : "Leaf")
                }
            }
            return assetPrefix + "Stage\(stages.firstIndex(of: stage)!)"
        }
        if self == .guanyin || self == .lithops {
            let index = isLeaf ? 0 : stages.firstIndex(of: stage)!
            return assetPrefix + "Stage\(index)"
        }
        if isLeaf { return assetPrefix + (usesStemCutting ? "Cutting" : "Leaf") }
        if self == .yuzhui && stage == .sprout { return "YuzhuiSprout" }
        return assetPrefix + "Stage\(stage.rawValue - (stage.rawValue >= 6 ? 6 : 0))"
    }

    static let legacyDecodingKey = CodingUserInfoKey(rawValue: "legacySucculentSpecies")!

    static func decode<Key: CodingKey>(from container: KeyedDecodingContainer<Key>,
                                      key: Key, decoder: Decoder) throws -> Self {
        if !container.contains(key), decoder.userInfo[legacyDecodingKey] as? Bool == true {
            return .huangli
        }
        return try container.decode(Self.self, forKey: key)
    }
}

enum SucculentMorphology: String, CaseIterable, Identifiable, Sendable {
    case crassulaceaeType, stonecropType, yuzhuiType, guanyinType, conophytumType
    case haworthiaType, cactusType, moneyStackType, motherOfThousandsType
    var stages: [SucculentStage] {
        switch self {
        case .crassulaceaeType: SucculentStage.rosetteStages
        case .stonecropType: SucculentStage.stonecropStages
        case .yuzhuiType: [.sprout] + SucculentStage.stonecropStages
        case .guanyinType: SucculentStage.guanyinStages
        case .conophytumType: SucculentStage.lithopsStages
        case .haworthiaType: SucculentStage.guanyinStages
        case .cactusType: SucculentStage.cactusStages
        case .moneyStackType: SucculentStage.moneyStages
        case .motherOfThousandsType: SucculentStage.motherStages
        }
    }
    var id: String { rawValue }
    var title: String {
        switch self {
        case .crassulaceaeType: "景天科型"
        case .stonecropType: "万年草型"
        case .yuzhuiType: "玉坠型"
        case .guanyinType: "观音莲型"
        case .conophytumType: "肉锥型"
        case .haworthiaType: "十二卷型"
        case .cactusType: "仙人掌型"
        case .moneyStackType: "钱串型"
        case .motherOfThousandsType: "不死鸟型"
        }
    }

    var representativeSpecies: SucculentSpecies {
        switch self {
        case .crassulaceaeType: .huangli
        case .stonecropType: .goldenStonecrop
        case .yuzhuiType: .yuzhui
        case .guanyinType: .guanyin
        case .conophytumType: .lithops
        case .haworthiaType: .iceLantern
        case .cactusType: .smallCactusBall
        case .moneyStackType: .moneyStack
        case .motherOfThousandsType: .broadMother
        }
    }
}
