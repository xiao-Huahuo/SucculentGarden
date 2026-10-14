// 木鱼球的持久化状态；每次点击保存累计数值和本次反馈位置。
import Foundation

struct MuyuProgress: Codable, Equatable, Sendable {
    var version = 1
    var merit = 0
    var fortune = 0
    var dailySeed = UInt64.random(in: 1...UInt64.max)
    var popupX = 0.0
    var popupY = 0.0
    var lastTap: Date?
}
