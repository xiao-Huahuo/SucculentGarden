// 从透明间隙测得的取帧与轮廓范围；只作运行时取景，不改写原图。
import Foundation

enum StonecropTypeAtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "BlueChalkCutting": .init(sourceName: "BlueChalkAtlas", rect: CGRect(x: 0, y: 0, width: 434, height: 644), layout: .init(width: 434, height: 644, x: 106, y: 149, w: 240, h: 407)),
        "BlueChalkStage0": .init(sourceName: "BlueChalkAtlas", rect: CGRect(x: 434, y: 0, width: 365, height: 644), layout: .init(width: 365, height: 644, x: 114, y: 207, w: 153, h: 336)),
        "BlueChalkStage1": .init(sourceName: "BlueChalkAtlas", rect: CGRect(x: 799, y: 0, width: 455, height: 644), layout: .init(width: 455, height: 644, x: 67, y: 161, w: 362, h: 403)),
        "BlueChalkStage2": .init(sourceName: "BlueChalkAtlas", rect: CGRect(x: 0, y: 644, width: 412, height: 610), layout: .init(width: 412, height: 610, x: 57, y: 125, w: 326, h: 357)),
        "BlueChalkStage3": .init(sourceName: "BlueChalkAtlas", rect: CGRect(x: 412, y: 644, width: 470, height: 610), layout: .init(width: 470, height: 610, x: 29, y: 80, w: 384, h: 417)),
        "BallPineCutting": .init(sourceName: "BallPineAtlas", rect: CGRect(x: 0, y: 0, width: 434, height: 660), layout: .init(width: 434, height: 660, x: 113, y: 239, w: 233, h: 326)),
        "BallPineStage0": .init(sourceName: "BallPineAtlas", rect: CGRect(x: 434, y: 0, width: 357, height: 660), layout: .init(width: 357, height: 660, x: 116, y: 290, w: 156, h: 278)),
        "BallPineStage1": .init(sourceName: "BallPineAtlas", rect: CGRect(x: 791, y: 0, width: 463, height: 660), layout: .init(width: 463, height: 660, x: 60, y: 192, w: 353, h: 399)),
        "BallPineStage2": .init(sourceName: "BallPineAtlas", rect: CGRect(x: 0, y: 660, width: 411, height: 594), layout: .init(width: 411, height: 594, x: 60, y: 88, w: 327, h: 345)),
        "BallPineStage3": .init(sourceName: "BallPineAtlas", rect: CGRect(x: 411, y: 660, width: 479, height: 594), layout: .init(width: 479, height: 594, x: 25, y: 70, w: 405, h: 379)),
    ]
}
