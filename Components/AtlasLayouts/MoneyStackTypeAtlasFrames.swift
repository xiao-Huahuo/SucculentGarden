// 从透明间隙测得的取帧与轮廓范围；只作运行时取景，不改写原图。
import Foundation

enum MoneyStackTypeAtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "MoneyStackCutting": .init(sourceName: "MoneyStackAtlas", rect: CGRect(x: 0, y: 0, width: 424, height: 640), layout: .init(width: 424, height: 640, x: 131, y: 202, w: 195, h: 328)),
        "MoneyStackStage0": .init(sourceName: "MoneyStackAtlas", rect: CGRect(x: 424, y: 0, width: 364, height: 640), layout: .init(width: 364, height: 640, x: 106, y: 161, w: 192, h: 384)),
        "MoneyStackStage1": .init(sourceName: "MoneyStackAtlas", rect: CGRect(x: 788, y: 0, width: 466, height: 640), layout: .init(width: 466, height: 640, x: 56, y: 155, w: 370, h: 405)),
        "MoneyStackStage2": .init(sourceName: "MoneyStackAtlas", rect: CGRect(x: 0, y: 640, width: 406, height: 614), layout: .init(width: 406, height: 614, x: 34, y: 86, w: 357, h: 404)),
        "MoneyStackStage3": .init(sourceName: "MoneyStackAtlas", rect: CGRect(x: 406, y: 640, width: 496, height: 614), layout: .init(width: 496, height: 614, x: 16, y: 80, w: 443, h: 417)),
        "DeerAntlerCutting": .init(sourceName: "DeerAntlerAtlas", rect: CGRect(x: 0, y: 0, width: 412, height: 623), layout: .init(width: 412, height: 623, x: 95, y: 186, w: 238, h: 318)),
        "DeerAntlerStage0": .init(sourceName: "DeerAntlerAtlas", rect: CGRect(x: 412, y: 0, width: 416, height: 623), layout: .init(width: 416, height: 623, x: 80, y: 154, w: 277, h: 372)),
        "DeerAntlerStage1": .init(sourceName: "DeerAntlerAtlas", rect: CGRect(x: 828, y: 0, width: 426, height: 623), layout: .init(width: 426, height: 623, x: 59, y: 199, w: 342, h: 324)),
        "DeerAntlerStage2": .init(sourceName: "DeerAntlerAtlas", rect: CGRect(x: 0, y: 623, width: 414, height: 631), layout: .init(width: 414, height: 631, x: 38, y: 118, w: 356, h: 358)),
        "DeerAntlerStage3": .init(sourceName: "DeerAntlerAtlas", rect: CGRect(x: 414, y: 623, width: 474, height: 631), layout: .init(width: 474, height: 631, x: 21, y: 98, w: 401, h: 397)),
        "BearPawCutting": .init(sourceName: "BearPawAtlas", rect: CGRect(x: 0, y: 0, width: 433, height: 605), layout: .init(width: 433, height: 605, x: 80, y: 211, w: 296, h: 307)),
        "BearPawStage0": .init(sourceName: "BearPawAtlas", rect: CGRect(x: 433, y: 0, width: 401, height: 605), layout: .init(width: 401, height: 605, x: 58, y: 154, w: 307, h: 380)),
        "BearPawStage1": .init(sourceName: "BearPawAtlas", rect: CGRect(x: 834, y: 0, width: 420, height: 605), layout: .init(width: 420, height: 605, x: 37, y: 151, w: 330, h: 383)),
        "BearPawStage2": .init(sourceName: "BearPawAtlas", rect: CGRect(x: 0, y: 605, width: 420, height: 649), layout: .init(width: 420, height: 649, x: 39, y: 109, w: 368, h: 369)),
        "BearPawStage3": .init(sourceName: "BearPawAtlas", rect: CGRect(x: 420, y: 605, width: 476, height: 649), layout: .init(width: 476, height: 649, x: 13, y: 71, w: 419, h: 414)),
    ]
}
