// 花盆购买、组件摆放与两步撤下在同一次原子存档中完成，失败不消耗钱或库存。
import Foundation

extension SucculentStore {
    func createLayout(size: GardenLayoutSize) throws -> SucculentGarden {
        try mutate { state in
            let number = state.layouts.filter { $0.size == size }.count + 1
            state.layouts.append(GardenLayout(id: UUID(), name: "\(size.title)花园 \(number)", size: size, pots: []))
        }
    }

    func buyPot(kind: GardenPotKind) throws -> SucculentGarden {
        try mutate { state in
            guard state.money >= kind.price else { throw GardenError.insufficientFunds }
            state.money -= kind.price
            state.pots.append(GardenPot(number: (state.pots.map(\.number).max() ?? 0) + 1, kind: kind))
        }
    }

    func placePot(id: UUID, in layoutID: UUID, before otherID: UUID? = nil) throws -> SucculentGarden {
        try mutate { state in
            guard let pot = state.pot(id: id) else { throw GardenError.potMissing }
            guard let target = state.layouts.firstIndex(where: { $0.id == layoutID }) else { throw GardenError.layoutMissing }
            let remaining = state.layouts[target].pots.filter { $0 != id }
            let used = remaining.compactMap { state.pot(id: $0) }.reduce(0) { $0 + $1.kind.space }
            guard used + pot.kind.space <= state.layouts[target].size.space else { throw GardenError.insufficientSpace }
            // 在两个独立组件之间搬的是整只盆；旧组件立即腾出空间，不复制盆和植株。
            for index in state.layouts.indices { state.layouts[index].pots.removeAll { $0 == id } }
            let insertion = otherID.flatMap { state.layouts[target].pots.firstIndex(of: $0) } ?? state.layouts[target].pots.count
            state.layouts[target].pots.insert(id, at: insertion)
        }
    }

    func withdrawPot(id: UUID, at date: Date = .now) throws -> SucculentGarden {
        try mutate(at: date) { state in
            guard let pot = state.pot(id: id), state.layout(containing: id) != nil else { throw GardenError.potMissing }
            if pot.isEmpty {
                for index in state.layouts.indices { state.layouts[index].pots.removeAll { $0 == id } }
            } else {
                for plantID in pot.plants.compactMap({ $0 }) { state.removePlant(plantID, at: date) }
            }
        }
    }

    func removePlant(id: UUID, at date: Date = .now) throws -> SucculentGarden {
        try mutate(at: date) { state in
            guard state.plants.contains(where: { $0.id == id }) else { throw GardenError.plantMissing }
            state.removePlant(id, at: date)
        }
    }

    func assign(plantID: UUID, toPot potID: UUID, position: Int? = nil, at date: Date = .now) throws -> SucculentGarden {
        try mutate(at: date) { state in try state.putPlant(plantID, in: potID, position: position, at: date) }
    }

    func sow(leafID: UUID, inPot potID: UUID, position: Int? = nil, at date: Date = .now) throws -> SucculentGarden {
        try mutate(at: date) { state in
            guard let index = state.leaves.firstIndex(where: { $0.id == leafID }) else { throw GardenError.leafMissing }
            let plant = SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: 0,
                                       growthUpdatedAt: date, species: state.leaves[index].species, isGrowing: false)
            state.plants.append(plant)
            try state.putPlant(plant.id, in: potID, position: position, at: date)
            state.leaves.remove(at: index)
        }
    }
}
