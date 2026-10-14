// 只操作隔离文件，验证提示跟随真实保存结果与材料丢弃范围。
import Foundation
import Testing

@MainActor @Suite(.serialized)
struct GardenNoticeTests {
    private func file() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("garden.json")
    }

    @Test
    func successfulActionShowsSavedResultAndInitialLoadIsQuiet() async throws {
        let url = try file(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let model = GardenModel(store: SucculentStore(fileURL: url))
        await model.load()
        #expect(model.notice == nil)
        await model.buy(.juvenile, species: .taodan)
        let state = try #require(model.garden)
        #expect(state.money == 7 && state.unplacedPlants.last?.species == .taodan)
        #expect(model.notice?.isError == false && model.notice?.message.contains("我的多肉") == true)
        #expect(try await SucculentStore(fileURL: url).read() == state)
    }

    @Test
    func failedActionReportsReasonWithoutSuccessOrDataChanges() async throws {
        let url = try file(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let model = GardenModel(store: SucculentStore(fileURL: url)); await model.load()
        let before = model.garden; let bytes = try Data(contentsOf: url)
        await model.buy(.cluster)
        #expect(model.garden == before && model.notice?.isError == true)
        #expect(model.notice?.message == GardenError.insufficientFunds.localizedDescription)
        #expect(try Data(contentsOf: url) == bytes)
        await model.load()
        #expect(model.notice == nil && model.errorMessage == nil)
    }

    @Test
    func staleDismissalCannotCloseNewerNotice() async throws {
        let url = try file(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let model = GardenModel(store: SucculentStore(fileURL: url)); await model.load()
        await model.claimLeaf(.huangli); let first = try #require(model.notice)
        await model.claimLeaf(.taodan); let second = try #require(model.notice)
        model.dismissNotice(first.id)
        #expect(model.notice == second)
        model.dismissNotice(second.id)
        #expect(model.notice == nil)
    }

    @Test
    func singleAndWholeSpeciesDiscardKeepOtherMaterialWalletAndQuota() async throws {
        let url = try file(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = SucculentStore(fileURL: url)
        for species in [SucculentSpecies.huangli,.yuzhui,.huangli,.yuzhui,.huangli] {
            _ = try await store.claimLeaf(species: species)
        }
        let model = GardenModel(store: store); await model.load()
        let before = try #require(model.garden); let id = try #require(before.leaves.first).id
        await model.discardLeaf(id)
        let once = try #require(model.garden)
        #expect(once.leafStacks.map(\.count) == [2,2])
        #expect(once.leaves.map(\.id) == before.leaves.filter { $0.id != id }.map(\.id))
        await model.discardLeaves(.huangli)
        let all = try #require(model.garden)
        #expect(all.leaves == before.leaves.filter { $0.species == .yuzhui })
        #expect(all.claimedToday == 5 && all.money == before.money && all.slots == before.slots)
        #expect(model.notice?.message.contains("2片") == true)
        #expect(try await SucculentStore(fileURL: url).read() == all)
        let bytes = try Data(contentsOf: url)
        await model.discardLeaf(id)
        #expect(model.notice?.isError == true && model.garden == all)
        #expect(try Data(contentsOf: url) == bytes)
    }

    @Test
    func plantingOneFromStackReportsThePotAndPreservesRemainingMaterial() async throws {
        let url = try file(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = SucculentStore(fileURL: url)
        _ = try await store.claimLeaf(species: .yuzhui); _ = try await store.claimLeaf(species: .yuzhui)
        let model = GardenModel(store: store); await model.load()
        let id = try #require(model.garden?.leaves.first).id
        await model.sow(id, in: 2)
        #expect(model.garden?.leafStacks.first?.count == 1)
        #expect(model.garden?.plant(in: 2)?.species == .yuzhui)
        #expect(model.notice?.message == "已将玉坠种入花盆3")
    }
}
