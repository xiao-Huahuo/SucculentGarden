// Widget 归档只携带显示尺寸的位图，避免把1254px原图随全部成长条目打包超限。
// 原始PNG不改；同步按需读取，确保Widget归档时有图，缓存预算8MiB。
import AppKit

@MainActor
enum WidgetArtworkCache {
    private static let cache = ArtworkImageCache(maximumDimension: 256, memoryLimit: 8 * 1_024 * 1_024)

    static func image(named name: String) -> NSImage? {
        cache.imageSynchronously(named: name)
    }
}
