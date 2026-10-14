// x/y 乘在等待时间上；只保存用户覆盖值，默认值依据园艺资料估计，不等于固定自然年限。
import Foundation

struct GardenGrowthMultipliers: Codable, Equatable, Sendable {
    var morphology: [String: Double] = [:]
    var species: [String: Double] = [:]
    static let allowedRange = 0.05...100.0

    func x(for type: SucculentMorphology) -> Double {
        morphology[type.rawValue] ?? type.defaultTimeMultiplier
    }

    func y(for plant: SucculentSpecies) -> Double {
        species[plant.rawValue] ?? plant.defaultTimeMultiplier
    }

    func validate() throws {
        guard morphology.allSatisfy({ SucculentMorphology(rawValue: $0.key) != nil && Self.allowedRange.contains($0.value) && $0.value.isFinite }),
              species.allSatisfy({ SucculentSpecies(rawValue: $0.key) != nil && Self.allowedRange.contains($0.value) && $0.value.isFinite }) else {
            throw GardenError.invalidMultiplier
        }
    }
}

extension SucculentMorphology {
    var defaultTimeMultiplier: Double {
        switch self {
        case .crassulaceaeType: 1
        case .stonecropType: 0.5
        case .yuzhuiType, .guanyinType: 0.75
        case .conophytumType: 2
        case .haworthiaType: 1.5
        case .cactusType: 1.25
        case .moneyStackType: 0.75
        case .motherOfThousandsType: 0.5
        }
    }
}

extension SucculentSpecies {
    var defaultTimeMultiplier: Double {
        if let entry = SucculentExpansionCatalog.entries[self] { return entry.timeMultiplier }
        switch self {
        // NC State 将拟石莲花属列为慢生；这些园艺品种缺少一致的逐期天数，采用保守相对估计。
        case .chihuahua, .orangeMonroe, .blueBird, .whiteMoon: return 1.25
        // SANBI 记录生石花播种苗接近一年才适合移栽，时间倍率显著高于常规多肉。
        case .lithops: return 3
        // 黄丽为1.00基准；中速或没有足够品种对比资料的植物先使用基准值。
        default: return 1
        }
    }
}
