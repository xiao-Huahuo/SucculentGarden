// 花园持久化：叶片/枝条沿用leaves字段，与植株分开；品种决定阶段与成长上限。
import Foundation

enum SucculentStage: Int, Codable, CaseIterable, Identifiable, Sendable {
    case sprout, juvenile, adult, prime, oldStem, cluster
    case grassSprout, grassCluster, grassClump, grassOverflow
    case offsetSeedling, offsetJuvenile, offsetAdult, offsetCluster, offsetOldStem
    case lithopsSeed, lithopsSprout, lithopsJuvenile, lithopsAdult, lithopsOldStem
    case cactusBud, cactusYoung, cactusAdult, cactusCluster, cactusOverflow
    case moneySprout, moneyYoung, moneyAdult, moneyOldStem
    case motherSprout, motherYoung, motherAdult, motherPrime, motherOldStem, motherCluster
    case moneyMultipleHeads

    var id: Int { rawValue }
    static let rosetteStages: [Self] = [.sprout, .juvenile, .adult, .prime, .oldStem, .cluster]
    static let stonecropStages: [Self] = [.grassSprout, .grassCluster, .grassClump, .grassOverflow]
    static let guanyinStages: [Self] = [.offsetSeedling, .offsetJuvenile, .offsetAdult, .offsetCluster, .offsetOldStem]
    static let lithopsStages: [Self] = [.lithopsSeed, .lithopsSprout, .lithopsJuvenile, .lithopsAdult, .lithopsOldStem]
    static let cactusStages: [Self] = [.cactusBud, .cactusYoung, .cactusAdult, .cactusCluster, .cactusOverflow]
    static let moneyStages: [Self] = [.moneySprout, .moneyYoung, .moneyAdult, .moneyOldStem, .moneyMultipleHeads]
    static let motherStages: [Self] = [.motherSprout, .motherYoung, .motherAdult, .motherPrime, .motherOldStem, .motherCluster]

    var title: String {
        switch self {
        case .sprout: "叶插小芽"
        case .juvenile, .offsetJuvenile, .lithopsJuvenile, .cactusYoung, .moneyYoung, .motherYoung: "幼年"
        case .adult: "成年（4cm）"
        case .prime: "壮年（6cm）"
        case .oldStem, .offsetOldStem, .lithopsOldStem, .moneyOldStem, .motherOldStem: "老桩"
        case .cluster, .grassCluster, .offsetCluster, .cactusCluster, .motherCluster: "群生"
        case .grassSprout: "小草"
        case .grassClump: "草丛"
        case .grassOverflow, .cactusOverflow: "爆盆"
        case .offsetSeedling, .moneySprout: "小苗"
        case .offsetAdult, .lithopsAdult, .cactusAdult, .moneyAdult, .motherAdult: "成年"
        case .cactusBud: "芽块"
        case .motherSprout: "小芽"
        case .motherPrime: "壮年"
        case .moneyMultipleHeads: "多头"
        case .lithopsSeed: "种子"
        case .lithopsSprout: "萌芽"
        }
    }

    var purchasePrice: Int? {
        switch self {
        case .sprout, .grassSprout, .offsetSeedling, .lithopsSeed, .cactusBud, .moneySprout, .motherSprout: nil
        case .juvenile, .grassCluster, .offsetJuvenile, .lithopsSprout, .cactusYoung, .moneyYoung, .motherYoung: 3
        case .adult, .grassClump, .offsetAdult, .lithopsJuvenile, .cactusAdult, .moneyAdult, .motherAdult: 10
        case .prime, .grassOverflow, .offsetCluster, .lithopsAdult, .cactusCluster, .moneyOldStem, .motherPrime: 20
        case .oldStem, .offsetOldStem, .lithopsOldStem, .cactusOverflow, .moneyMultipleHeads, .motherOldStem: 50
        case .cluster, .motherCluster: 100
        }
    }

