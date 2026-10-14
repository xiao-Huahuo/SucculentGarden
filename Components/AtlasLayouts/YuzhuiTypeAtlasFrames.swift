// 从透明间隙测得的取帧与轮廓范围；只作运行时取景，不改写原图。
import Foundation

enum YuzhuiTypeAtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "FireFestivalLeaf": .init(sourceName: "FireFestivalAtlas", rect: CGRect(x: 0, y: 0, width: 426, height: 612), layout: .init(width: 426, height: 612, x: 108, y: 258, w: 272, h: 289)),
        "FireFestivalStage0": .init(sourceName: "FireFestivalAtlas", rect: CGRect(x: 426, y: 0, width: 427, height: 612), layout: .init(width: 427, height: 612, x: 47, y: 271, w: 311, h: 277)),
        "FireFestivalStage1": .init(sourceName: "FireFestivalAtlas", rect: CGRect(x: 853, y: 0, width: 401, height: 612), layout: .init(width: 401, height: 612, x: 69, y: 185, w: 263, h: 382)),
        "FireFestivalStage2": .init(sourceName: "FireFestivalAtlas", rect: CGRect(x: 0, y: 612, width: 417, height: 642), layout: .init(width: 417, height: 642, x: 61, y: 162, w: 329, h: 320)),
        "FireFestivalStage3": .init(sourceName: "FireFestivalAtlas", rect: CGRect(x: 417, y: 612, width: 416, height: 642), layout: .init(width: 416, height: 642, x: 28, y: 86, w: 366, h: 410)),
        "FireFestivalStage4": .init(sourceName: "FireFestivalAtlas", rect: CGRect(x: 833, y: 612, width: 421, height: 642), layout: .init(width: 421, height: 642, x: 23, y: 45, w: 376, h: 446)),
        "GollumJadeLeaf": .init(sourceName: "GollumJadeAtlas", rect: CGRect(x: 0, y: 0, width: 430, height: 617), layout: .init(width: 430, height: 617, x: 122, y: 269, w: 260, h: 260)),
        "GollumJadeStage0": .init(sourceName: "GollumJadeAtlas", rect: CGRect(x: 430, y: 0, width: 411, height: 617), layout: .init(width: 411, height: 617, x: 49, y: 287, w: 308, h: 237)),
        "GollumJadeStage1": .init(sourceName: "GollumJadeAtlas", rect: CGRect(x: 841, y: 0, width: 413, height: 617), layout: .init(width: 413, height: 617, x: 55, y: 239, w: 265, h: 309)),
        "GollumJadeStage2": .init(sourceName: "GollumJadeAtlas", rect: CGRect(x: 0, y: 617, width: 416, height: 637), layout: .init(width: 416, height: 637, x: 59, y: 127, w: 320, h: 312)),
        "GollumJadeStage3": .init(sourceName: "GollumJadeAtlas", rect: CGRect(x: 416, y: 617, width: 398, height: 637), layout: .init(width: 398, height: 637, x: 37, y: 100, w: 333, h: 340)),
        "GollumJadeStage4": .init(sourceName: "GollumJadeAtlas", rect: CGRect(x: 814, y: 617, width: 440, height: 637), layout: .init(width: 440, height: 637, x: 29, y: 70, w: 374, h: 376)),
    ]
}
