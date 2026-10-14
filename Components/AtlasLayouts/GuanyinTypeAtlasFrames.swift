// 从透明间隙测得的取帧与轮廓范围；只作运行时取景，不改写原图。
import Foundation

enum GuanyinTypeAtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "MountainRoseStage0": .init(sourceName: "MountainRoseAtlas", rect: CGRect(x: 0, y: 0, width: 400, height: 635), layout: .init(width: 400, height: 635, x: 112, y: 251, w: 211, h: 265)),
        "MountainRoseStage1": .init(sourceName: "MountainRoseAtlas", rect: CGRect(x: 400, y: 0, width: 404, height: 635), layout: .init(width: 404, height: 635, x: 77, y: 229, w: 281, h: 279)),
        "MountainRoseStage2": .init(sourceName: "MountainRoseAtlas", rect: CGRect(x: 804, y: 0, width: 450, height: 635), layout: .init(width: 450, height: 635, x: 47, y: 202, w: 357, h: 334)),
        "MountainRoseStage3": .init(sourceName: "MountainRoseAtlas", rect: CGRect(x: 0, y: 635, width: 425, height: 619), layout: .init(width: 425, height: 619, x: 60, y: 99, w: 341, h: 334)),
        "MountainRoseStage4": .init(sourceName: "MountainRoseAtlas", rect: CGRect(x: 425, y: 635, width: 447, height: 619), layout: .init(width: 447, height: 619, x: 25, y: 135, w: 355, h: 284, anchorY: 376.40)),
        "CobwebHouseleekStage0": .init(sourceName: "CobwebHouseleekAtlas", rect: CGRect(x: 0, y: 0, width: 401, height: 646), layout: .init(width: 401, height: 646, x: 104, y: 265, w: 229, h: 264)),
        "CobwebHouseleekStage1": .init(sourceName: "CobwebHouseleekAtlas", rect: CGRect(x: 401, y: 0, width: 401, height: 646), layout: .init(width: 401, height: 646, x: 69, y: 242, w: 298, h: 291)),
        "CobwebHouseleekStage2": .init(sourceName: "CobwebHouseleekAtlas", rect: CGRect(x: 802, y: 0, width: 452, height: 646), layout: .init(width: 452, height: 646, x: 35, y: 208, w: 395, h: 341)),
        "CobwebHouseleekStage3": .init(sourceName: "CobwebHouseleekAtlas", rect: CGRect(x: 0, y: 646, width: 429, height: 608), layout: .init(width: 429, height: 608, x: 48, y: 98, w: 366, h: 336)),
        "CobwebHouseleekStage4": .init(sourceName: "CobwebHouseleekAtlas", rect: CGRect(x: 429, y: 646, width: 450, height: 608), layout: .init(width: 450, height: 608, x: 16, y: 110, w: 374, h: 323, anchorY: 384.55)),
    ]
}
