// 从透明间隙测得的取帧与轮廓范围；只作运行时取景，不改写原图。
import Foundation

enum CactusTypeAtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "FortuneHandStage0": .init(sourceName: "FortuneHandAtlas", rect: CGRect(x: 0, y: 0, width: 393, height: 650), layout: .init(width: 393, height: 650, x: 129, y: 317, w: 158, h: 249)),
        "FortuneHandStage1": .init(sourceName: "FortuneHandAtlas", rect: CGRect(x: 393, y: 0, width: 393, height: 650), layout: .init(width: 393, height: 650, x: 79, y: 171, w: 266, h: 406)),
        "FortuneHandStage2": .init(sourceName: "FortuneHandAtlas", rect: CGRect(x: 786, y: 0, width: 468, height: 650), layout: .init(width: 468, height: 650, x: 49, y: 85, w: 363, h: 499)),
        "FortuneHandStage3": .init(sourceName: "FortuneHandAtlas", rect: CGRect(x: 0, y: 650, width: 405, height: 604), layout: .init(width: 405, height: 604, x: 67, y: 91, w: 304, h: 406)),
        "FortuneHandStage4": .init(sourceName: "FortuneHandAtlas", rect: CGRect(x: 405, y: 650, width: 480, height: 604), layout: .init(width: 480, height: 604, x: 35, y: 66, w: 391, h: 426)),
        "SmallCactusBallStage0": .init(sourceName: "SmallCactusBallAtlas", rect: CGRect(x: 0, y: 0, width: 394, height: 620), layout: .init(width: 394, height: 620, x: 128, y: 306, w: 190, h: 180)),
        "SmallCactusBallStage1": .init(sourceName: "SmallCactusBallAtlas", rect: CGRect(x: 394, y: 0, width: 421, height: 620), layout: .init(width: 421, height: 620, x: 76, y: 201, w: 308, h: 305)),
        "SmallCactusBallStage2": .init(sourceName: "SmallCactusBallAtlas", rect: CGRect(x: 815, y: 0, width: 439, height: 620), layout: .init(width: 439, height: 620, x: 37, y: 147, w: 375, h: 367)),
        "SmallCactusBallStage3": .init(sourceName: "SmallCactusBallAtlas", rect: CGRect(x: 0, y: 620, width: 411, height: 634), layout: .init(width: 411, height: 634, x: 51, y: 150, w: 344, h: 265)),
        "SmallCactusBallStage4": .init(sourceName: "SmallCactusBallAtlas", rect: CGRect(x: 411, y: 620, width: 472, height: 634), layout: .init(width: 472, height: 634, x: 17, y: 107, w: 399, h: 350)),
        "FairyCastleStage0": .init(sourceName: "FairyCastleAtlas", rect: CGRect(x: 0, y: 0, width: 400, height: 629), layout: .init(width: 400, height: 629, x: 133, y: 273, w: 181, h: 249)),
        "FairyCastleStage1": .init(sourceName: "FairyCastleAtlas", rect: CGRect(x: 400, y: 0, width: 396, height: 629), layout: .init(width: 396, height: 629, x: 87, y: 164, w: 256, h: 389)),
        "FairyCastleStage2": .init(sourceName: "FairyCastleAtlas", rect: CGRect(x: 796, y: 0, width: 458, height: 629), layout: .init(width: 458, height: 629, x: 53, y: 51, w: 348, h: 530)),
        "FairyCastleStage3": .init(sourceName: "FairyCastleAtlas", rect: CGRect(x: 0, y: 629, width: 412, height: 625), layout: .init(width: 412, height: 625, x: 73, y: 63, w: 295, h: 471)),
        "FairyCastleStage4": .init(sourceName: "FairyCastleAtlas", rect: CGRect(x: 412, y: 629, width: 469, height: 625), layout: .init(width: 469, height: 625, x: 44, y: 49, w: 366, h: 475)),
        "GoldFingerStage0": .init(sourceName: "GoldFingerAtlas", rect: CGRect(x: 0, y: 0, width: 418, height: 619), layout: .init(width: 418, height: 619, x: 127, y: 284, w: 184, h: 216)),
        "GoldFingerStage1": .init(sourceName: "GoldFingerAtlas", rect: CGRect(x: 418, y: 0, width: 371, height: 619), layout: .init(width: 371, height: 619, x: 120, y: 184, w: 176, h: 330)),
        "GoldFingerStage2": .init(sourceName: "GoldFingerAtlas", rect: CGRect(x: 789, y: 0, width: 465, height: 619), layout: .init(width: 465, height: 619, x: 58, y: 121, w: 372, h: 425)),
        "GoldFingerStage3": .init(sourceName: "GoldFingerAtlas", rect: CGRect(x: 0, y: 619, width: 409, height: 635), layout: .init(width: 409, height: 635, x: 63, y: 104, w: 323, h: 399)),
        "GoldFingerStage4": .init(sourceName: "GoldFingerAtlas", rect: CGRect(x: 409, y: 619, width: 472, height: 635), layout: .init(width: 472, height: 635, x: 24, y: 74, w: 389, h: 430)),
        "WhiteBirdStage0": .init(sourceName: "WhiteBirdAtlas", rect: CGRect(x: 0, y: 0, width: 408, height: 655), layout: .init(width: 408, height: 655, x: 151, y: 386, w: 187, h: 186)),
        "WhiteBirdStage1": .init(sourceName: "WhiteBirdAtlas", rect: CGRect(x: 408, y: 0, width: 395, height: 655), layout: .init(width: 395, height: 655, x: 71, y: 306, w: 294, h: 297)),
        "WhiteBirdStage2": .init(sourceName: "WhiteBirdAtlas", rect: CGRect(x: 803, y: 0, width: 451, height: 655), layout: .init(width: 451, height: 655, x: 31, y: 266, w: 372, h: 360)),
        "WhiteBirdStage3": .init(sourceName: "WhiteBirdAtlas", rect: CGRect(x: 0, y: 655, width: 421, height: 599), layout: .init(width: 421, height: 599, x: 91, y: 71, w: 301, h: 297)),
        "WhiteBirdStage4": .init(sourceName: "WhiteBirdAtlas", rect: CGRect(x: 421, y: 655, width: 455, height: 599), layout: .init(width: 455, height: 599, x: 30, y: 30, w: 362, h: 348)),
        "NineTailFoxStage0": .init(sourceName: "NineTailFoxAtlas", rect: CGRect(x: 0, y: 0, width: 392, height: 636), layout: .init(width: 392, height: 636, x: 115, y: 251, w: 197, h: 278)),
        "NineTailFoxStage1": .init(sourceName: "NineTailFoxAtlas", rect: CGRect(x: 392, y: 0, width: 413, height: 636), layout: .init(width: 413, height: 636, x: 79, y: 153, w: 275, h: 382)),
        "NineTailFoxStage2": .init(sourceName: "NineTailFoxAtlas", rect: CGRect(x: 805, y: 0, width: 449, height: 636), layout: .init(width: 449, height: 636, x: 60, y: 97, w: 344, h: 496)),
        "NineTailFoxStage3": .init(sourceName: "NineTailFoxAtlas", rect: CGRect(x: 0, y: 636, width: 408, height: 618), layout: .init(width: 408, height: 618, x: 40, y: 64, w: 344, h: 459, anchorY: 357.76)),
        "NineTailFoxStage4": .init(sourceName: "NineTailFoxAtlas", rect: CGRect(x: 408, y: 636, width: 472, height: 618), layout: .init(width: 472, height: 618, x: 25, y: 43, w: 388, h: 486, anchorY: 354.04)),
    ]
}
