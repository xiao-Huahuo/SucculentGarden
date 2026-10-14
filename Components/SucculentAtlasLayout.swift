// 每个品种只打包一张原始透明图；帧矩形用于运行时取图，不改写源PNG。
import Foundation

struct SucculentAtlasFrame: Sendable {
    let sourceName: String
    let rect: CGRect
    let layout: SucculentArtworkLayout
}

enum SucculentAtlasLayout {
    static let frames: [String: SucculentAtlasFrame] = {
        var result: [String: SucculentAtlasFrame] = [:]
        result.merge(CrassulaceaeTypeAtlasFrames.frames, uniquingKeysWith: { _, new in new })
        result.merge(StonecropTypeAtlasFrames.frames, uniquingKeysWith: { _, new in new })
        result.merge(YuzhuiTypeAtlasFrames.frames, uniquingKeysWith: { _, new in new })
        result.merge(GuanyinTypeAtlasFrames.frames, uniquingKeysWith: { _, new in new })
        result.merge(ConophytumTypeAtlasFrames.frames, uniquingKeysWith: { _, new in new })
        result.merge(HaworthiaTypeAtlasFrames.frames, uniquingKeysWith: { _, new in new })
        result.merge(CactusTypeAtlasFrames.frames, uniquingKeysWith: { _, new in new })
        result.merge(MoneyStackTypeAtlasFrames.frames, uniquingKeysWith: { _, new in new })
        result.merge(MotherOfThousandsTypeAtlasFrames.frames, uniquingKeysWith: { _, new in new })
        result.merge(Revision29AtlasFrames.frames, uniquingKeysWith: { _, new in new })
        result.merge(Revision30AtlasFrames.frames, uniquingKeysWith: { _, new in new })
        result.merge(Revision37AtlasFrames.frames, uniquingKeysWith: { _, new in new })
        result.merge(Revision40AtlasFrames.frames, uniquingKeysWith: { _, new in new })
        return result
    }()
}
