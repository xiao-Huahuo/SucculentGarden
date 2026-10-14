// 使用隔离位图验证按需加载、后台解码、同名合并、取消和缓存淘汰，不读取真实存档。
import AppKit
import CoreGraphics
import Foundation
import Testing

@MainActor
struct ArtworkImageCacheTests {
    @Test
    func onlyRequestedArtworkLoadsOffMainThreadAndReusesTheCachedImage() async throws {
        let probe = try Probe()
        let cache = ArtworkImageCache(maximumDimension: 512, memoryLimit: 1_000_000, loader: probe.load)
        #expect(probe.names.isEmpty && cache.cachedBytes == 0)
        let first = try #require(await cache.image(named: "visible"))
        let again = try #require(await cache.image(named: "visible"))
        #expect(first === again && probe.names == ["visible"])
        #expect(probe.mainThreadLoads == 0)
        #expect(cache.cachedNames == ["visible"])
    }

    @Test
    func duplicateRequestsDecodeOnceAndOneCancelledViewDoesNotCancelAnother() async throws {
        let probe = try Probe(delay: 0.04)
        let cache = ArtworkImageCache(maximumDimension: 512, memoryLimit: 1_000_000, loader: probe.load)
        let first = Task { await cache.image(named: "shared") }
        let second = Task { await cache.image(named: "shared") }
        await Task.yield()
        first.cancel()
        #expect(await second.value != nil)
        _ = await first.value
        #expect(probe.names == ["shared"])
        #expect(cache.cachedNames == ["shared"])
    }

    @Test
    func leastRecentlyUsedImagesAreEvictedWithinTheByteBudgetForBothLoadModes() async throws {
        let probe = try Probe()
        let bytes = probe.bitmap.bytesPerRow * probe.bitmap.height
        let cache = ArtworkImageCache(maximumDimension: 256, memoryLimit: bytes * 2, loader: probe.load)
        #expect(await cache.image(named: "a") != nil)
        #expect(await cache.image(named: "b") != nil)
        #expect(cache.imageSynchronously(named: "a") != nil)
        #expect(cache.imageSynchronously(named: "c") != nil)
        #expect(cache.cachedNames == ["a", "c"] && cache.cachedBytes == bytes * 2)
        #expect(await cache.image(named: "b") != nil)
        #expect(cache.cachedNames == ["c", "b"] && cache.cachedBytes <= cache.memoryLimit)
        #expect(probe.names == ["a", "b", "c", "b"])
    }

    @Test
    func missingOrOversizedImagesDoNotPoisonTheCache() async throws {
        let probe = try Probe()
        let cache = ArtworkImageCache(maximumDimension: 256, memoryLimit: 1, loader: probe.load)
        #expect(await cache.image(named: "valid") != nil)
        #expect(cache.cachedBytes == 0 && cache.cachedNames.isEmpty)
        #expect(await cache.image(named: "missing") == nil)
        #expect(await cache.image(named: "missing") == nil)
        #expect(probe.names == ["valid", "missing", "missing"])
    }

    @Test
    func decodingRemovesTheFullSizeSourceFromAppKitsNamedCache() async throws {
        let probe = try Probe()
        let name = "isolated-artwork-\(UUID().uuidString)"
        let source = NSImage(cgImage: probe.bitmap, size: CGSize(width: 64, height: 32))
        #expect(source.setName(name))
        defer { source.setName(nil) }
        let decoded = await Task.detached { ArtworkImageDecoder.image(named: name, maximumDimension: 32) }.value
        let bitmap = try #require(decoded)
        #expect(bitmap.width == 32 && bitmap.height == 16)
        #expect(NSImage(named: name) == nil)
        #expect(probe.bitmap.width == 64 && probe.bitmap.height == 32)
    }
}

private final class Probe: @unchecked Sendable {
    let bitmap: CGImage
    private let delay: TimeInterval
    private let lock = NSLock()
    private var requested: [String] = []
    private var mainCount = 0
    var names: [String] { lock.withLock { requested } }
    var mainThreadLoads: Int { lock.withLock { mainCount } }

    init(delay: TimeInterval = 0) throws {
        self.delay = delay
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(CGContext(data: nil, width: 64, height: 32, bitsPerComponent: 8,
                                            bytesPerRow: 0, space: space,
                                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        bitmap = try #require(context.makeImage())
    }

    func load(_ name: String, _ dimension: Int) -> CGImage? {
        lock.withLock {
            requested.append(name)
            if Thread.isMainThread { mainCount += 1 }
        }
        if delay > 0 { Thread.sleep(forTimeInterval: delay) }
        return name == "missing" ? nil : bitmap
    }
}
