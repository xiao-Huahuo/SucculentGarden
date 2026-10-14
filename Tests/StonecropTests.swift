// 万年草型的四阶段、枝插与全局额度；测试文件完全隔离于真实花园。
import Foundation
import Testing

@Suite(.serialized)
struct StonecropTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 86_400

    @Test
    func fourStagesHaveExactGrowthBoundariesAndNoOldStemTransitions() {
        for species in [SucculentSpecies.goldenStonecrop, .snowStonecrop, .jixingMeiren] {
            #expect(species.stages.map(\.title) == ["小草", "群生", "草丛", "爆盆"])
            #expect(species.propagationTitle == "枝条")
            let plant = SucculentPlant(id: UUID(), acquiredAt: date, growthSeconds: 0,
                                       growthUpdatedAt: date, species: species)
            let stages: [(Double, SucculentStage)] = [(0, .grassSprout), (1, .grassCluster),
                                                     (4, .grassClump), (9, .grassOverflow)]
            for (index, pair) in stages.enumerated() {
                #expect(plant.stage(at: date.addingTimeInterval(pair.0 * day), rate: 1) == pair.1)
                if index > 0 {
                    #expect(plant.stage(at: date.addingTimeInterval(pair.0 * day - 1), rate: 1) == stages[index - 1].1)
                }
            }
            #expect(plant.stage(at: date.addingTimeInterval(400 * day), rate: 1) == .grassOverflow)
            #expect(plant.age(at: date.addingTimeInterval(400 * day), rate: 1) == 9 * day)
            #expect(plant.transitionDates(after: date, rate: 1) == [1.0, 4, 9].map { date.addingTimeInterval($0 * day) })
        }
    }

    @Test
    func leavesAndTwigsShareFiveClaimsAndTwigsOnlyGrowAfterPlanting() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("garden.json")
        let store = SucculentStore(fileURL: url)
        let species: [SucculentSpecies] = [.huangli, .goldenStonecrop, .snowStonecrop, .jixingMeiren, .goldenStonecrop]
        for value in species { _ = try await store.claimLeaf(species: value, at: date) }
        let inventory = try await SucculentStore(fileURL: url).read()
        #expect(inventory.money == 10 && inventory.claimedToday == 5)
        #expect(inventory.plants.isEmpty && inventory.leaves.map(\.species) == species)
        for value in [SucculentSpecies.huangli, .goldenStonecrop, .snowStonecrop, .jixingMeiren, .yuzhui] {
            await #expect(throws: GardenError.self) { try await store.claimLeaf(species: value, at: date) }
        }
        let plantingDate = date.addingTimeInterval(100 * day)
        let twig = inventory.leaves[1]
        let planted = try await store.sow(leafID: twig.id, in: 0, at: plantingDate)
        let plant = try #require(planted.plant(in: 0))
        #expect(plant.species == .goldenStonecrop && plant.stage(at: plantingDate, rate: 1) == .grassSprout)
        #expect(planted.leaves.count == 4 && planted.money == 10)
        await #expect(throws: GardenError.self) { try await store.sow(leafID: twig.id, in: 1, at: plantingDate) }
        _ = try await store.sow(leafID: inventory.leaves[2].id, in: 1, at: plantingDate)
        let snowID = try #require((try await store.read()).plant(in: 1)).id
        let moved = try await store.assign(plantID: snowID, to: 0)
        #expect(moved.slots == [snowID, nil, nil] && moved.unplacedPlants == [plant])
        #expect(try await SucculentStore(fileURL: url).read() == moved)
    }

    @Test
    func everyPriceIsPaidOnceAndForeignStagesCannotBeBought() async throws {
        for species in [SucculentSpecies.goldenStonecrop, .snowStonecrop, .jixingMeiren] {
            let directory = try temporaryDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appendingPathComponent("garden.json")
            let store = SucculentStore(fileURL: url)
            // 正常叶插成长/出售筹资，完全在临时文件中。
            for slot in 0..<3 {
                let leaf = try #require((try await store.claimLeaf(at: date)).leaves.last)
                _ = try await store.sow(leafID: leaf.id, in: slot, at: date)
            }
            let later = date.addingTimeInterval(39 * day)
            for plant in try await store.read().plants { _ = try await store.sell(plantID: plant.id, at: later) }
            let before = try Data(contentsOf: url)
            for stage in [SucculentStage.grassSprout, .sprout, .juvenile, .cluster] {
                await #expect(throws: GardenError.self) { try await store.buy(stage: stage, species: species, at: later) }
            }
            await #expect(throws: GardenError.self) { try await store.buy(stage: .grassCluster, at: later) }
            #expect(try Data(contentsOf: url) == before)
            let twig = try #require((try await store.claimLeaf(species: species, at: later)).leaves.last)
            let small = try await store.sow(leafID: twig.id, in: 0, at: later)
            let smallID = try #require(small.plant(in: 0)).id
            let soldSmall = try await store.sell(plantID: smallID, at: later)
            #expect(soldSmall.money == small.money + 1)
            var previous = soldSmall
            let prices: [(SucculentStage, Int, Int)] = [(.grassCluster, 3, 2), (.grassClump, 10, 5), (.grassOverflow, 20, 10)]
            for (stage, buy, sell) in prices {
                let bought = try await store.buy(stage: stage, species: species, at: later)
                let plant = try #require(bought.plants.last)
                #expect(bought.money == previous.money - buy && plant.stage(at: later, rate: 1) == stage)
                let sold = try await store.sell(plantID: plant.id, at: later)
                #expect(sold.money == bought.money + sell && sold.plants.isEmpty)
                await #expect(throws: GardenError.self) { try await store.sell(plantID: plant.id, at: later) }
                #expect(try await SucculentStore(fileURL: url).read() == sold)
                previous = sold
            }
        }
    }

    @Test
    func rateChangePreservesGrassProgressAndThreeFutureTransitions() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SucculentStore(fileURL: directory.appendingPathComponent("garden.json"))
        let twig = try #require((try await store.claimLeaf(species: .snowStonecrop, at: date)).leaves.last)
        _ = try await store.sow(leafID: twig.id, in: 0, at: date)
        let changedAt = date.addingTimeInterval(day / 4)
        let changed = try await store.changeRate(to: 2, at: changedAt)
        let plant = try #require(changed.plant(in: 0))
        #expect(plant.growthSeconds == day / 2)
        #expect(plant.transitionDates(after: changedAt, rate: changed.effectiveRate(for: plant.species)).count == 3)
        let next = try #require(plant.transitionDates(after: changedAt, rate: changed.effectiveRate(for: plant.species)).first)
        #expect(next == date.addingTimeInterval(day * 0.375))
        #expect(plant.stage(at: next, rate: changed.effectiveRate(for: plant.species)) == .grassCluster)
        #expect(plant.transitionDates(after: date.addingTimeInterval(100 * day), rate: 2).isEmpty)
    }

    @Test
    func trailingLeavesStayInsideSlotsWhilePlantBaseMeetsPotRim() {
        let layouts = [SucculentArtworkLayout(x: 42, y: 59, w: 1181, h: 1168, anchorY: 900),
                       SucculentArtworkLayout(x: 5, y: 153, w: 1244, h: 964, anchorY: 847)]
        for layout in layouts {
            for width: CGFloat in [78, 82, 96] {
                let size = CGSize(width: width, height: width + 15)
                let placement = layout.placement(in: size, planted: true)
                let base = layout.plantingAnchorY! * placement.scale + placement.offset.height
                #expect(abs(base - (size.height - 23)) < 0.001)
                #expect(layout.bounds.minY * placement.scale + placement.offset.height >= -0.001)
                #expect(layout.bounds.maxY * placement.scale + placement.offset.height <= size.height + 0.001)
                #expect(layout.bounds.minX * placement.scale + placement.offset.width >= -0.001)
                #expect(layout.bounds.maxX * placement.scale + placement.offset.width <= size.width + 0.001)
            }
        }
    }

    @Test
    func independentRootFootprintFitsSoilAtEveryDisplaySize() {
        let layout = SucculentArtworkLayout(x: 20, y: 100, w: 1200, h: 1000,
                                            rootMinX: 160, rootMaxX: 1080)
        for width: CGFloat in [58.5, 72, 78, 96] {
            let size = CGSize(width: width, height: 111)
            let position = layout.placement(in: size, planted: true)
            let leftRoot = 160 * position.scale + position.offset.width
            let rightRoot = 1080 * position.scale + position.offset.width
            #expect(leftRoot >= size.width / 2 - 17 - 0.001)
            #expect(rightRoot <= size.width / 2 + 17 + 0.001)
            #expect(abs(layout.bounds.maxY * position.scale + position.offset.height - 88) < 0.001)
        }
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
