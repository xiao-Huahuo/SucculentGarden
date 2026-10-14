// 三新品种群生修正为紧凑侧芽簇；原图仅在运行时取帧，不改写像素。
import Foundation

enum Revision40AtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "CheeseStage5": .init(sourceName: "RosetteClusters40Atlas", rect: CGRect(x: 0, y: 0, width: 717, height: 728), layout: .init(width: 717, height: 728, x: 36, y: 109, w: 667, h: 507)),
        "TopsyTurvyStage5": .init(sourceName: "RosetteClusters40Atlas", rect: CGRect(x: 717, y: 0, width: 726, height: 728), layout: .init(width: 726, height: 728, x: 15, y: 103, w: 689, h: 516)),
        "TangyuanStage5": .init(sourceName: "RosetteClusters40Atlas", rect: CGRect(x: 1443, y: 0, width: 716, height: 728), layout: .init(width: 716, height: 728, x: 24, y: 124, w: 650, h: 492)),
    ]
}
