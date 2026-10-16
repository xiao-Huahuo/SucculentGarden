// WidgetKit不提供时间线实例ID；由用户选择稳定花园实体，系统配置只读枚举用于显示实际桌面组件。
import AppIntents
import WidgetKit
import Foundation

enum GardenPotChoice: Int, AppEnum {
    case first = 0, second = 1, third = 2
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "花盆")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .first: "花盆 1", .second: "花盆 2", .third: "花盆 3"
    ]
}

struct GardenWidgetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "多肉花园"
    static let description = IntentDescription("每块组件选择自己的独立花园。先在主页面创建，再在这里选择对应尺寸。")
    @Parameter(title: "独立花园") var layout: GardenLayoutEntity?
    // 保留旧参数身份以读取已安装实例；新编辑页面只展示独立花园。
    @Parameter(title: "旧版小号显示", default: .first) var pot: GardenPotChoice
    static var parameterSummary: some ParameterSummary { Summary { \.$layout } }
}

struct GardenLayoutEntity: AppEntity {
    let id: String
    let name: String
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "独立花园")
    static let defaultQuery = GardenLayoutQuery()
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct GardenLayoutQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [GardenLayoutEntity] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }
    func suggestedEntities() async throws -> [GardenLayoutEntity] {
        try await SucculentStore.shared.read().layouts.map { GardenLayoutEntity(id: $0.id.uuidString, name: $0.name) }
    }
}

struct GardenWidgetBinding: Identifiable, Equatable, Sendable {
    let id: String
    let layoutID: UUID?
    let size: GardenLayoutSize
    var isLegacy: Bool

    static func problem(layoutID: UUID?, size: GardenLayoutSize, garden: SucculentGarden, bindings: [Self]) -> String? {
        if let layoutID, bindings.filter({ $0.layoutID == layoutID }).count > 1 {
            return "每块组件需选择不同花园。请编辑本组件，选择独立花园。"
        }
        guard let layoutID, let layout = garden.layout(id: layoutID), layout.size == size else {
            return "请先在主页面创建\(size.title)花园，再编辑本组件选择它。"
        }
        return nil
    }

    static func configured() async throws -> [Self] {
        let infos = try await WidgetCenter.shared.currentConfigurations()
        return infos.enumerated().compactMap { index, info in
            guard info.kind == "SucculentGardenWidget",
                  info.family == .systemSmall || info.family == .systemMedium else { return nil }
            let configuration = info.widgetConfigurationIntent(of: GardenWidgetConfiguration.self)
            let size: GardenLayoutSize = info.family == .systemSmall ? .small : .medium
            let selected = configuration?.layout.flatMap { UUID(uuidString: $0.id) }
            // 原有中号实例继续使用原三盆；旧小号须选择自己的花园，不再借用中号的盆。
            return Self(id: "\(index)", layoutID: selected ?? (size == .medium ? GardenLayout.originalID : nil),
                        size: size, isLegacy: selected == nil)
        }
    }
}
