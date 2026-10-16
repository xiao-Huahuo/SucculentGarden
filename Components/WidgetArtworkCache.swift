// Widget 归档只携带显示尺寸的位图，避免把1254px原图随全部成长条目打包超限。
// 原始PNG不改；同步按需读取，确保Widget归档时有图，缓存预算8MiB。
import AppKit

@MainActor
enum WidgetArtworkCache {
    private static let cache = ArtworkImageCache(maximumDimension: 256, memoryLimit: 8 * 1_024 * 1_024)
    // 横向两/三格的盆在Retina组件里需要更多像素；植物仍沿用原256px预算。
    private static let largePots = ArtworkImageCache(maximumDimension: 512, memoryLimit: 2 * 1_024 * 1_024)

    static func image(named name: String) -> NSImage? {
        (name == "WidePot47" || name == "LongPot47" ? largePots : cache).imageSynchronously(named: name)
    }
}
