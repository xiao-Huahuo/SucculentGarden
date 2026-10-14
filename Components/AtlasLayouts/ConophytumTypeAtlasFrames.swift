// 从透明间隙测得的取帧与轮廓范围；只作运行时取景，不改写原图。
import Foundation

enum ConophytumTypeAtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "MaughaniiStage0": .init(sourceName: "MaughaniiAtlas", rect: CGRect(x: 0, y: 0, width: 418, height: 628), layout: .init(width: 418, height: 628, x: 204, y: 368, w: 50, h: 53)),
        "MaughaniiStage1": .init(sourceName: "MaughaniiAtlas", rect: CGRect(x: 418, y: 0, width: 403, height: 628), layout: .init(width: 403, height: 628, x: 137, y: 328, w: 140, h: 127)),
        "MaughaniiStage2": .init(sourceName: "MaughaniiAtlas", rect: CGRect(x: 821, y: 0, width: 433, height: 628), layout: .init(width: 433, height: 628, x: 90, y: 256, w: 238, h: 220)),
        "MaughaniiStage3": .init(sourceName: "MaughaniiAtlas", rect: CGRect(x: 0, y: 628, width: 430, height: 626), layout: .init(width: 430, height: 626, x: 89, y: 157, w: 282, h: 259)),
        "MaughaniiStage4": .init(sourceName: "MaughaniiAtlas", rect: CGRect(x: 430, y: 628, width: 429, height: 626), layout: .init(width: 429, height: 626, x: 60, y: 152, w: 289, h: 276)),
        "SplitRockStage0": .init(sourceName: "SplitRockAtlas", rect: CGRect(x: 0, y: 0, width: 418, height: 655), layout: .init(width: 418, height: 655, x: 194, y: 408, w: 61, h: 60)),
        "SplitRockStage1": .init(sourceName: "SplitRockAtlas", rect: CGRect(x: 418, y: 0, width: 402, height: 655), layout: .init(width: 402, height: 655, x: 141, y: 392, w: 141, h: 120)),
        "SplitRockStage2": .init(sourceName: "SplitRockAtlas", rect: CGRect(x: 820, y: 0, width: 434, height: 655), layout: .init(width: 434, height: 655, x: 89, y: 335, w: 236, h: 198)),
        "SplitRockStage3": .init(sourceName: "SplitRockAtlas", rect: CGRect(x: 0, y: 655, width: 435, height: 599), layout: .init(width: 435, height: 599, x: 67, y: 122, w: 320, h: 258)),
        "SplitRockStage4": .init(sourceName: "SplitRockAtlas", rect: CGRect(x: 435, y: 655, width: 427, height: 599), layout: .init(width: 427, height: 599, x: 48, y: 131, w: 302, h: 252)),
    ]
}
