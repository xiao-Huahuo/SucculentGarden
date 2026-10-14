// 商店、植株收藏和繁殖材料共用卡片尺寸，保持透明底色与紧凑网格。
import SwiftUI

enum GardenInventoryLayout {
    static let width: CGFloat = 184
    static let height: CGFloat = 272
    static let imageWidth: CGFloat = 164
    static let imageHeight: CGFloat = 156
    static let spacing: CGFloat = 16
    static var columns: [GridItem] {
        [GridItem(.adaptive(minimum: width, maximum: width), spacing: spacing)]
    }
}

enum GardenMultiplierDisplay {
    static let showXKey = "garden.showTimeMultiplierX"
    static let showYKey = "garden.showTimeMultiplierY"
}

struct GardenInventoryCard<Content: View>: View {
    @AppStorage(GardenMultiplierDisplay.showXKey) private var showX = false
    @AppStorage(GardenMultiplierDisplay.showYKey) private var showY = true
    let typeMultiplier: Double
    let timeMultiplier: Double
    let content: Content

    init(typeMultiplier: Double, timeMultiplier: Double, @ViewBuilder content: () -> Content) {
        self.typeMultiplier = typeMultiplier
        self.timeMultiplier = timeMultiplier
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 6) { content }
            .padding(10)
            .frame(width: GardenInventoryLayout.width, height: GardenInventoryLayout.height, alignment: .top)
            .overlay(alignment: .topLeading) {
                if showX || showY {
                    HStack(spacing: 8) {
                        if showX {
                            Text("x × \(typeMultiplier.formatted(.number.precision(.fractionLength(2))))")
                                .help("类型时间乘数；越大成长越慢。")
                                .accessibilityLabel("类型时间乘数 \(typeMultiplier.formatted())")
                        }
                        if showY {
                            Text("y × \(timeMultiplier.formatted(.number.precision(.fractionLength(2))))")
                                .help("植物时间乘数；越大成长越慢。")
                                .accessibilityLabel("植物时间乘数 \(timeMultiplier.formatted())")
                        }
                    }
                    .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                    .frame(maxWidth: GardenInventoryLayout.width - 40, alignment: .leading)
                    .padding(6)
                    .allowsHitTesting(false)
                }
            }
    }
}
