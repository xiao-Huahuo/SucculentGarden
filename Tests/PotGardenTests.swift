// 隔离覆盖唯一三格花园、空间容量、暂停续长和旧存档迁移，不操作真实存档。
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

    @Test func wideAndLongPotsUseOnlyTheSharedThreeSpaces() async throws {
        let (url, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: url) }
        let state = try await store.read()
        #expect(state.layouts.count == 1 && state.layouts[0].pots == GardenPot.originalIDs)
        let bought = try await store.buyPot(kind: .wide)
        let wide = try #require(bought.pots.last)
        #expect(bought.money == 1_800 && wide.plants.count == 3)
        await #expect(throws: GardenError.self) { try await store.placePot(id: wide.id, in: UUID()) }
        await #expect(throws: GardenError.self) { try await store.placePot(id: wide.id, in: GardenLayout.originalID) }
        _ = try await store.withdrawPot(id: GardenPot.originalIDs[1])
        _ = try await store.withdrawPot(id: GardenPot.originalIDs[2])
        let placed = try await store.placePot(id: wide.id, in: GardenLayout.originalID)
        #expect(placed.layouts[0].pots == [GardenPot.originalIDs[0], wide.id])
        let longState = try await store.buyPot(kind: .long)
        let long = try #require(longState.pots.last)
        await #expect(throws: GardenError.self) { try await store.placePot(id: long.id, in: GardenLayout.originalID) }
        #expect(try await store.read() == longState)
        _ = try await store.withdrawPot(id: wide.id)
        _ = try await store.withdrawPot(id: GardenPot.originalIDs[0])
        let final = try await store.placePot(id: long.id, in: GardenLayout.originalID)
        #expect(final.layouts[0].pots == [long.id] && long.plants.count == 5 && final.layouts.count == 1)
    }

    @Test func smallWidgetChoosesAnOrdinaryPotByItsDisplayedSpace() {
        var state = SucculentGarden()
        #expect(state.smallWidgetPot(choice: .second)?.id == GardenPot.originalIDs[1])
        let replacement = GardenPot(number: 4, kind: .ordinary)
        state.pots.append(replacement)
        state.layouts[0].pots = [GardenPot.originalIDs[0], replacement.id, GardenPot.originalIDs[2]]
        #expect(state.smallWidgetPot(choice: .second)?.id == replacement.id)
        let wide = GardenPot(number: 5, kind: .wide)
        state.pots.append(wide)
        state.layouts[0].pots = [wide.id, replacement.id]
        #expect(state.smallWidgetPot(choice: .third)?.id == replacement.id)
        #expect(state.smallWidgetPot(choice: .first)?.id == replacement.id)
        state.layouts[0].pots = [wide.id]
        #expect(state.smallWidgetPot(choice: .first) == nil)
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

    @Test func widePotSowingReplacementAndMovementDoNotDuplicate() async throws {
        let (url, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try await store.withdrawPot(id: GardenPot.originalIDs[1])
        _ = try await store.withdrawPot(id: GardenPot.originalIDs[2])
        let pot = try #require((try await store.buyPot(kind: .wide)).pots.last)
        _ = try await store.placePot(id: pot.id, in: GardenLayout.originalID)
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
        #expect(read.version == 9 && read.slots == old.slots && read.money == old.money)
        #expect(read.pots.count == 3 && read.layouts.count == 1)
        #expect(read.plants.allSatisfy { $0.age(at: at, rate: 1) == 110 })
        #expect(read.plants.prefix(3).allSatisfy(\.isGrowing) && !read.plants[3].isGrowing)
        #expect(try Data(contentsOf: url) == data)
        let saved = try await store.read(createIfMissing: true, at: at)
        #expect(try await store.read(at: at.addingTimeInterval(day)) == saved)
    }
    @Test func schemaEightRemovesOnlyEmptyExtraGardensWithoutChangingInventory() async throws {
        let (url, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: url) }
        var old = try await store.read()
        old.version = 8
        old.layouts += [GardenLayout(id: UUID(), name: "中号花园 2", size: .medium, pots: []),
                        GardenLayout(id: UUID(), name: "中号花园 3", size: .medium, pots: [])]
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: url)
        let preview = try await store.read()
        #expect(preview.version == 9 && preview.layouts == [old.layouts[0]])
        #expect(preview.pots == old.pots && preview.plants == old.plants && preview.leaves == old.leaves && preview.money == old.money)
        #expect(try Data(contentsOf: url) == bytes)
        let saved = try await store.read(createIfMissing: true)
        let reopened = try await store.read()
        #expect(saved == preview && reopened == saved)
    }

    @Test func schemaEightReturnsOverflowPotsAndPausesTheirPlantsWithoutLoss() async throws {
        let (url, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: url) }
        var old = try await store.read()
        old.version = 8
        let leafID = try #require((try await store.claimLeaf(at: date)).leaves.last?.id)
        old = try await store.sow(leafID: leafID, in: 0, at: date)
        old.version = 8
        let plantID = try #require(old.pots[0].plants[0])
        let moved = old.layouts[0].pots.removeFirst()
        var wide = GardenPot(number: 4, kind: .wide)
        let overflowPlant = SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: 0, growthUpdatedAt: date)
        old.plants.append(overflowPlant)
        wide.plants[0] = overflowPlant.id
        old.pots.append(wide)
        old.layouts.append(GardenLayout(id: UUID(), name: "中号花园 2", size: .medium, pots: [wide.id, moved]))
        // 共用花园已有2格，只能再容纳原普通盆；宽盆及植株会留在库存/收藏。
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: url)
        let migrated = try await store.read(at: date.addingTimeInterval(day))
        #expect(migrated.version == 9 && migrated.layouts.count == 1)
        #expect(migrated.layouts[0].pots == [GardenPot.originalIDs[1], GardenPot.originalIDs[2], moved])
        #expect(migrated.unplacedPots.map(\.id) == [wide.id])
        #expect(migrated.plant(id: plantID)?.isGrowing == true)
        #expect(migrated.plant(id: overflowPlant.id)?.isGrowing == false)
        #expect(migrated.plant(id: overflowPlant.id)?.growthSeconds == day)
        #expect(migrated.unplacedPlants.map(\.id).contains(overflowPlant.id))
        #expect(try Data(contentsOf: url) == bytes)
    }

    @Test func potSurfaceGeometryAndLinksStayAlignedWithSharedLayout() throws {
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