    var salePrice: Int {
        switch self {
        case .sprout, .grassSprout, .offsetSeedling, .lithopsSeed, .cactusBud, .cactusYoung, .moneySprout, .motherSprout: 1
        case .juvenile, .grassCluster, .offsetJuvenile, .lithopsSprout, .cactusAdult, .moneyYoung, .motherYoung: 2
        case .adult, .grassClump, .offsetAdult, .lithopsJuvenile, .cactusCluster, .moneyAdult, .motherAdult: 5
        case .prime, .grassOverflow, .offsetCluster, .lithopsAdult, .cactusOverflow, .moneyOldStem, .motherPrime: 10
        case .oldStem, .offsetOldStem, .lithopsOldStem, .moneyMultipleHeads, .motherOldStem: 20
        case .cluster, .motherCluster: 50
        }
    }
    var startSeconds: TimeInterval {
        let days: Double
        if let index = Self.guanyinStages.firstIndex(of: self) { days = [0, 1, 4, 9, 19][index] }
        else if let index = Self.lithopsStages.firstIndex(of: self) { days = [0, 1, 4, 9, 19][index] }
        else if let index = Self.cactusStages.firstIndex(of: self) { days = [0, 1, 2, 5, 10][index] }
        else if let index = Self.moneyStages.firstIndex(of: self) { days = [0, 1, 4, 9, 19][index] }
        else if let index = Self.motherStages.firstIndex(of: self) { days = Self.startDays[index] }
        else { days = rawValue < 6 ? Self.startDays[rawValue] : [0.0, 1, 4, 9][rawValue - 6] }
        return days * 86_400
    }
    static let startDays: [Double] = [0, 1, 4, 9, 19, 39]

    static func at(growthSeconds: TimeInterval, stages: [Self] = rosetteStages) -> Self {
        stages.last { growthSeconds >= $0.startSeconds } ?? stages[0]
    }
}

struct SucculentLeaf: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let claimedAt: Date
    var species: SucculentSpecies = .huangli

    private enum CodingKeys: String, CodingKey { case id, claimedAt, species }
}

// 仅合并展示；每份材料仍保留原ID，拖放只消耗第一份。
struct SucculentLeafStack: Identifiable, Sendable {
    let species: SucculentSpecies
    let firstLeafID: UUID
    var count: Int
    var id: SucculentSpecies { species }
}

struct SucculentPlant: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let acquiredAt: Date
    var growthSeconds: TimeInterval
    var growthUpdatedAt: Date
    var species: SucculentSpecies = .huangli
    var lastHarvestedAt: Date?
    static let harvestCooldown: TimeInterval = 86_400

    func nextHarvestDate() -> Date? { lastHarvestedAt?.addingTimeInterval(Self.harvestCooldown) }

    private enum CodingKeys: String, CodingKey {
        case id, acquiredAt, growthSeconds, growthUpdatedAt, species, lastHarvestedAt
    }

    func age(at date: Date, rate: Double) -> TimeInterval {
        min(species.startSeconds(for: species.matureStage),
            growthSeconds + max(0, date.timeIntervalSince(growthUpdatedAt)) * rate)
    }

    func stage(at date: Date, rate: Double) -> SucculentStage {
        let age = age(at: date, rate: rate)
        return species.stages.last { species.startSeconds(for: $0) <= age } ?? species.initialStage
    }

    func transitionDates(after date: Date, rate: Double) -> [Date] {
        let currentAge = age(at: date, rate: rate)
        return species.stages.compactMap { stage in
            let start = species.startSeconds(for: stage)
            guard start > currentAge else { return nil }
            return date.addingTimeInterval((start - currentAge) / rate)
        }
    }

    mutating func settle(at date: Date, rate: Double) {
        growthSeconds = age(at: date, rate: rate)
        growthUpdatedAt = max(date, growthUpdatedAt)
    }
}

