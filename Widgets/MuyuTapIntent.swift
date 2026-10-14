// 点击球体触发真实的持久化写入；操作完成后系统重新加载小组件时间线。
import AppIntents
import WidgetKit

struct MuyuTapIntent: AppIntent {
    static let title: LocalizedStringResource = "敲木鱼球"
    static let description = IntentDescription("功德增加 1，福缘随机增加 1 至 3。")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        do {
            try await MuyuStore.shared.tap()
            WidgetCenter.shared.reloadTimelines(ofKind: "LittleComponentWidget")
        } catch {
            await MuyuStore.shared.recordFailure(error)
            throw error
        }
        return .result()
    }
}
