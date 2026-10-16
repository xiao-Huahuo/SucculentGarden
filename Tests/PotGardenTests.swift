// 独立文件覆盖多组件、空间容量、暂停续长和旧存档迁移，不操作用户真实花园。
import Foundation
import Testing

@Suite(.serialized)
struct PotGardenTests {
    let date = Date(timeIntervalSince1970: 1_800_000_000)
    let day = 86_400.0

    private func fixture() throws -> (URL, SucculentStore) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pots-\(UUID()).json")
        var state = SucculentGarden()
        state.money = 2_000
        try JSONEncoder().encode(state).write(to: url)
        return (url, SucculentStore(fileURL: url))
    }

    @Test func potSpaceAndOwnershipStayIndependentAcrossSeveralWidgets() async throws {
        let (url, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try await store.createLayout(size: .small)
        let state = try await store.createLayout(size: .medium)
        let small = state.layouts[1], second = state.layouts[2]
        let bought = try await store.buyPot(kind: .wide)
        let wide = try #require(bought.pots.last)
        #expect(bought.money == 1_800 && wide.plants.count == 3)
        await #expect(throws: GardenError.self) { try await store.placePot(id: wide.id, in: small.id) }
        let placed = try await store.placePot(id: wide.id, in: second.id)
        #expect(placed.layouts[0] == state.layouts[0] && placed.layouts[1] == small)
        #expect(placed.layout(containing: wide.id)?.id == second.id)
        let longState = try await store.buyPot(kind: .long)
        let long = try #require(longState.pots.last)
        await #expect(throws: GardenError.self) { try await store.placePot(id: long.id, in: second.id) }
        #expect(try await store.read() == longState)
        _ = try await store.withdrawPot(id: wide.id)
        let final = try await store.placePot(id: long.id, in: second.id)
        #expect(final.layout(id: second.id)?.pots == [long.id] && long.plants.count == 5)
        #expect(final.layouts[0].pots == GardenPot.originalIDs && final.layouts[1].pots.isEmpty)
    }

    @Test func twoStepWithdrawalKeepsPotThenReturnsItAndPausesGrowth() async throws {
        let (url, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: url) }
        let leaf = try #require((try await store.claimLeaf(at: date)).leaves.last)
        let planted = try await store.sow(leafID: leaf.id, in: 0, at: date)
        let id = try #require(planted.plants.last).id
        let half = date.addingTimeInterval(day / 2)
        let withdrawn = try await store.withdrawPot(id: GardenPot.originalIDs[0], at: half)
        let plant = try #require(withdrawn.plant(id: id))
        #expect(!plant.isGrowing && plant.age(at: half.addingTimeInterval(50 * day), rate: 1) == day / 2)
        #expect(plant.transitionDates(after: half, rate: 1).isEmpty)
        #expect(withdrawn.layouts[0].pots.count == 3 && withdrawn.pots[0].isEmpty)
        let removed = try await store.withdrawPot(id: GardenPot.originalIDs[0], at: half)
        #expect(removed.layouts[0].pots.count == 2 && removed.unplacedPots.map(\.id) == [GardenPot.originalIDs[0]])
        _ = try await store.placePot(id: GardenPot.originalIDs[0], in: GardenLayout.originalID)
        let later = half.addingTimeInterval(50 * day)
        let resumed = try await store.assign(plantID: id, toPot: GardenPot.originalIDs[0], at: later)
        let growing = try #require(resumed.plant(id: id))
        #expect(growing.isGrowing && growing.age(at: later, rate: 1) == day / 2)
        #expect(growing.stage(at: later.addingTimeInterval(day / 2), rate: 1) == .juvenile)
        #expect(try await SucculentStore(fileURL: url).read() == resumed)
    }

    @Test func widePotSowingReplacementAndCrossWidgetMovementDoNotDuplicate() async throws {
        let (url, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: url) }
        let layout = try #require((try await store.createLayout(size: .medium)).layouts.last)
        let pot = try #require((try await store.buyPot(kind: .wide)).pots.last)
        _ = try await store.placePot(id: pot.id, in: layout.id)
        for _ in 0..<3 {
            let leaf = try #require((try await store.claimLeaf(at: date)).leaves.last)
            _ = try await store.sow(leafID: leaf.id, inPot: pot.id, at: date)
        }
        let extra = try #require((try await store.claimLeaf(at: date)).leaves.last)
        let full = try await store.read()
        await #expect(throws: GardenError.self) { try await store.sow(leafID: extra.id, inPot: pot.id, at: date) }
        #expect(try await store.read() == full)
        let replaced = try await store.sow(leafID: extra.id, inPot: pot.id, position: 1, at: date)
        let outgoing = try #require(full.pot(id: pot.id)?.plants[1])
        #expect(replaced.pot(containing: outgoing) == nil && replaced.plant(id: outgoing)?.isGrowing == false)
        let incoming = try #require(replaced.pot(id: pot.id)?.plants[1])
        let moved = try await store.assign(plantID: incoming, toPot: GardenPot.originalIDs[0], at: date)
        #expect(moved.pot(id: pot.id)?.plants[1] == nil && moved.pots[0].plants[0] == incoming)
        #expect(moved.pots.flatMap(\.plants).filter { $0 == incoming }.count == 1)
    }

    @Test func purchasedPlantsPauseAndRemovingOnePlantDoesNotRemoveItsPot() async throws {
        let (url, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: url) }
        let purchased = try await store.buy(stage: .juvenile, at: date)
        let plant = try #require(purchased.plants.last)
        #expect(!plant.isGrowing && plant.stage(at: date.addingTimeInterval(100 * day), rate: 1) == .juvenile)
        _ = try await store.assign(plantID: plant.id, toPot: GardenPot.originalIDs[0], at: date)
        let removed = try await store.removePlant(id: plant.id, at: date.addingTimeInterval(day))
        #expect(removed.pots[0].isEmpty && removed.layouts[0].pots.count == 3)
        #expect(removed.plant(id: plant.id)?.growthSeconds == 2 * day)
    }

    @Test func schemaSevenMigratesEveryPlantAndOriginalPotWithoutWritingOnWidgetRead() async throws {
        let (url, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: url) }
        var old = SucculentGarden()
        old.version = 7
        old.plants = (0..<4).map { _ in SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: 10, growthUpdatedAt: date) }
        old.slots = old.plants.prefix(3).map(\.id)
        old.plants[3].isGrowing = true // 旧版未入盆也成长。
        let data = try JSONEncoder().encode(old)
        try data.write(to: url)
        let at = date.addingTimeInterval(100)
        let read = try await store.read(at: at)
        #expect(read.version == 8 && read.slots == old.slots && read.money == old.money)
        #expect(read.pots.count == 3 && read.layouts.count == 1)
        #expect(read.plants.allSatisfy { $0.age(at: at, rate: 1) == 110 })
        #expect(read.plants.prefix(3).allSatisfy(\.isGrowing) && !read.plants[3].isGrowing)
        #expect(try Data(contentsOf: url) == data)
        let saved = try await store.read(createIfMissing: true, at: at)
        #expect(try await store.read(at: at.addingTimeInterval(day)) == saved)
    }
    @Test func actualWidgetBindingsRequireUniqueGardensAndMatchingSizes() {
        var state = SucculentGarden()
        let small = GardenLayout(id: UUID(), name: "小号花园 1", size: .small, pots: [])
        let medium = GardenLayout(id: UUID(), name: "中号花园 2", size: .medium, pots: [])
        state.layouts += [small, medium]
        let bindings = [GardenWidgetBinding(id: "0", layoutID: state.layouts[0].id, size: .medium, isLegacy: true),
                        GardenWidgetBinding(id: "1", layoutID: small.id, size: .small, isLegacy: false),
                        GardenWidgetBinding(id: "2", layoutID: medium.id, size: .medium, isLegacy: false)]
        for binding in bindings {
            #expect(GardenWidgetBinding.problem(layoutID: binding.layoutID, size: binding.size, garden: state, bindings: bindings) == nil)
        }
        let duplicate = bindings + [GardenWidgetBinding(id: "3", layoutID: small.id, size: .small, isLegacy: false)]
        #expect(GardenWidgetBinding.problem(layoutID: small.id, size: .small, garden: state, bindings: duplicate) != nil)
        #expect(GardenWidgetBinding.problem(layoutID: small.id, size: .medium, garden: state, bindings: bindings) != nil)
        #expect(GardenWidgetBinding.problem(layoutID: nil, size: .small, garden: state, bindings: bindings) != nil)
        #expect(GardenWidgetBinding.problem(layoutID: medium.id, size: .medium, garden: state, bindings: duplicate) == nil)
    }

    @Test func potSurfaceGeometryAndLinksStayAlignedWithIndependentLayouts() throws {
        var state = SucculentGarden()
        let wide = GardenPot(number: 4, kind: .wide)
        let layout = GardenLayout(id: UUID(), name: "组合", size: .medium, pots: [wide.id, state.pots[0].id])
        state.pots.append(wide)
        let frames = GardenPotGeometry.frames(layout: layout, garden: state, width: 330)
        #expect(frames.map { $0.rect.width } == [220, 110])
        #expect(frames[0].rect.maxX == frames[1].rect.minX && frames[1].rect.maxX == 330)
        for kind in GardenPotKind.allCases {
            let roots = GardenPotGeometry.roots(kind: kind, width: 100 * CGFloat(kind.space), height: 100)
            #expect(roots.count == kind.capacity && roots.allSatisfy { $0.x > 0 && $0.y > 0 && $0.y < 100 })
            for (index, root) in roots.enumerated() {
                #expect(GardenPotGeometry.nearestPosition(kind: kind, point: root, width: 100 * CGFloat(kind.space), height: 100) == index)
            }
        }
        let url = GardenRoute.url(layoutID: layout.id, potID: wide.id)
        let route = try #require(GardenRoute.destination(from: url))
        #expect(route.layoutID == layout.id && route.potID == wide.id)
        #expect(GardenRoute.slot(from: url) == nil)
    }

}
