// 盆内位置与组件归属是唯一摆放来源；旧槽位只保留为兼容旧链接和存档的计算属性。
import Foundation

extension SucculentGarden {
    var slots: [UUID?] {
        get { GardenPot.originalIDs.map { pot(id: $0)?.plants.first ?? nil } }
        set {
            for (index, id) in GardenPot.originalIDs.enumerated() where newValue.indices.contains(index) {
                if let position = pots.firstIndex(where: { $0.id == id }) { pots[position].plants = [newValue[index]] }
            }
            if version >= 8 {
                for index in plants.indices { plants[index].isGrowing = pot(containing: plants[index].id) != nil }
            }
        }
    }

    func plant(id: UUID?) -> SucculentPlant? { plants.first { $0.id == id } }
    func pot(id: UUID) -> GardenPot? { pots.first { $0.id == id } }
    func layout(id: UUID) -> GardenLayout? { layouts.first { $0.id == id } }
    func layout(containing potID: UUID) -> GardenLayout? { layouts.first { $0.pots.contains(potID) } }
    func pot(containing plantID: UUID) -> GardenPot? {
        pots.first { $0.plants.contains(plantID) && layout(containing: $0.id) != nil }
    }
    var unplacedPots: [GardenPot] { pots.filter { layout(containing: $0.id) == nil } }

    func validatePots() throws {
        let potIDs = Set(pots.map(\.id)), plantIDs = Set(plants.map(\.id))
        let placedPots = layouts.flatMap(\.pots)
        let pottedPlants = pots.flatMap(\.plants).compactMap { $0 }
        guard !layouts.isEmpty, Set(layouts.map(\.id)).count == layouts.count,
              potIDs.count == pots.count, Set(pots.map(\.number)).count == pots.count,
              pots.allSatisfy({ $0.number > 0 && $0.plants.count == $0.kind.capacity }),
              Set(placedPots).count == placedPots.count, placedPots.allSatisfy({ potIDs.contains($0) }),
              Set(pottedPlants).count == pottedPlants.count, pottedPlants.allSatisfy({ plantIDs.contains($0) }),
              unplacedPots.allSatisfy(\.isEmpty),
              layouts.allSatisfy({ layout in
                  !layout.name.isEmpty && layout.pots.compactMap { pot(id: $0) }.reduce(0) { $0 + $1.kind.space } <= layout.size.space
              }),
              plants.allSatisfy({ $0.isGrowing == (pot(containing: $0.id) != nil) }) else { throw GardenError.invalidData }
    }

    mutating func putPlant(_ id: UUID, in potID: UUID, position requested: Int?, at date: Date) throws {
        guard let target = pots.firstIndex(where: { $0.id == potID }), layout(containing: potID) != nil else { throw GardenError.potMissing }
        guard plants.contains(where: { $0.id == id }) else { throw GardenError.plantMissing }
        if requested == nil, pots[target].plants.contains(id) { return }
        guard let position = requested ?? pots[target].plants.firstIndex(of: nil) else { throw GardenError.potFull }
        guard pots[target].plants.indices.contains(position) else { throw GardenError.invalidPotPosition }
        if pots[target].plants[position] == id { return }
        if let displaced = pots[target].plants[position] { removePlant(displaced, at: date) }
        for index in pots.indices { pots[index].plants = pots[index].plants.map { $0 == id ? nil : $0 } }
        pots[target].plants[position] = id
        if let index = plants.firstIndex(where: { $0.id == id }) {
            if !plants[index].isGrowing { plants[index].growthUpdatedAt = max(date, plants[index].growthUpdatedAt) }
            plants[index].isGrowing = true
        }
    }

    mutating func removePlant(_ id: UUID, at date: Date) {
        if let index = plants.firstIndex(where: { $0.id == id }), plants[index].isGrowing {
            plants[index].settle(at: date, rate: effectiveRate(for: plants[index].species))
            plants[index].isGrowing = false
        }
        for index in pots.indices { pots[index].plants = pots[index].plants.map { $0 == id ? nil : $0 } }
    }
}
