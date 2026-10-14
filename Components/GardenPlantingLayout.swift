// 显示尺寸与落点路由共用，避免浮层坐标被当作单个花盆坐标。
import Foundation

enum GardenPlantingLayout {
    static let width: CGFloat = 360
    static let padding: CGFloat = 12
    static let spacing: CGFloat = 10
    static let scrollClearance: CGFloat = 240

    static func slot(at x: CGFloat, width: CGFloat) -> Int? {
        guard x.isFinite, width.isFinite, width > 2 * padding + 2 * spacing,
              x >= 0, x <= width else { return nil }
        let slotWidth = (width - 2 * padding - 2 * spacing) / 3
        return min(2, max(0, Int((x - padding + spacing / 2) / (slotWidth + spacing))))
    }
}
