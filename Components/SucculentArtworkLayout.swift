// PNG画布、透明轮廓与代表叶长；仅控制取景和显示尺度，不改动资源像素。
import Foundation

struct SucculentArtworkLayout: Sendable {
    let canvas: CGSize
    let bounds: CGRect
    let plantingAnchorY: CGFloat?
    let rootMinX: CGFloat?
    let rootMaxX: CGFloat?
    let referenceLeafLength: CGFloat?

    init(width: CGFloat = 1254, height: CGFloat = 1254, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, anchorY: CGFloat? = nil, rootMinX: CGFloat? = nil, rootMaxX: CGFloat? = nil, leafLength: CGFloat? = nil) {
        canvas = CGSize(width: width, height: height)
        bounds = CGRect(x: x, y: y, width: w, height: h)
        plantingAnchorY = anchorY
        self.rootMinX = rootMinX
        self.rootMaxX = rootMaxX
        referenceLeafLength = leafLength
    }

    // 草叶可垂过盆沿：把种植点对准盆口，同时让整个轮廓留在槽位内。
    func placement(in size: CGSize, planted: Bool, maximumSize: CGSize? = nil) -> (scale: CGFloat, offset: CGSize) {
        let sizeLimit = maximumSize.map { min($0.width / bounds.width, $0.height / bounds.height) } ?? .infinity
        var scale = min(size.width / bounds.width, size.height / bounds.height, sizeLimit)
        var y = size.height - bounds.height * scale - bounds.minY * scale
        var x = (size.width - bounds.width * scale) / 2 - bounds.minX * scale
        if planted {
            let soilY = size.height - 23
            let anchor = plantingAnchorY ?? bounds.maxY
            let upper = anchor - bounds.minY
            let lower = bounds.maxY - anchor
            scale = min(size.width / bounds.width,
                        upper > 0 ? soilY / upper : .infinity,
                        lower > 0 ? 23 / lower : .infinity, sizeLimit)
            let rootCenter = rootMinX.flatMap { left in rootMaxX.map { (left + $0) / 2 } } ?? bounds.midX
            scale = min(scale, size.width / 2 / (rootCenter - bounds.minX),
                        size.width / 2 / (bounds.maxX - rootCenter))
            if let rootMinX, let rootMaxX, rootMaxX > rootMinX {
                // 花盆绘制高度固定32pt，新陶盆盆土内可用约26pt；根点必须留在盆土内。
                scale = min(scale, 26 / (rootMaxX - rootMinX))
            }
            y = soilY - anchor * scale
            x = size.width / 2 - rootCenter * scale
        }
        return (scale, CGSize(width: x, height: y))
    }

