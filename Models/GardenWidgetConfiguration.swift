// 小号组件从唯一桌面花园中选一只普通盆；中号展示整个三格花园。
import AppIntents

enum GardenPotChoice: Int, AppEnum {
    case first = 0, second = 1, third = 2
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "花盆")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .first: "花盆 1", .second: "花盆 2", .third: "花盆 3"
    ]
}

struct GardenWidgetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "多肉花园"
    static let description = IntentDescription("只放一块多肉花园组件；小号选择普通盆，中号展示整个花园。")
    @Parameter(title: "小号显示", default: .first) var pot: GardenPotChoice
}
