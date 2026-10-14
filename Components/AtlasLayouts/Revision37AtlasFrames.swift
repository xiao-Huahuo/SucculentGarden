// 用户选中的第一批原图；取帧与轮廓仅用于视图布局，源PNG保持原字节。
import Foundation

enum Revision37AtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "CheeseLeaf": .init(sourceName: "CheeseAtlas", rect: CGRect(x: 0, y: 0, width: 454, height: 367), layout: .init(width: 454, height: 367, x: 151, y: 146, w: 188, h: 153)),
        "CheeseStage0": .init(sourceName: "CheeseAtlas", rect: CGRect(x: 454, y: 0, width: 439, height: 367), layout: .init(width: 439, height: 367, x: 80, y: 162, w: 244, h: 143)),
        "CheeseStage1": .init(sourceName: "CheeseAtlas", rect: CGRect(x: 893, y: 0, width: 419, height: 367), layout: .init(width: 419, height: 367, x: 83, y: 108, w: 253, h: 215)),
        "CheeseStage2": .init(sourceName: "CheeseAtlas", rect: CGRect(x: 0, y: 367, width: 454, height: 411), layout: .init(width: 454, height: 411, x: 68, y: 90, w: 318, h: 252)),
        "CheeseStage3": .init(sourceName: "CheeseAtlas", rect: CGRect(x: 454, y: 367, width: 439, height: 411), layout: .init(width: 439, height: 411, x: 28, y: 76, w: 374, h: 288)),
        "CheeseStage4": .init(sourceName: "CheeseAtlas", rect: CGRect(x: 893, y: 367, width: 419, height: 411), layout: .init(width: 419, height: 411, x: 39, y: 44, w: 345, h: 336, rootMinX: 195, rootMaxX: 224)),
        "CheeseStage5": .init(sourceName: "CheeseAtlas", rect: CGRect(x: 0, y: 778, width: 454, height: 421), layout: .init(width: 454, height: 421, x: 60, y: 31, w: 366, h: 338, rootMinX: 228, rootMaxX: 254)),
        "TopsyTurvyLeaf": .init(sourceName: "TopsyTurvyAtlas", rect: CGRect(x: 0, y: 0, width: 416, height: 397), layout: .init(width: 416, height: 397, x: 60, y: 132, w: 286, h: 207)),
        "TopsyTurvyStage0": .init(sourceName: "TopsyTurvyAtlas", rect: CGRect(x: 416, y: 0, width: 433, height: 397), layout: .init(width: 433, height: 397, x: 50, y: 140, w: 308, h: 209)),
        "TopsyTurvyStage1": .init(sourceName: "TopsyTurvyAtlas", rect: CGRect(x: 849, y: 0, width: 373, height: 397), layout: .init(width: 373, height: 397, x: 37, y: 110, w: 281, h: 237)),
        "TopsyTurvyStage2": .init(sourceName: "TopsyTurvyAtlas", rect: CGRect(x: 0, y: 397, width: 416, height: 437), layout: .init(width: 416, height: 437, x: 47, y: 123, w: 332, h: 259)),
        "TopsyTurvyStage3": .init(sourceName: "TopsyTurvyAtlas", rect: CGRect(x: 416, y: 397, width: 433, height: 437), layout: .init(width: 433, height: 437, x: 15, y: 70, w: 392, h: 321)),
        "TopsyTurvyStage4": .init(sourceName: "TopsyTurvyAtlas", rect: CGRect(x: 849, y: 397, width: 373, height: 437), layout: .init(width: 373, height: 437, x: 27, y: 49, w: 323, h: 342, rootMinX: 179, rootMaxX: 202)),
        "TopsyTurvyStage5": .init(sourceName: "TopsyTurvyAtlas", rect: CGRect(x: 0, y: 834, width: 416, height: 453), layout: .init(width: 416, height: 453, x: 32, y: 47, w: 369, h: 335, rootMinX: 196, rootMaxX: 244)),
        "TangyuanLeaf": .init(sourceName: "TangyuanAtlas", rect: CGRect(x: 0, y: 0, width: 428, height: 387), layout: .init(width: 428, height: 387, x: 121, y: 168, w: 167, h: 147)),
        "TangyuanStage0": .init(sourceName: "TangyuanAtlas", rect: CGRect(x: 428, y: 0, width: 409, height: 387), layout: .init(width: 409, height: 387, x: 44, y: 143, w: 267, h: 179)),
        "TangyuanStage1": .init(sourceName: "TangyuanAtlas", rect: CGRect(x: 837, y: 0, width: 389, height: 387), layout: .init(width: 389, height: 387, x: 64, y: 126, w: 245, h: 200)),
        "TangyuanStage2": .init(sourceName: "TangyuanAtlas", rect: CGRect(x: 0, y: 387, width: 428, height: 430), layout: .init(width: 428, height: 430, x: 37, y: 106, w: 318, h: 259)),
        "TangyuanStage3": .init(sourceName: "TangyuanAtlas", rect: CGRect(x: 428, y: 387, width: 409, height: 430), layout: .init(width: 409, height: 430, x: 10, y: 74, w: 364, h: 305)),
        "TangyuanStage4": .init(sourceName: "TangyuanAtlas", rect: CGRect(x: 837, y: 387, width: 389, height: 430), layout: .init(width: 389, height: 430, x: 36, y: 63, w: 314, h: 316, rootMinX: 183, rootMaxX: 207)),
        "TangyuanStage5": .init(sourceName: "TangyuanAtlas", rect: CGRect(x: 0, y: 817, width: 428, height: 466), layout: .init(width: 428, height: 466, x: 24, y: 52, w: 395, h: 333, rootMinX: 204, rootMaxX: 232)),
    ]
}
