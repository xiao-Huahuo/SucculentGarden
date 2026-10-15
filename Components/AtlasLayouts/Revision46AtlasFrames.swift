// 自然树形、固定单叶尺度、空间螺旋与俯视红土盆；仅运行时取帧，原始PNG不改。
import Foundation

enum Revision46AtlasFrames {
    static let frames: [String: SucculentAtlasFrame] = [
        "ElephantBushCutting": .init(sourceName: "ElephantBush46Atlas", rect: CGRect(x: 0, y: 0, width: 209, height: 724), layout: .init(width: 209, height: 724, x: 54, y: 555, w: 98, h: 127, rootMinX: 95, rootMaxX: 110, leafLength: 50)),
        "ElephantBushStage0": .init(sourceName: "ElephantBush46Atlas", rect: CGRect(x: 152, y: 0, width: 251, height: 724), layout: .init(width: 251, height: 724, x: 57, y: 505, w: 110, h: 177, rootMinX: 118, rootMaxX: 136, leafLength: 49)),
        "ElephantBushStage1": .init(sourceName: "ElephantBush46Atlas", rect: CGRect(x: 319, y: 0, width: 381, height: 724), layout: .init(width: 381, height: 724, x: 84, y: 389, w: 269, h: 295, rootMinX: 197, rootMaxX: 218, leafLength: 35)),
        "ElephantBushStage2": .init(sourceName: "ElephantBush46Atlas", rect: CGRect(x: 672, y: 0, width: 403, height: 724), layout: .init(width: 403, height: 724, x: 28, y: 266, w: 366, h: 420, rootMinX: 194, rootMaxX: 244, leafLength: 34)),
        "ElephantBushStage3": .init(sourceName: "ElephantBush46Atlas", rect: CGRect(x: 1066, y: 0, width: 542, height: 724), layout: .init(width: 542, height: 724, x: 9, y: 68, w: 502, h: 620, rootMinX: 289, rootMaxX: 364, leafLength: 29)),
        "ElephantBushStage4": .init(sourceName: "ElephantBush46Atlas", rect: CGRect(x: 1577, y: 0, width: 595, height: 724), layout: .init(width: 595, height: 724, x: 31, y: 40, w: 536, h: 648, rootMinX: 272, rootMaxX: 384, leafLength: 27)),
        "ElephantBushRainbowCutting": .init(sourceName: "ElephantBushRainbow46Atlas", rect: CGRect(x: 0, y: 0, width: 204, height: 724), layout: .init(width: 204, height: 724, x: 32, y: 518, w: 127, h: 159, rootMinX: 99, rootMaxX: 118, leafLength: 50)),
        "ElephantBushRainbowStage0": .init(sourceName: "ElephantBushRainbow46Atlas", rect: CGRect(x: 159, y: 0, width: 220, height: 724), layout: .init(width: 220, height: 724, x: 45, y: 458, w: 133, h: 220, rootMinX: 125, rootMaxX: 147, leafLength: 49)),
        "ElephantBushRainbowStage1": .init(sourceName: "ElephantBushRainbow46Atlas", rect: CGRect(x: 337, y: 0, width: 337, height: 724), layout: .init(width: 337, height: 724, x: 42, y: 375, w: 256, h: 304, rootMinX: 159, rootMaxX: 184, leafLength: 40)),
        "ElephantBushRainbowStage2": .init(sourceName: "ElephantBushRainbow46Atlas", rect: CGRect(x: 635, y: 0, width: 443, height: 724), layout: .init(width: 443, height: 724, x: 39, y: 185, w: 403, h: 494, rootMinX: 197, rootMaxX: 251, leafLength: 33)),
        "ElephantBushRainbowStage3": .init(sourceName: "ElephantBushRainbow46Atlas", rect: CGRect(x: 1077, y: 0, width: 533, height: 724), layout: .init(width: 533, height: 724, x: 1, y: 67, w: 511, h: 614, rootMinX: 271, rootMaxX: 344, leafLength: 29)),
        "ElephantBushRainbowStage4": .init(sourceName: "ElephantBushRainbow46Atlas", rect: CGRect(x: 1589, y: 0, width: 583, height: 724), layout: .init(width: 583, height: 724, x: 21, y: 28, w: 544, h: 654, rootMinX: 286, rootMaxX: 419, leafLength: 28)),
        "JadeTreeCutting": .init(sourceName: "JadeTree46Atlas", rect: CGRect(x: 0, y: 0, width: 190, height: 724), layout: .init(width: 190, height: 724, x: 24, y: 495, w: 152, h: 166, rootMinX: 81, rootMaxX: 107, leafLength: 75)),
        "JadeTreeStage0": .init(sourceName: "JadeTree46Atlas", rect: CGRect(x: 176, y: 0, width: 223, height: 724), layout: .init(width: 223, height: 724, x: 14, y: 424, w: 180, h: 201, rootMinX: 92, rootMaxX: 119, leafLength: 72)),
        "JadeTreeStage1": .init(sourceName: "JadeTree46Atlas", rect: CGRect(x: 370, y: 0, width: 314, height: 724), layout: .init(width: 314, height: 724, x: 29, y: 293, w: 260, h: 341, rootMinX: 153, rootMaxX: 184, leafLength: 65)),
        "JadeTreeStage2": .init(sourceName: "JadeTree46Atlas", rect: CGRect(x: 659, y: 0, width: 425, height: 724), layout: .init(width: 425, height: 724, x: 25, y: 146, w: 392, h: 493, rootMinX: 209, rootMaxX: 262, leafLength: 60)),
        "JadeTreeStage3": .init(sourceName: "JadeTree46Atlas", rect: CGRect(x: 1076, y: 0, width: 494, height: 724), layout: .init(width: 494, height: 724, x: 8, y: 59, w: 481, h: 581, rootMinX: 182, rootMaxX: 243, leafLength: 48)),
        "JadeTreeStage4": .init(sourceName: "JadeTree46Atlas", rect: CGRect(x: 1565, y: 0, width: 607, height: 724), layout: .init(width: 607, height: 724, x: 5, y: 30, w: 576, h: 627, rootMinX: 271, rootMaxX: 379, leafLength: 48)),
        "SpiralGrassCutting": .init(sourceName: "SpiralGrass46Atlas", rect: CGRect(x: 0, y: 0, width: 243, height: 724), layout: .init(width: 243, height: 724, x: 65, y: 31, w: 106, h: 661, rootMinX: 65, rootMaxX: 171, leafLength: 520)),
        "SpiralGrassStage0": .init(sourceName: "SpiralGrass46Atlas", rect: CGRect(x: 171, y: 0, width: 359, height: 724), layout: .init(width: 359, height: 724, x: 72, y: 31, w: 226, h: 661, rootMinX: 144, rootMaxX: 253, leafLength: 520)),
        "SpiralGrassStage1": .init(sourceName: "SpiralGrass46Atlas", rect: CGRect(x: 469, y: 0, width: 407, height: 724), layout: .init(width: 407, height: 724, x: 61, y: 32, w: 304, h: 660, rootMinX: 167, rootMaxX: 278, leafLength: 520)),
        "SpiralGrassStage2": .init(sourceName: "SpiralGrass46Atlas", rect: CGRect(x: 834, y: 0, width: 458, height: 724), layout: .init(width: 458, height: 724, x: 42, y: 31, w: 382, h: 661, rootMinX: 173, rootMaxX: 284, leafLength: 520)),
        "SpiralGrassStage3": .init(sourceName: "SpiralGrass46Atlas", rect: CGRect(x: 1258, y: 0, width: 474, height: 724), layout: .init(width: 474, height: 724, x: 34, y: 31, w: 394, h: 661, rootMinX: 169, rootMaxX: 279, leafLength: 520)),
        "SpiralGrassStage4": .init(sourceName: "SpiralGrass46Atlas", rect: CGRect(x: 1686, y: 0, width: 486, height: 724), layout: .init(width: 486, height: 724, x: 46, y: 29, w: 428, h: 663, rootMinX: 148, rootMaxX: 386, leafLength: 520)),
        "SucculentPot": .init(sourceName: "TerracottaPot46Atlas", rect: CGRect(x: 0, y: 0, width: 1254, height: 1254), layout: .init(width: 1254, height: 1254, x: 185, y: 207, w: 885, h: 878)),
    ]
}
