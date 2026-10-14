// 三页共用卡片宽度；高度随图片与内容变化，网格每行由最高卡片撑开。
import SwiftUI

enum GardenInventoryLayout {
    static let width: CGFloat = 184
    static let imageWidth: CGFloat = 164
    static let maximumImageHeight: CGFloat = 156
    static let pointsPerCentimeter = maximumImageHeight / SucculentArtworkSize.previewSpan
    static let spacing: CGFloat = 16
    static var columns: [GridItem] {
        [GridItem(.adaptive(minimum: width, maximum: width), spacing: spacing, alignment: .top)]
    }

    static func imageHeight(species: SucculentSpecies, stage: SucculentStage, isMaterial: Bool) -> CGFloat {
        let name = species.assetName(stage: stage, isLeaf: isMaterial)
        guard let layout = SucculentArtworkLayout.assets[name] else { return maximumImageHeight }
        let cm = SucculentArtworkSize.centimeters(species: species, stage: stage, isLeaf: isMaterial)
        let scale = min(imageWidth / layout.bounds.width, maximumImageHeight / layout.bounds.height,
                        cm.width * pointsPerCentimeter / layout.bounds.width,
                        cm.height * pointsPerCentimeter / layout.bounds.height)
        return layout.bounds.height * scale
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
        VStack(spacing: 6) {
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
                .allowsHitTesting(false)
            }
            content
        }
        .padding(10)
        .frame(width: GardenInventoryLayout.width, alignment: .top)
    }
}