extension SucculentLeaf {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(id: try values.decode(UUID.self, forKey: .id),
                  claimedAt: try values.decode(Date.self, forKey: .claimedAt),
                  species: try SucculentSpecies.decode(from: values, key: .species, decoder: decoder))
    }
}

extension SucculentPlant {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(id: try values.decode(UUID.self, forKey: .id),
                  acquiredAt: try values.decode(Date.self, forKey: .acquiredAt),
                  growthSeconds: try values.decode(TimeInterval.self, forKey: .growthSeconds),
                  growthUpdatedAt: try values.decode(Date.self, forKey: .growthUpdatedAt),
                  species: try SucculentSpecies.decode(from: values, key: .species, decoder: decoder),
                  lastHarvestedAt: try values.decodeIfPresent(Date.self, forKey: .lastHarvestedAt))
    }
}

struct SucculentGarden: Codable, Equatable, Sendable {
    var version = 7
    var money = 10
    var leaves: [SucculentLeaf] = []
    var plants: [SucculentPlant] = []
    var slots: [UUID?] = [nil, nil, nil]
    var growthRate = 1.0
    var growthMultipliers = GardenGrowthMultipliers()

    func effectiveRate(for species: SucculentSpecies) -> Double {
        growthRate / (growthMultipliers.x(for: species.morphology) * growthMultipliers.y(for: species))
    }

    mutating func settleGrowth(at date: Date) {
        for index in plants.indices {
            let rate = effectiveRate(for: plants[index].species)
            plants[index].settle(at: date, rate: rate)
        }
    }
    var claimDate: Date?
    var claimedToday = 0

    var leafStacks: [SucculentLeafStack] {
        var stacks: [SucculentLeafStack] = []
        var indices: [SucculentSpecies: Int] = [:]
        for leaf in leaves {
            if let index = indices[leaf.species] {
                stacks[index].count += 1
            } else {
                indices[leaf.species] = stacks.count
                stacks.append(SucculentLeafStack(species: leaf.species, firstLeafID: leaf.id, count: 1))
            }
        }
        return stacks
    }

    var unplacedPlants: [SucculentPlant] {
        let placed = Set(slots.compactMap { $0 })
        return plants.filter { !placed.contains($0.id) }
    }

    func plant(in slot: Int) -> SucculentPlant? {
        guard slots.indices.contains(slot), let id = slots[slot] else { return nil }
        return plants.first { $0.id == id }
    }

    func remainingClaims(at date: Date, calendar: Calendar = .autoupdatingCurrent) -> Int {
        guard let claimDate, calendar.isDate(claimDate, inSameDayAs: date) else { return 5 }
        return max(0, 5 - claimedToday)
    }

    func validate() throws {
        let plantIDs = Set(plants.map(\.id))
        let placedIDs = slots.compactMap { $0 }
        try growthMultipliers.validate()
        guard (1...7).contains(version), money >= 0, slots.count == 3,
              version == 1 || Set(placedIDs).count == placedIDs.count,
              growthRate.isFinite, (0.25...1_000).contains(growthRate),
              (0...5).contains(claimedToday),
              Set(leaves.map(\.id)).count == leaves.count,
              plantIDs.count == plants.count,
              slots.compactMap({ $0 }).allSatisfy({ plantIDs.contains($0) }),
              plants.allSatisfy({ ($0.lastHarvestedAt == nil || ($0.species.morphology == .motherOfThousandsType && $0.lastHarvestedAt!.timeIntervalSinceReferenceDate.isFinite && $0.lastHarvestedAt! >= $0.acquiredAt)) && $0.growthSeconds.isFinite &&
                  (0...(version < 4 && $0.species == .yuzhui ? 9 * 86_400 : (version < 7 && $0.species.morphology == .moneyStackType ? 9 * 86_400 : $0.species.startSeconds(for: $0.species.matureStage)))).contains($0.growthSeconds) }) else {
            throw GardenError.invalidData
        }
    }

