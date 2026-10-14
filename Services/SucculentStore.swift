// 主应用是花园唯一写入者；Widget 只读共享 App Group 文件，读取不会创建或重置业务数据。
import Foundation
import OSLog

actor SucculentStore {
    static let groupID = "GU3HYVNR96.local.littlecomponent.garden"
    static let shared = SucculentStore()
    private let suppliedURL: URL?
    private let logger = Logger(subsystem: "local.littlecomponent.app", category: "SucculentStore")

    init(fileURL: URL? = nil) { suppliedURL = fileURL }

    func read(createIfMissing: Bool = false, at date: Date = .now) throws -> SucculentGarden {
        let url = try storageURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            let initial = SucculentGarden()
            if createIfMissing { try save(initial, to: url) }
            return initial
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let version = try decoder.decode(GardenFileHeader.self, from: data).version
        decoder.userInfo[SucculentSpecies.legacyDecodingKey] = version < 3
        var state = try decoder.decode(SucculentGarden.self, from: data)
        try state.validate()
        if state.version < 7 {
            state.migrateLegacyState(at: date)
            try state.validate()
            if createIfMissing { try save(state, to: url) }
        }
        return state
    }

    func claimLeaf(species: SucculentSpecies = .huangli, at date: Date = .now,
                   calendar: Calendar = .autoupdatingCurrent) throws -> SucculentGarden {
        try mutate { state in
            try Self.recordClaim(in: &state, at: date, calendar: calendar)
            state.leaves.append(SucculentLeaf(id: UUID(), claimedAt: date, species: species))
        }
    }

    func sow(leafID: UUID, in slot: Int, at date: Date = .now) throws -> SucculentGarden {
        try mutate { state in
            guard state.slots.indices.contains(slot) else { throw GardenError.invalidSlot }
            guard let index = state.leaves.firstIndex(where: { $0.id == leafID }) else { throw GardenError.leafMissing }
            let plant = SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: 0,
                                       growthUpdatedAt: date, species: state.leaves[index].species)
            state.leaves.remove(at: index)
            state.plants.append(plant)
            state.slots[slot] = plant.id
        }
    }

    func buy(stage: SucculentStage, species: SucculentSpecies = .huangli,
             in slot: Int, at date: Date = .now, calendar: Calendar = .autoupdatingCurrent) throws -> SucculentGarden {
        try mutate { state in
            guard state.slots.indices.contains(slot) else { throw GardenError.invalidSlot }
            guard species.stages.contains(stage) else { throw GardenError.invalidStage }
            guard let price = species.purchasePrice(for: stage) else { throw GardenError.cannotBuyLeafCutting }
            guard state.money >= price else { throw GardenError.insufficientFunds }
            if price == 0 { try Self.recordClaim(in: &state, at: date, calendar: calendar) }
            let plant = SucculentPlant(id: UUID(), acquiredAt: date,
                                       growthSeconds: species.startSeconds(for: stage), growthUpdatedAt: date, species: species)
            state.money -= price
            state.plants.append(plant)
            // 免费领取先进入收藏，不能占用或替换用户已经摆好的花盆。
            if price > 0 { state.slots[slot] = plant.id }
        }
    }

    func assign(plantID: UUID, to slot: Int) throws -> SucculentGarden {
        try mutate { state in
            guard state.slots.indices.contains(slot) else { throw GardenError.invalidSlot }
            guard state.plants.contains(where: { $0.id == plantID }) else { throw GardenError.plantMissing }
            state.slots = state.slots.map { $0 == plantID ? nil : $0 }
            state.slots[slot] = plantID
        }
    }

    func clear(slot: Int) throws -> SucculentGarden {
        try mutate { state in
            guard state.slots.indices.contains(slot) else { throw GardenError.invalidSlot }
            state.slots[slot] = nil
        }
    }

    func sell(plantID: UUID, at date: Date = .now) throws -> SucculentGarden {
        try mutate { state in
            guard let index = state.plants.firstIndex(where: { $0.id == plantID }) else { throw GardenError.plantMissing }
            let price = state.plants[index].stage(at: date, rate: state.effectiveRate(for: state.plants[index].species)).salePrice
            state.money += price
            state.plants.remove(at: index)
            state.slots = state.slots.map { $0 == plantID ? nil : $0 }
        }
    }

    func disassemble(plantID: UUID, at date: Date = .now) throws -> SucculentGarden {
        try mutate { state in
            guard let index = state.plants.firstIndex(where: { $0.id == plantID }) else { throw GardenError.plantMissing }
            let plant = state.plants[index]
            let stage = plant.stage(at: date, rate: state.effectiveRate(for: plant.species))
            guard let count = plant.species.disassemblyCount(for: stage) else { throw GardenError.cannotDisassemble }
            state.leaves.append(contentsOf: (0..<count).map { _ in
                SucculentLeaf(id: UUID(), claimedAt: date, species: plant.species)
            })
            state.plants.remove(at: index)
            state.slots = state.slots.map { $0 == plantID ? nil : $0 }
        }
    }

    func harvest(plantID: UUID, at date: Date = .now) throws -> SucculentGarden {
        try mutate { state in
            guard let index = state.plants.firstIndex(where: { $0.id == plantID }) else { throw GardenError.plantMissing }
            let plant = state.plants[index]
            let stage = plant.stage(at: date, rate: state.effectiveRate(for: plant.species))
            guard let count = plant.species.harvestCount(for: stage) else { throw GardenError.cannotHarvest }
            if let next = plant.nextHarvestDate(), date < next { throw GardenError.harvestCoolingDown }
            state.leaves.append(contentsOf: (0..<count).map { _ in
                SucculentLeaf(id: UUID(), claimedAt: date, species: plant.species)
            })
            state.plants[index].lastHarvestedAt = date
        }
    }

    func changeRate(to rate: Double, at date: Date = .now) throws -> SucculentGarden {
        guard rate.isFinite, (0.25...1_000).contains(rate) else { throw GardenError.invalidRate }
        return try mutate { state in
            state.settleGrowth(at: date)
            state.growthRate = rate
        }
    }

    func changeMultipliers(to multipliers: GardenGrowthMultipliers, at date: Date = .now) throws -> SucculentGarden {
        try multipliers.validate()
        return try mutate { state in
            state.settleGrowth(at: date)
            state.growthMultipliers = multipliers
        }
    }

    private func mutate(_ action: (inout SucculentGarden) throws -> Void) throws -> SucculentGarden {
        do {
            var state = try read(createIfMissing: true)
            try action(&state)
            try state.validate()
            try save(state, to: storageURL())
            return state
        } catch {
            logger.error("花园操作失败：\(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private static func recordClaim(in state: inout SucculentGarden, at date: Date, calendar: Calendar) throws {
        guard state.remainingClaims(at: date, calendar: calendar) > 0 else { throw GardenError.dailyLimit }
        if state.claimDate == nil || !calendar.isDate(state.claimDate!, inSameDayAs: date) { state.claimedToday = 0 }
        state.claimDate = date
        state.claimedToday += 1
    }

    private func storageURL() throws -> URL {
        if let suppliedURL { return suppliedURL }
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.groupID
        ) else { throw GardenError.sharedContainerUnavailable }
        let directory = container.appendingPathComponent("Library/Application Support/SucculentGarden", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("garden.json")
    }

    private func save(_ state: SucculentGarden, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(state).write(to: url, options: .atomic)
    }
}

private struct GardenFileHeader: Decodable { let version: Int }
