// 从透明间隙测得的取帧与轮廓范围；只作运行时取景，不改写原图。
import Foundation

enum MotherOfThousandsTypeAtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "BroadMotherBud": .init(sourceName: "BroadMotherAtlas", rect: CGRect(x: 0, y: 0, width: 405, height: 412), layout: .init(width: 405, height: 412, x: 121, y: 184, w: 179, h: 188)),
        "BroadMotherStage0": .init(sourceName: "BroadMotherAtlas", rect: CGRect(x: 405, y: 0, width: 415, height: 412), layout: .init(width: 415, height: 412, x: 92, y: 176, w: 260, h: 216)),
        "BroadMotherStage1": .init(sourceName: "BroadMotherAtlas", rect: CGRect(x: 820, y: 0, width: 434, height: 412), layout: .init(width: 434, height: 412, x: 64, y: 64, w: 323, h: 328)),
        "BroadMotherStage2": .init(sourceName: "BroadMotherAtlas", rect: CGRect(x: 0, y: 412, width: 424, height: 407), layout: .init(width: 424, height: 407, x: 28, y: 38, w: 387, h: 350)),
        "BroadMotherStage3": .init(sourceName: "BroadMotherAtlas", rect: CGRect(x: 424, y: 412, width: 411, height: 407), layout: .init(width: 411, height: 407, x: 9, y: 21, w: 395, h: 367)),
        "BroadMotherStage4": .init(sourceName: "BroadMotherAtlas", rect: CGRect(x: 835, y: 412, width: 419, height: 407), layout: .init(width: 419, height: 407, x: 8, y: 45, w: 395, h: 354)),
        "BroadMotherStage5": .init(sourceName: "BroadMotherAtlas", rect: CGRect(x: 0, y: 819, width: 485, height: 435), layout: .init(width: 485, height: 435, x: 27, y: 9, w: 422, h: 385)),
        "TubeMotherBud": .init(sourceName: "TubeMotherAtlas", rect: CGRect(x: 0, y: 0, width: 425, height: 420), layout: .init(width: 425, height: 420, x: 161, y: 204, w: 167, h: 156)),
        "TubeMotherStage0": .init(sourceName: "TubeMotherAtlas", rect: CGRect(x: 425, y: 0, width: 391, height: 420), layout: .init(width: 391, height: 420, x: 108, y: 178, w: 203, h: 203)),
        "TubeMotherStage1": .init(sourceName: "TubeMotherAtlas", rect: CGRect(x: 816, y: 0, width: 438, height: 420), layout: .init(width: 438, height: 420, x: 81, y: 97, w: 257, h: 303)),
        "TubeMotherStage2": .init(sourceName: "TubeMotherAtlas", rect: CGRect(x: 0, y: 420, width: 431, height: 401), layout: .init(width: 431, height: 401, x: 82, y: 47, w: 321, h: 321)),
        "TubeMotherStage3": .init(sourceName: "TubeMotherAtlas", rect: CGRect(x: 431, y: 420, width: 390, height: 401), layout: .init(width: 390, height: 401, x: 29, y: 21, w: 335, h: 364)),
        "TubeMotherStage4": .init(sourceName: "TubeMotherAtlas", rect: CGRect(x: 821, y: 420, width: 433, height: 401), layout: .init(width: 433, height: 401, x: 27, y: 56, w: 352, h: 313)),
        "TubeMotherStage5": .init(sourceName: "TubeMotherAtlas", rect: CGRect(x: 0, y: 821, width: 467, height: 433), layout: .init(width: 467, height: 433, x: 64, y: 17, w: 348, h: 338)),
        "NarrowMotherBud": .init(sourceName: "NarrowMotherAtlas", rect: CGRect(x: 0, y: 0, width: 410, height: 418), layout: .init(width: 410, height: 418, x: 129, y: 168, w: 178, h: 207)),
        "NarrowMotherStage0": .init(sourceName: "NarrowMotherAtlas", rect: CGRect(x: 410, y: 0, width: 445, height: 418), layout: .init(width: 445, height: 418, x: 96, y: 171, w: 265, h: 225)),
        "NarrowMotherStage1": .init(sourceName: "NarrowMotherAtlas", rect: CGRect(x: 855, y: 0, width: 399, height: 418), layout: .init(width: 399, height: 418, x: 85, y: 62, w: 255, h: 332)),
        "NarrowMotherStage2": .init(sourceName: "NarrowMotherAtlas", rect: CGRect(x: 0, y: 418, width: 420, height: 407), layout: .init(width: 420, height: 407, x: 52, y: 33, w: 336, h: 349)),
        "NarrowMotherStage3": .init(sourceName: "NarrowMotherAtlas", rect: CGRect(x: 420, y: 418, width: 413, height: 407), layout: .init(width: 413, height: 407, x: 33, y: 22, w: 365, h: 367)),
        "NarrowMotherStage4": .init(sourceName: "NarrowMotherAtlas", rect: CGRect(x: 833, y: 418, width: 421, height: 407), layout: .init(width: 421, height: 407, x: 16, y: 38, w: 377, h: 342)),
        "NarrowMotherStage5": .init(sourceName: "NarrowMotherAtlas", rect: CGRect(x: 0, y: 825, width: 468, height: 429), layout: .init(width: 468, height: 429, x: 50, y: 19, w: 365, h: 348)),
    ]
}
