// 30期钱串三种重绘；成年沿用用户指定的原幼年布局，按新时期尺寸显示。
import Foundation

enum Revision30AtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "BearPawCutting": .init(sourceName: "BearPawPrior30Atlas", rect: CGRect(x: 0, y: 0, width: 433, height: 605), layout: .init(width: 433, height: 605, x: 80, y: 211, w: 296, h: 307)),
        "BearPawStage0": .init(sourceName: "BearPawPrior30Atlas", rect: CGRect(x: 433, y: 0, width: 401, height: 605), layout: .init(width: 401, height: 605, x: 58, y: 154, w: 307, h: 380)),
        "BearPawStage1": .init(sourceName: "BearPawAtlas", rect: CGRect(x: 836, y: 0, width: 418, height: 619), layout: .init(width: 418, height: 619, x: 79, y: 187, w: 269, h: 338)),
        "BearPawStage2": .init(sourceName: "BearPawPrior30Atlas", rect: CGRect(x: 834, y: 0, width: 420, height: 605), layout: .init(width: 420, height: 605, x: 37, y: 151, w: 330, h: 383)),
        "BearPawStage3": .init(sourceName: "BearPawAtlas", rect: CGRect(x: 403, y: 619, width: 424, height: 635), layout: .init(width: 424, height: 635, x: 21, y: 112, w: 396, h: 393)),
        "BearPawStage4": .init(sourceName: "BearPawAtlas", rect: CGRect(x: 827, y: 619, width: 427, height: 635), layout: .init(width: 427, height: 635, x: 9, y: 96, w: 415, h: 411)),
        "DeerAntlerCutting": .init(sourceName: "DeerAntlerPrior30Atlas", rect: CGRect(x: 0, y: 0, width: 412, height: 623), layout: .init(width: 412, height: 623, x: 95, y: 186, w: 238, h: 318)),
        "DeerAntlerStage0": .init(sourceName: "DeerAntlerPrior30Atlas", rect: CGRect(x: 412, y: 0, width: 416, height: 623), layout: .init(width: 416, height: 623, x: 80, y: 154, w: 277, h: 372)),
        "DeerAntlerStage1": .init(sourceName: "DeerAntlerAtlas", rect: CGRect(x: 835, y: 0, width: 419, height: 634), layout: .init(width: 419, height: 634, x: 136, y: 210, w: 210, h: 333)),
        "DeerAntlerStage2": .init(sourceName: "DeerAntlerPrior30Atlas", rect: CGRect(x: 828, y: 0, width: 426, height: 623), layout: .init(width: 426, height: 623, x: 59, y: 199, w: 342, h: 324)),
        "DeerAntlerStage3": .init(sourceName: "DeerAntlerAtlas", rect: CGRect(x: 383, y: 634, width: 444, height: 620), layout: .init(width: 444, height: 620, x: 47, y: 82, w: 375, h: 371)),
        "DeerAntlerStage4": .init(sourceName: "DeerAntlerAtlas", rect: CGRect(x: 827, y: 634, width: 427, height: 620), layout: .init(width: 427, height: 620, x: 23, y: 84, w: 401, h: 401)),
        "MoneyStackCutting": .init(sourceName: "MoneyStackPrior30Atlas", rect: CGRect(x: 0, y: 0, width: 422, height: 637), layout: .init(width: 422, height: 637, x: 127, y: 197, w: 196, h: 330)),
        "MoneyStackStage0": .init(sourceName: "MoneyStackPrior30Atlas", rect: CGRect(x: 422, y: 0, width: 364, height: 637), layout: .init(width: 364, height: 637, x: 112, y: 154, w: 187, h: 395)),
        "MoneyStackStage1": .init(sourceName: "MoneyStackAtlas", rect: CGRect(x: 835, y: 0, width: 419, height: 610), layout: .init(width: 419, height: 610, x: 129, y: 134, w: 139, h: 397)),
        "MoneyStackStage2": .init(sourceName: "MoneyStackPrior30Atlas", rect: CGRect(x: 786, y: 0, width: 468, height: 637), layout: .init(width: 468, height: 637, x: 55, y: 154, w: 379, h: 407)),
        "MoneyStackStage3": .init(sourceName: "MoneyStackAtlas", rect: CGRect(x: 437, y: 610, width: 367, height: 644), layout: .init(width: 367, height: 644, x: 11, y: 87, w: 355, h: 455)),
        "MoneyStackStage4": .init(sourceName: "MoneyStackAtlas", rect: CGRect(x: 804, y: 610, width: 450, height: 644), layout: .init(width: 450, height: 644, x: 2, y: 81, w: 439, h: 464)),
    ]
}
