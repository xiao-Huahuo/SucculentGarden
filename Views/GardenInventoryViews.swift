// 一个品种一个商店框；收藏仅显示待摆放植株，放入花盆后从收藏移出。
import SwiftUI

struct GardenShopView: View {
    @Bindable var model: GardenModel
    let garden: SucculentGarden
    let date: Date
    let availableHeight: CGFloat
    private var matches: [SucculentSpecies] {
        model.shopSpecies
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !matches.isEmpty {
                LazyVGrid(columns: GardenInventoryLayout.columns, alignment: .leading, spacing: GardenInventoryLayout.spacing) {
                    ForEach(matches) { species in
                        speciesCard(species)
                    }
                }
            } else if model.search.isEmpty, let morphology = model.shopMorphology {
                ContentUnavailableView("\(morphology.title)暂无多肉", systemImage: "leaf")
                    .frame(maxWidth: .infinity, minHeight: availableHeight)
            } else {
                ContentUnavailableView.search(text: model.search)
                    .frame(maxWidth: .infinity, minHeight: availableHeight)
            }
        }
    }

    private func speciesCard(_ species: SucculentSpecies) -> some View {
        let stage = model.shopStage(for: species)
        let price = species.purchasePrice(for: stage)
        return GardenInventoryCard(typeMultiplier: garden.growthMultipliers.x(for: species.morphology),
                                   timeMultiplier: garden.growthMultipliers.y(for: species)) {
            SucculentArtwork(stage: stage, species: species, isLeaf: price == nil,
                             pointsPerCentimeter: GardenInventoryLayout.pointsPerCentimeter)
                .frame(width: GardenInventoryLayout.imageWidth,
                       height: GardenInventoryLayout.imageHeight(species: species, stage: stage, isMaterial: price == nil))
            Text(species.title).font(.headline).lineLimit(1).minimumScaleFactor(0.85)
            Picker("生长时期", selection: Binding(
                get: { model.shopStage(for: species) },
                set: { model.selectShopStage($0, for: species) }
            )) {
                ForEach(species.stages) { Text(species.stageTitle(for: $0)).tag($0) }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .controlSize(.small)
            if let price {
                Button(price == 0 ? "领取小草" : "购买 · $\(price)") { Task { await model.buy(stage, species: species) } }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .help(price == 0 ? "领取后保存到“我的多肉”，可拖入花盆。" : "购买并放入当前花盆。")
                    .disabled(model.isBusy || garden.money < price || (price == 0 && garden.remainingClaims(at: date) == 0))
                if price == 0 {
                    Text("今日剩余 \(garden.remainingClaims(at: date)) / 5")
                        .font(.caption).foregroundStyle(.secondary)
                } else if garden.money < price {
                    Text("余额不足").font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Button("领取\(species.propagationTitle)") { Task { await model.claimLeaf(species) } }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(model.isBusy || garden.remainingClaims(at: date) == 0)
                Text("今日剩余 \(garden.remainingClaims(at: date)) / 5")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct GardenCollectionView: View {
    let model: GardenModel
    let garden: SucculentGarden
    let date: Date
    let availableHeight: CGFloat

    private var matches: [SucculentPlant] {
        model.collectionPlants(in: garden, at: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if garden.plants.isEmpty {
                ContentUnavailableView("收藏里还没有多肉", systemImage: "leaf",
                                       description: Text("购买一株多肉，或把繁殖材料拖到下方花盆开始种植。"))
                    .frame(maxWidth: .infinity, minHeight: availableHeight)
            } else if garden.unplacedPlants.isEmpty {
                ContentUnavailableView("多肉已放入花盆", systemImage: "leaf",
                                       description: Text("可拖动下方多肉换盆，或在花盆菜单中移回收藏。"))
                    .frame(maxWidth: .infinity, minHeight: availableHeight)
            } else if matches.isEmpty {
                if model.search.isEmpty, model.collectionStageIndex != nil {
                    ContentUnavailableView("该阶段暂无待摆放多肉", systemImage: "leaf")
                        .frame(maxWidth: .infinity, minHeight: availableHeight)
                } else if model.search.isEmpty, let morphology = model.collectionMorphology {
                    ContentUnavailableView("\(morphology.title)暂无待摆放多肉", systemImage: "leaf")
                        .frame(maxWidth: .infinity, minHeight: availableHeight)
                } else {
                    ContentUnavailableView.search(text: model.search)
                        .frame(maxWidth: .infinity, minHeight: availableHeight)
                }
            } else {
                LazyVGrid(columns: GardenInventoryLayout.columns, alignment: .leading, spacing: GardenInventoryLayout.spacing) {
                    ForEach(matches) { plant in
                        plantItem(plant)
                    }
                }
            }
        }
    }

    private func plantItem(_ plant: SucculentPlant) -> some View {
        let stage = plant.stage(at: date, rate: garden.effectiveRate(for: plant.species))
        let index = (garden.plants.firstIndex(where: { $0.id == plant.id }) ?? 0) + 1
        return GardenInventoryCard(typeMultiplier: garden.growthMultipliers.x(for: plant.species.morphology),
                                   timeMultiplier: garden.growthMultipliers.y(for: plant.species)) {
            SucculentArtwork(stage: stage, species: plant.species,
                             pointsPerCentimeter: GardenInventoryLayout.pointsPerCentimeter)
                .frame(width: GardenInventoryLayout.imageWidth,
                       height: GardenInventoryLayout.imageHeight(species: plant.species, stage: stage, isMaterial: false))
                .draggable(GardenDragItem(kind: .plant, id: plant.id))
            Text("\(plant.species.title) \(index)").font(.headline).lineLimit(1).minimumScaleFactor(0.85)
            Text(plant.species.stageTitle(for: stage)).font(.caption).foregroundStyle(.secondary)
            if let next = plant.transitionDates(after: date, rate: garden.effectiveRate(for: plant.species)).first {
                Text("下阶段：\(next, style: .relative)")
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                Text("已长成\(plant.species.stageTitle(for: plant.species.matureStage))").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .overlay(alignment: .topTrailing) {
            Menu { plantActions(plant) } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .padding(6)
            .accessibilityLabel("操作\(plant.species.title)")
        }
        .contextMenu { plantActions(plant) }
        .disabled(model.isBusy)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(plant.species.title) \(index)，\(plant.species.stageTitle(for: stage))")
    }

    @ViewBuilder private func plantActions(_ plant: SucculentPlant) -> some View {
        ForEach(0..<3, id: \.self) { slot in
            Button("放入花盆 \(slot + 1)") {
                model.selectedSlot = slot
                Task { await model.assign(plant.id, to: slot) }
            }
        }
        Divider()
        let stage = plant.stage(at: date, rate: garden.effectiveRate(for: plant.species))
        let count = plant.species.disassemblyCount(for: stage)
        Button(plant.species.morphology == .guanyinType || plant.species.morphology == .haworthiaType ? "拆成小苗" : plant.species.morphology == .conophytumType ? "不可拆分" : plant.species.morphology == .cactusType ? "拆成芽块" : plant.species.morphology == .moneyStackType ? "拆成枝条" : "拆成叶片") { Task { await model.disassemble(plant.id) } }
            .disabled(count == nil)
            .help(count.map { "消耗这株多肉，获得\($0)份\(plant.species.title)\(plant.species.propagationTitle)。" } ?? "当前时期不能拆分。")
        if plant.species.morphology == .motherOfThousandsType {
            let harvest = plant.species.harvestCount(for: stage)
            let cooling = plant.nextHarvestDate().map { $0 > date } ?? false
            Button("摘芽") { Task { await model.harvest(plant.id) } }
                .disabled(harvest == nil || cooling)
                .help(harvest == nil ? "成年后可摘芽。" : cooling ? "距下次摘芽还有\(GardenGrowthTime.text(plant.nextHarvestDate()!.timeIntervalSince(date)))。" : "获得\(harvest!)个小芽，保留母株；每株24小时一次。")
        }
        Button("出售 · $\(stage.salePrice)") { Task { await model.sell(plant.id) } }
    }
}

struct GardenLeavesView: View {
    let model: GardenModel
    let garden: SucculentGarden
    let date: Date
    let availableHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if garden.leaves.isEmpty {
                ContentUnavailableView("没有待种植的繁殖材料", systemImage: "tray",
                                       description: Text("前往商店免费领取繁殖材料，再拖到下方花盆开始种植。"))
                    .frame(maxWidth: .infinity, minHeight: availableHeight)
            } else {
                LazyVGrid(columns: GardenInventoryLayout.columns, alignment: .leading, spacing: GardenInventoryLayout.spacing) {
                    ForEach(garden.leafStacks) { stack in
                        GardenInventoryCard(typeMultiplier: garden.growthMultipliers.x(for: stack.species.morphology),
                                            timeMultiplier: garden.growthMultipliers.y(for: stack.species)) {
                            SucculentArtwork(stage: nil, species: stack.species, isLeaf: true,
                                             pointsPerCentimeter: GardenInventoryLayout.pointsPerCentimeter)
                                .frame(width: GardenInventoryLayout.imageWidth,
                                       height: GardenInventoryLayout.imageHeight(species: stack.species, stage: stack.species.initialStage, isMaterial: true))
                            Text("\(stack.species.title)\(stack.species.propagationTitle)")
                                .font(.headline).lineLimit(1).minimumScaleFactor(0.85)
                            Text(stack.species.propagationQuantity(count: stack.count))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .draggable(GardenDragItem(kind: .leaf, id: stack.firstLeafID))
                        .accessibilityLabel("拖动\(stack.species.title)\(stack.species.propagationTitle)，共\(stack.species.propagationQuantity(count: stack.count))；拖动一份到花盆")
                    }
                }
                .disabled(model.isBusy)
            }
        }
    }
}
