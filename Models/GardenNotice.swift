// 操作横幅只存在于当前界面，不写入花园存档。
import Foundation

struct GardenNotice: Identifiable, Equatable, Sendable {
    let id = UUID()
    let message: String
    var isError = false
}
