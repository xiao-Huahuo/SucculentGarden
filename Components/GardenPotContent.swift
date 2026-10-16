// 主页面和真正的Widget共用盆、植株、根点及前后遮挡；不把几株肉各画成一只独立盆。
import SwiftUI

struct GardenPotContent: View {
    let pot: GardenPot
    let garden: SucculentGarden
    let date: Date
    var isWidget = false
    var showsCountdown = false

    private var plants: [SucculentPlant] { pot.plants.compactMap { garden.plant(id: $0) } }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let size = GardenPotGeometry.potSize(kind: pot.kind, width: geometry.size.width)
                let roots = GardenPotGeometry.roots(kind: pot.kind, width: geometry.size.width, height: 100)
                ZStack(alignment: .bottom) {
                    FlowerpotArtwork(kind: pot.kind, isWidget: isWidget).frame(width: size.width, height: size.height)
                    ForEach(pot.plants.indices, id: \.self) { position in
                        if let plant = garden.plant(id: pot.plants[position]) {
                            SucculentArtwork(stage: plant.stage(at: date, rate: garden.effectiveRate(for: plant.species)),
                                             species: plant.species, isWidget: isWidget, isPlanted: true,
                                             pointsPerCentimeter: size.width / CGFloat(pot.kind.capacity * 4),
                                             plantingPoint: roots[position], rootWidth: size.width * 0.75 / sqrt(CGFloat(pot.kind.capacity)))
                                .frame(width: geometry.size.width, height: 100)
                        } else if !isWidget {
                            Image(systemName: "plus").font(.system(size: 11, weight: .light))
                                .foregroundStyle(.secondary).position(roots[position])
                        }
                    }
                }
                .frame(width: geometry.size.width, height: 100, alignment: .bottom)
            }
            .frame(height: 100)
            if plants.isEmpty {
                Text("空\(pot.kind.title)").font(.system(size: 10)).foregroundStyle(.secondary)
            } else if showsCountdown {
                ForEach(plants) { plant in
                    if pot.kind == .ordinary {
                        VStack(spacing: 3) {
                            Text(label(plant)).font(.system(size: 10, weight: .medium)).lineLimit(2)
                            Text(countdown(plant)).font(.system(size: 9)).monospacedDigit()
                                .foregroundStyle(.secondary).lineLimit(2)
                        }.multilineTextAlignment(.center)
                    } else {
                        Text("\(label(plant)) · \(countdown(plant))")
                            .font(.system(size: 10)).monospacedDigit().lineLimit(2).minimumScaleFactor(0.8)
                            .multilineTextAlignment(.center)
                    }
                }
            } else {
                Text(plants.map(label).joined(separator: " · "))
                    .font(.system(size: 10, weight: .medium)).lineLimit(pot.kind == .ordinary ? 2 : 3)
                    .minimumScaleFactor(0.8).multilineTextAlignment(.center)
            }
        }
    }

    private func label(_ plant: SucculentPlant) -> String {
        let stage = plant.stage(at: date, rate: garden.effectiveRate(for: plant.species))
        let title = stage == .adult ? "成年" : stage == .prime ? "壮年" : plant.species.stageTitle(for: stage)
        return "\(plant.species.title)（\(title)）"
    }

    private func countdown(_ plant: SucculentPlant) -> String {
        GardenGrowthTime.remaining(for: plant, at: date, rate: garden.effectiveRate(for: plant.species))
            .map(GardenGrowthTime.compact) ?? "已到最终阶段"
    }
}
