// 显示缓存需要限制像素、保持比例与透明度，不能把原图变为不透明大位图。
import AppKit
import CoreGraphics
import Testing

@MainActor
struct WidgetArtworkTests {
    @Test
    func widgetBitmapIsSmallAndKeepsAlphaAndAspectRatio() throws {
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(CGContext(data: nil, width: 1254, height: 800,
                                            bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1))
        context.fill(CGRect(x: 200, y: 200, width: 800, height: 400))
        let original = try #require(context.makeImage())
        let result = try #require(ArtworkImageDecoder.thumbnail(from: original, maximumDimension: 256))
        #expect(result.width == 256 && result.height == 163)
        #expect(result.bytesPerRow * result.height < 256 * 256 * 4)
        let pixels = NSBitmapImageRep(cgImage: result)
        #expect(try #require(pixels.colorAt(x: 0, y: 0)).alphaComponent == 0)
        #expect(try #require(pixels.colorAt(x: 128, y: 80)).alphaComponent > 0.99)
        #expect(original.width == 1254 && original.height == 800)
    }
}