    static let assets: [String: Self] = [
        "GuanyinStage0": .init(width: 1254, height: 1254, x: 235, y: 165, w: 815, h: 928),
        "GuanyinStage1": .init(width: 1254, height: 1254, x: 52, y: 126, w: 1148, h: 954),
        "GuanyinStage2": .init(width: 1254, height: 1254, x: 41, y: 88, w: 1175, h: 1097),
        "GuanyinStage3": .init(width: 1254, height: 1254, x: 42, y: 111, w: 1186, h: 1053, anchorY: 974.46),
        "GuanyinStage4": .init(width: 1254, height: 1254, x: 41, y: 91, w: 1192, h: 1093, anchorY: 987.26),
        "LithopsStage0": .init(width: 1254, height: 1254, x: 605, y: 605, w: 45, h: 44),
        "LithopsStage1": .init(width: 1254, height: 1254, x: 193, y: 281, w: 878, h: 736),
        "LithopsStage2": .init(width: 1254, height: 1254, x: 159, y: 272, w: 943, h: 744),
        "LithopsStage3": .init(width: 1254, height: 1254, x: 88, y: 205, w: 1081, h: 867),
        "LithopsStage4": .init(width: 1254, height: 1254, x: 81, y: 186, w: 1097, h: 924),
        "YuzhuiSprout": .init(width: 1254, height: 1254, x: 305, y: 508, w: 697, h: 344),
        "YuzhuiLeaf": .init(width: 1254, height: 1254, x: 392, y: 408, w: 534, h: 434),
        "HuangliLeaf": .init(x: 248, y: 398, w: 764, h: 467),
        "HuangliStage0": .init(x: 239, y: 476, w: 745, h: 478),
        "HuangliStage1": .init(x: 216, y: 334, w: 827, h: 670),
        "HuangliStage2": .init(x: 33, y: 99, w: 1208, h: 1070),
        "HuangliStage3": .init(x: 32, y: 99, w: 1193, h: 1069),
        "HuangliStage4": .init(x: 28, y: 108, w: 1212, h: 1047),
        "HuangliStage5": .init(x: 122, y: 61, w: 1048, h: 1150),
        "SucculentPot": .init(x: 101, y: 199, w: 1052, h: 853),
        "TaodanStage0": .init(width: 1254, height: 1254, x: 82, y: 336, w: 1095, h: 642),
        "TaodanStage1": .init(width: 1254, height: 1254, x: 113, y: 159, w: 1030, h: 967),
        "TaodanStage2": .init(width: 1254, height: 1254, x: 37, y: 102, w: 1185, h: 1036),
        "TaodanStage3": .init(width: 1254, height: 1254, x: 46, y: 95, w: 1177, h: 1024),
        "TaodanStage4": .init(width: 1254, height: 1254, x: 59, y: 106, w: 1149, h: 1048),
        "TaodanStage5": .init(width: 1254, height: 1254, x: 25, y: 95, w: 1204, h: 1089),
        "TaodanLeaf": .init(width: 1254, height: 1254, x: 167, y: 186, w: 916, h: 849),
        "ChihuahuaStage0": .init(width: 1254, height: 1254, x: 37, y: 342, w: 1179, h: 623),
        "ChihuahuaStage1": .init(width: 1254, height: 1254, x: 77, y: 151, w: 1110, h: 984),
        "ChihuahuaStage2": .init(width: 1254, height: 1254, x: 27, y: 54, w: 1205, h: 1142),
        "ChihuahuaStage3": .init(width: 1254, height: 1254, x: 27, y: 51, w: 1214, h: 1146),
        "ChihuahuaStage4": .init(width: 1254, height: 1254, x: 6, y: 66, w: 1246, h: 1145),
        "ChihuahuaStage5": .init(width: 1254, height: 1254, x: 28, y: 49, w: 1224, h: 1153),
        "ChihuahuaLeaf": .init(width: 1254, height: 1254, x: 198, y: 155, w: 902, h: 939),
        "OrangeMonroeStage0": .init(width: 1254, height: 1254, x: 65, y: 331, w: 1142, h: 674),
        "OrangeMonroeStage1": .init(width: 1254, height: 1254, x: 141, y: 229, w: 1006, h: 835),
        "OrangeMonroeStage2": .init(width: 1254, height: 1254, x: 36, y: 111, w: 1187, h: 1034),
        "OrangeMonroeStage3": .init(width: 1254, height: 1254, x: 50, y: 108, w: 1161, h: 1049),
        "OrangeMonroeStage4": .init(width: 1254, height: 1254, x: 68, y: 108, w: 1123, h: 1066),
        "OrangeMonroeStage5": .init(width: 1254, height: 1254, x: 26, y: 87, w: 1208, h: 1107),
        "OrangeMonroeLeaf": .init(width: 1254, height: 1254, x: 198, y: 241, w: 858, h: 758),
        "BabyFingerStage0": .init(width: 1254, height: 1254, x: 62, y: 324, w: 1134, h: 657),
        "BabyFingerStage1": .init(width: 1254, height: 1254, x: 117, y: 204, w: 1019, h: 853),
        "BabyFingerStage2": .init(width: 1254, height: 1254, x: 47, y: 106, w: 1159, h: 1044),
        "BabyFingerStage3": .init(width: 1254, height: 1254, x: 53, y: 91, w: 1156, h: 1073),
        "BabyFingerStage4": .init(width: 1254, height: 1254, x: 69, y: 87, w: 1121, h: 1098),
        "BabyFingerStage5": .init(width: 1254, height: 1254, x: 39, y: 180, w: 1180, h: 949),
        "BabyFingerLeaf": .init(width: 1254, height: 1254, x: 169, y: 189, w: 989, h: 880),
        "BlueBirdStage0": .init(width: 1254, height: 1254, x: 52, y: 340, w: 1150, h: 661),
        "BlueBirdStage1": .init(width: 1254, height: 1254, x: 74, y: 152, w: 1106, h: 957),
        "BlueBirdStage2": .init(width: 1254, height: 1254, x: 36, y: 85, w: 1196, h: 1103),
        "BlueBirdStage3": .init(width: 1254, height: 1254, x: 22, y: 68, w: 1213, h: 1124),
        "BlueBirdStage4": .init(width: 1254, height: 1254, x: 36, y: 44, w: 1192, h: 1169),
        "BlueBirdStage5": .init(width: 1254, height: 1254, x: 30, y: 152, w: 1211, h: 997),
        "BlueBirdLeaf": .init(width: 1254, height: 1254, x: 163, y: 165, w: 982, h: 948),
        "JilongyueStage0": .init(width: 1254, height: 1254, x: 63, y: 327, w: 1145, h: 684),
        "JilongyueStage1": .init(width: 1254, height: 1254, x: 111, y: 170, w: 1024, h: 925),
        "JilongyueStage2": .init(width: 1254, height: 1254, x: 54, y: 101, w: 1162, h: 1062),
        "JilongyueStage3": .init(width: 1254, height: 1254, x: 27, y: 48, w: 1202, h: 1149),
        "JilongyueStage4": .init(width: 1254, height: 1254, x: 36, y: 59, w: 1191, h: 1136),
        "JilongyueStage5": .init(width: 1254, height: 1254, x: 59, y: 91, w: 1143, h: 1096),
        "JilongyueLeaf": .init(width: 1254, height: 1254, x: 135, y: 166, w: 1030, h: 922),
        "RubyStage0": .init(width: 1254, height: 1254, x: 86, y: 373, w: 1095, h: 552),
        "RubyStage1": .init(width: 1254, height: 1254, x: 179, y: 196, w: 956, h: 886),
        "RubyStage2": .init(width: 1254, height: 1254, x: 58, y: 94, w: 1138, h: 1071),
        "RubyStage3": .init(width: 1254, height: 1254, x: 47, y: 80, w: 1174, h: 1098),
        "RubyStage4": .init(width: 1254, height: 1254, x: 46, y: 50, w: 1168, h: 1158),
        "RubyStage5": .init(width: 1254, height: 1254, x: 50, y: 65, w: 1166, h: 1131),
        "RubyLeaf": .init(width: 1254, height: 1254, x: 245, y: 198, w: 845, h: 858),
        "WhiteMoonStage0": .init(width: 1254, height: 1254, x: 53, y: 307, w: 1154, h: 753),
        "WhiteMoonStage1": .init(width: 1254, height: 1254, x: 148, y: 145, w: 955, h: 981),
        "WhiteMoonStage2": .init(width: 1254, height: 1254, x: 34, y: 86, w: 1186, h: 1075),
        "WhiteMoonStage3": .init(width: 1254, height: 1254, x: 40, y: 89, w: 1184, h: 1076),
        "WhiteMoonStage4": .init(width: 1254, height: 1254, x: 47, y: 77, w: 1165, h: 1107),
        "WhiteMoonStage5": .init(width: 1254, height: 1254, x: 9, y: 131, w: 1237, h: 1044),
        "WhiteMoonLeaf": .init(width: 1254, height: 1254, x: 186, y: 197, w: 953, h: 893),
        "GoldenStonecropStage2": .init(width: 1254, height: 1254, x: 43, y: 166, w: 1165, h: 861, rootMinX: 398, rootMaxX: 1069),
        "GoldenStonecropStage1": .init(width: 1254, height: 1254, x: 38, y: 106, w: 1180, h: 1042, rootMinX: 331, rootMaxX: 911),
        "GoldenStonecropCutting": .init(width: 1254, height: 1254, x: 350, y: 158, w: 676, h: 919),
        "GoldenStonecropStage3": .init(width: 1254, height: 1254, x: 42, y: 59, w: 1181, h: 1168, anchorY: 899.96),
        "GoldenStonecropStage0": .init(width: 1254, height: 1254, x: 277, y: 255, w: 712, h: 793, rootMinX: 649, rootMaxX: 687),
        "JixingMeirenStage2": .init(width: 1254, height: 1254, x: 44, y: 212, w: 1163, h: 793, rootMinX: 197, rootMaxX: 1073),
        "JixingMeirenStage1": .init(width: 1254, height: 1254, x: 258, y: 116, w: 738, h: 1015, rootMinX: 471, rootMaxX: 816),
        "JixingMeirenCutting": .init(width: 1254, height: 1254, x: 486, y: 182, w: 418, h: 885),
        "JixingMeirenStage3": .init(width: 1254, height: 1254, x: 21, y: 176, w: 1212, h: 938, anchorY: 851.36),
        "JixingMeirenStage0": .init(width: 1254, height: 1254, x: 467, y: 286, w: 348, h: 724, rootMinX: 607, rootMaxX: 658),
        "SnowStonecropStage2": .init(width: 1254, height: 1254, x: 20, y: 203, w: 1222, h: 836, rootMinX: 166, rootMaxX: 1114),
        "SnowStonecropStage1": .init(width: 1254, height: 1254, x: 289, y: 166, w: 752, h: 906, rootMinX: 442, rootMaxX: 829),
        "SnowStonecropCutting": .init(width: 1254, height: 1254, x: 461, y: 163, w: 547, h: 945),
        "SnowStonecropStage3": .init(width: 1254, height: 1254, x: 5, y: 134, w: 1244, h: 1012, anchorY: 862.64),
        "SnowStonecropStage0": .init(width: 1254, height: 1254, x: 392, y: 249, w: 480, h: 747, rootMinX: 623, rootMaxX: 668),
        "YuzhuiStage2": .init(width: 1254, height: 1254, x: 54, y: 149, w: 1153, h: 950, rootMinX: 269, rootMaxX: 918),
        "YuzhuiStage1": .init(width: 1254, height: 1254, x: 277, y: 66, w: 755, h: 1032, rootMinX: 495, rootMaxX: 754),
        "YuzhuiStage3": .init(width: 1254, height: 1254, x: 25, y: 71, w: 1208, h: 1119, anchorY: 764.78),
        "YuzhuiStage0": .init(width: 1254, height: 1254, x: 461, y: 177, w: 338, h: 850, rootMinX: 602, rootMaxX: 653)
    ].merging(SucculentAtlasLayout.frames.mapValues(\.layout), uniquingKeysWith: { _, new in new })
}
