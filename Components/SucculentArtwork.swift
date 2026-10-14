// 显示品种 PNG；仅调整视图取景，不改写图片像素或透明通道。
import SwiftUI
import WidgetKit

struct SucculentArtwork: View {
    let stage: SucculentStage?
    var species: SucculentSpecies = .huangli
    var isLeaf = false
    var isWidget = false
    var isPlanted = false
    var pointsPerCentimeter: CGFloat?

    var body: some View {
        GardenArtworkImage(name: species.assetName(stage: stage ?? species.initialStage, isLeaf: isLeaf),
                           isWidget: isWidget, planted: isPlanted,
                           centimeters: SucculentArtworkSize.centimeters(species: species, stage: stage ?? species.initialStage, isLeaf: isLeaf),
                           pointsPerCentimeter: pointsPerCentimeter)
            .accessibilityLabel(isLeaf ? "\(species.title)\(species.propagationTitle)" : "\(species.title)，\(species.stageTitle(for: stage ?? species.initialStage))")
    }
}

struct FlowerpotArtwork: View {
    var isWidget = false
    var body: some View {
        GardenArtworkImage(name: "SucculentPot", isWidget: isWidget)
            .accessibilityHidden(true)
    }
}

private struct GardenArtworkImage: View {
    let name: String
    let isWidget: Bool
    var planted = false
    var centimeters: CGSize?
    var pointsPerCentimeter: CGFloat?
    @State private var loaded: LoadedArtwork?

    private struct LoadedArtwork {
        let name: String
        let image: NSImage?
    }

    var body: some View {
        if isWidget {
            drawing(image: WidgetArtworkCache.image(named: name), failed: true)
        } else {
            drawing(image: loaded?.name == name ? loaded?.image : nil, failed: loaded?.name == name)
                .task(id: name) {
                    let image = await ArtworkImageCache.shared.image(named: name)
                    guard !Task.isCancelled else { return }
                    loaded = LoadedArtwork(name: name, image: image)
                }
                .onDisappear { loaded = nil }
        }
    }

    @ViewBuilder private func drawing(image: NSImage?, failed: Bool) -> some View {
        if let layout = SucculentArtworkLayout.assets[name] {
            GeometryReader { geometry in
                let unit = pointsPerCentimeter ?? SucculentArtworkSize.previewPointsPerCentimeter(in: geometry.size)
                let maximumSize = centimeters.map { CGSize(width: $0.width * unit, height: $0.height * unit) }
                let placement = layout.placement(in: geometry.size, planted: planted, maximumSize: maximumSize)
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .widgetAccentedRenderingMode(.fullColor)
                        .frame(width: layout.canvas.width * placement.scale, height: layout.canvas.height * placement.scale)
                        .offset(placement.offset)
                } else if failed {
                    Image(systemName: "photo.badge.exclamationmark").accessibilityLabel("贴图暂不可用")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView().controlSize(.small)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .clipped()
            .contentShape(Rectangle())
        } else {
            Image(systemName: "photo.badge.exclamationmark")
                .accessibilityLabel("贴图暂不可用")
        }
    }
}

struct SucculentSlotContent: View {
    let plant: SucculentPlant?
    let date: Date
    let rate: Double
    var artSize: CGFloat = 80
    var isWidget = false
    var showsCountdown = false
    var showsPlantName = false

    private var stage: SucculentStage? { plant?.stage(at: date, rate: rate) }

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                FlowerpotArtwork(isWidget: isWidget)
                    .frame(width: artSize * 0.65, height: 32)
                if let stage {
                    SucculentArtwork(stage: stage, species: plant?.species ?? .huangli,
                                     isWidget: isWidget, isPlanted: true,
                                     pointsPerCentimeter: SucculentArtworkSize.plantedPointsPerCentimeter(artSize: artSize))
                        .frame(width: artSize, height: artSize + 15)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(.tertiary)
                        .frame(maxHeight: .infinity, alignment: .center)
                }
            }
            .frame(width: artSize, height: artSize + 15)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(isWidget || showsPlantName ? 2 : 1)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)
                .foregroundStyle(stage == nil ? .secondary : .primary)
            if showsCountdown, let plant {
                if let seconds = GardenGrowthTime.remaining(for: plant, at: date, rate: rate) {
                    Text("还需 \(GardenGrowthTime.text(seconds))")
                        .font(.system(size: 10)).monospacedDigit()
                        .foregroundStyle(.secondary)
                        .lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.8)
                } else {
                    Text("已到最终阶段").font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var label: String {
        guard let stage, let plant else { return "空花盆" }
        guard isWidget || showsPlantName else { return plant.species.stageTitle(for: stage) }
        let title = stage == .adult ? "成年" : stage == .prime ? "壮年" : plant.species.stageTitle(for: stage)
        return "\(plant.species.title)（\(title)）"
    }
}
