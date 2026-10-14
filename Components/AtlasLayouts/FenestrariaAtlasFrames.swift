// 五十铃玉五期共用原始透明图集；小苗帧也用于免费繁殖材料。
import Foundation

enum FenestrariaAtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "FenestrariaStage0": .init(sourceName: "FenestrariaAtlas", rect: CGRect(x: 0, y: 0, width: 300, height: 724), layout: .init(width: 300, height: 724, x: 53, y: 389, w: 198, h: 193)),
        "FenestrariaStage1": .init(sourceName: "FenestrariaAtlas", rect: CGRect(x: 300, y: 0, width: 360, height: 724), layout: .init(width: 360, height: 724, x: 59, y: 341, w: 261, h: 237)),
        "FenestrariaStage2": .init(sourceName: "FenestrariaAtlas", rect: CGRect(x: 660, y: 0, width: 430, height: 724), layout: .init(width: 430, height: 724, x: 45, y: 253, w: 357, h: 325)),
        "FenestrariaStage3": .init(sourceName: "FenestrariaAtlas", rect: CGRect(x: 1090, y: 0, width: 510, height: 724), layout: .init(width: 510, height: 724, x: 36, y: 216, w: 447, h: 363)),
        "FenestrariaStage4": .init(sourceName: "FenestrariaAtlas", rect: CGRect(x: 1600, y: 0, width: 572, height: 724), layout: .init(width: 572, height: 724, x: 25, y: 197, w: 513, h: 394)),
    ]
}