    // 旧版允许重复摆放；升级保留最后一个槽位，植株与成长记录不变。
    mutating func migrateLegacyState(at date: Date = .now) {
        guard version < 7 else { return }
        if version < 5 {
            if version == 1 {
                var seen = Set<UUID>()
                for slot in slots.indices.reversed() {
                    if let id = slots[slot], !seen.insert(id).inserted { slots[slot] = nil }
                }
            }
            // 玉坠旧小草从第0天开始，新增叶插期时整体平移一天。
            if version < 4 {
                for index in plants.indices where plants[index].species == .yuzhui { plants[index].growthSeconds += 86_400 }
            }
            // 引入x/y之前的离线时间仍按旧全局倍率结算。
            for index in plants.indices { plants[index].settle(at: date, rate: growthRate) }
        }
        // 旧钱串到第9天已长成多头；新增老桩不能把已长成的植株退回中间时期。
        for index in plants.indices where plants[index].species.morphology == .moneyStackType {
            let oldMaximum = 9.0 * 86_400
            let rate = effectiveRate(for: plants[index].species)
            let age = min(oldMaximum, plants[index].growthSeconds + max(0, date.timeIntervalSince(plants[index].growthUpdatedAt)) * rate)
            plants[index].growthSeconds = age >= oldMaximum ? age + 10 * 86_400 : age
            plants[index].growthUpdatedAt = max(date, plants[index].growthUpdatedAt)
        }
        version = 7
    }
}

enum GardenError: LocalizedError {
    case invalidData, sharedContainerUnavailable, dailyLimit, leafMissing
    case plantMissing, insufficientFunds, cannotBuyLeafCutting, invalidSlot, invalidRate, invalidStage, cannotDisassemble, invalidMultiplier, cannotHarvest, harvestCoolingDown

    var errorDescription: String? {
        switch self {
        case .invalidData: "保存的花园数据无法读取，原文件已保留。"
        case .sharedContainerUnavailable: "无法访问共享花园，请检查应用签名与共享组权限。"
        case .dailyLimit: "今天的 5 次免费领取已经用完，明天再来。"
        case .leafMissing: "这份繁殖材料已经种植或不在库存中。"
        case .plantMissing: "这株多肉已售出或不在收藏中。"
        case .insufficientFunds: "余额不足。"
        case .cannotBuyLeafCutting: "初始时期需将免费领取的繁殖材料种入花盆。"
        case .invalidSlot: "花盆不存在。"
        case .invalidStage: "该品种没有这个生长时期。"
        case .cannotDisassemble: "这个时期不能拆分繁殖。"
        case .invalidRate: "成长倍率需要在 0.25× 至 1000× 之间。"
        case .invalidMultiplier: "时间乘数需要在 0.05 至 100 之间。"
        case .cannotHarvest: "只有成年及之后的不死鸟可以摘芽。"
        case .harvestCoolingDown: "这株不死鸟摘芽后需要等待 24 小时。"
        }
    }
}

// schema 5 新增乘数覆盖；旧文件缺少该字段时使用默认值，其他业务字段仍严格解码。
extension SucculentGarden {
    private enum CodingKeys: String, CodingKey {
        case version, money, leaves, plants, slots, growthRate, growthMultipliers, claimDate, claimedToday
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(Int.self, forKey: .version)
        money = try values.decode(Int.self, forKey: .money)
        leaves = try values.decode([SucculentLeaf].self, forKey: .leaves)
        plants = try values.decode([SucculentPlant].self, forKey: .plants)
        slots = try values.decode([UUID?].self, forKey: .slots)
        growthRate = try values.decode(Double.self, forKey: .growthRate)
        growthMultipliers = try values.decodeIfPresent(GardenGrowthMultipliers.self, forKey: .growthMultipliers) ?? .init()
        claimDate = try values.decodeIfPresent(Date.self, forKey: .claimDate)
        claimedToday = try values.decode(Int.self, forKey: .claimedToday)
    }
}
