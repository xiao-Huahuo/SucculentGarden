// 可见视图按需请求、同名请求合并；仅缓存显示位图，按最近使用顺序淘汰到字节预算以内。
import AppKit
import CoreGraphics
import OSLog

@MainActor
final class ArtworkImageCache {
    static let shared = ArtworkImageCache(maximumDimension: 512, memoryLimit: 16 * 1_024 * 1_024)
    private struct Entry {
        let image: NSImage
        let bytes: Int
    }

    let maximumDimension: Int
    let memoryLimit: Int
    private let loader: @Sendable (String, Int) -> CGImage?
    private var entries: [String: Entry] = [:]
    private var order: [String] = []
    private var pending: [String: Task<CGImage?, Never>] = [:]
    private let logger = Logger(subsystem: "local.littlecomponent.app", category: "ArtworkImageCache")
    private(set) var cachedBytes = 0
    var cachedNames: [String] { order }

    init(maximumDimension: Int, memoryLimit: Int,
         loader: @escaping @Sendable (String, Int) -> CGImage? = { ArtworkImageDecoder.image(named: $0, maximumDimension: $1) }) {
        self.maximumDimension = maximumDimension
        self.memoryLimit = memoryLimit
        self.loader = loader
    }

    func image(named name: String) async -> NSImage? {
        if let image = cached(name) { return image }
        if let task = pending[name] { return await task.value.map(Self.displayImage) }
        let loader = loader
        let dimension = maximumDimension
        let task = Task.detached(priority: .userInitiated) { loader(name, dimension) }
        pending[name] = task
        let bitmap = await task.value
        pending[name] = nil
        return store(bitmap, named: name)
    }

    // Widget的视图在归档时必须有图片，不能依赖归档后不会执行的SwiftUI.task。
    func imageSynchronously(named name: String) -> NSImage? {
        if let image = cached(name) { return image }
        return store(loader(name, maximumDimension), named: name)
    }

    private func cached(_ name: String) -> NSImage? {
        guard let entry = entries[name] else { return nil }
        order.removeAll { $0 == name }
        order.append(name)
        return entry.image
    }

    private func store(_ bitmap: CGImage?, named name: String) -> NSImage? {
        guard let bitmap else {
            logger.error("贴图无法读取：\(name, privacy: .public)")
            return nil
        }
        let image = Self.displayImage(bitmap)
        let bytes = bitmap.bytesPerRow * bitmap.height
        guard bytes <= memoryLimit else { return image }
        if let previous = entries.removeValue(forKey: name) { cachedBytes -= previous.bytes }
        order.removeAll { $0 == name }
        while cachedBytes + bytes > memoryLimit, let oldest = order.first {
            order.removeFirst()
            if let removed = entries.removeValue(forKey: oldest) { cachedBytes -= removed.bytes }
        }
        entries[name] = Entry(image: image, bytes: bytes)
        order.append(name)
        cachedBytes += bytes
        return image
    }

    private static func displayImage(_ bitmap: CGImage) -> NSImage {
        NSImage(cgImage: bitmap, size: CGSize(width: bitmap.width, height: bitmap.height))
    }
}
