// 串行读取资产并生成显示位图；原图退出AppKit命名缓存，不改写PNG或资产目录。
import AppKit
import CoreGraphics

enum ArtworkImageDecoder {
    private static let queue = DispatchQueue(label: "local.littlecomponent.artwork.decode", qos: .userInitiated)

    static func image(named name: String, maximumDimension: Int) -> CGImage? {
        queue.sync {
            autoreleasepool {
                let frame = SucculentAtlasLayout.frames[name]
                let sourceName = frame?.sourceName ?? name
                guard let image = NSImage(named: sourceName) else { return nil }
                defer { image.setName(nil) }
                guard let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
                if let frame {
                    guard let selected = source.cropping(to: frame.rect) else { return nil }
                    return thumbnail(from: selected, maximumDimension: maximumDimension)
                }
                return thumbnail(from: source, maximumDimension: maximumDimension)
            }
        }
    }

    static func thumbnail(from source: CGImage, maximumDimension: Int) -> CGImage? {
        let ratio = min(1, Double(maximumDimension) / Double(max(source.width, source.height)))
        let width = max(1, Int((Double(source.width) * ratio).rounded()))
        let height = max(1, Int((Double(source.height) * ratio).rounded()))
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}
