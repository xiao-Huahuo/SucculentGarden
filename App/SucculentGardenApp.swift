// 多肉主页面管理共享花园；桌面 Widget 的选择按钮通过深链接打开对应花盆。
import SwiftUI
import WidgetKit
import AppKit

@main
struct SucculentGardenApp: App {
    @State private var gardenModel = GardenModel()
    @Environment(\.scenePhase) private var scenePhase
    init() {
        // 启动时让已添加的小组件重新读取持久化数据，也刷新更新安装后的时间线。
        WidgetCenter.shared.reloadTimelines(ofKind: "LittleComponentWidget")
    }

    var body: some Scene {
        WindowGroup("多肉花园", id: "garden") {
            GardenMainView(model: gardenModel)
                .onOpenURL { url in
                    gardenModel.handle(url)
                    NSApp.activate()
                }
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
        }
        .handlesExternalEvents(matching: ["*"])
        .defaultSize(width: 940, height: 700)
        .windowToolbarStyle(.unified)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { WidgetCenter.shared.reloadTimelines(ofKind: "SucculentGardenWidget") }
        }
        Settings {
            ScrollView { GardenSettingsView(model: gardenModel).padding(20) }
                .frame(width: 560, height: 460)
                .overlay(alignment: .topTrailing) { GardenNoticeBanner(model: gardenModel).padding(12) }
        }
    }
}
