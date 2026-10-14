// 只替换千佛手成年以后与白月影幼年以后的形态；叶片及更早期沿用原图。
import Foundation

enum Revision43AtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "ThousandBuddhaStage2": .init(sourceName: "ThousandBuddha43Atlas", rect: CGRect(x: 0, y: 0, width: 435, height: 768), layout: .init(width: 435, height: 768, x: 121, y: 146, w: 237, h: 550, rootMinX: 224, rootMaxX: 269)),
        "ThousandBuddhaStage3": .init(sourceName: "ThousandBuddha43Atlas", rect: CGRect(x: 435, y: 0, width: 385, height: 768), layout: .init(width: 385, height: 768, x: 64, y: 33, w: 267, h: 679, rootMinX: 175, rootMaxX: 229)),
        "ThousandBuddhaStage4": .init(sourceName: "ThousandBuddha43Atlas", rect: CGRect(x: 820, y: 0, width: 600, height: 768), layout: .init(width: 600, height: 768, x: 60, y: 88, w: 529, h: 635, anchorY: 699, rootMinX: 125, rootMaxX: 171)),
        "ThousandBuddhaStage5": .init(sourceName: "ThousandBuddha43Atlas", rect: CGRect(x: 1420, y: 0, width: 628, height: 768), layout: .init(width: 628, height: 768, x: 24, y: 61, w: 571, h: 654, anchorY: 699, rootMinX: 220, rootMaxX: 278)),
        "WhiteMoonStage1": .init(sourceName: "WhiteMoon43Atlas", rect: CGRect(x: 0, y: 0, width: 340, height: 724), layout: .init(width: 340, height: 724, x: 32, y: 284, w: 297, h: 292)),
        "WhiteMoonStage2": .init(sourceName: "WhiteMoon43Atlas", rect: CGRect(x: 340, y: 0, width: 410, height: 724), layout: .init(width: 410, height: 724, x: 17, y: 199, w: 384, h: 375)),
        "WhiteMoonStage3": .init(sourceName: "WhiteMoon43Atlas", rect: CGRect(x: 750, y: 0, width: 500, height: 724), layout: .init(width: 500, height: 724, x: 13, y: 120, w: 476, h: 465)),
        "WhiteMoonStage4": .init(sourceName: "WhiteMoon43Atlas", rect: CGRect(x: 1250, y: 0, width: 435, height: 724), layout: .init(width: 435, height: 724, x: 10, y: 101, w: 417, h: 517, rootMinX: 173, rootMaxX: 268)),
        "WhiteMoonStage5": .init(sourceName: "WhiteMoon43Atlas", rect: CGRect(x: 1685, y: 0, width: 487, height: 724), layout: .init(width: 487, height: 724, x: 4, y: 149, w: 458, h: 423)),
    ]
}
