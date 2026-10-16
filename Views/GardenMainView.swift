// 访达式侧栏、工具栏与图标区域；右下角种植区使用桌面组件同一份植株视图与数据。
import SwiftUI

struct GardenMainView: View {
    @Bindable var model: GardenModel

    private var selection: Binding<GardenSection?> {
        Binding(get: { model.section }, set: { if let value = $0 { model.section = value } })
    }

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                Text(model.garden.map { "钱: $ \($0.money)" } ?? "钱: $ —")
                    .font(.headline)
                    .monospacedDigit()
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .accessibilityLabel("当前金钱 \(model.garden?.money.description ?? "暂不可用")")
                List(GardenSection.allCases, selection: selection) { section in
                    Label(section.rawValue, systemImage: section.symbol).tag(section)
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 230)
            .navigationTitle("多肉花园")
        } detail: {
            if let garden = model.garden {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            if model.section == .shop || model.section == .collection {
                                morphologySidebar
                            }
                            ScrollView {
                                sectionContent(garden: garden, date: context.date,
                                               availableHeight: max(0, geometry.size.height - 48))
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                    .padding(24)
                                    // 浮层不占整行；末尾内容仍可滚到花盆上方完整查看。
                                    .padding(.bottom, GardenPlantingLayout.scrollClearance)
                            }
                        }
                        .overlay(alignment: .bottomTrailing) {
                            GardenPlantingTray(model: model, garden: garden, date: context.date)
                                .frame(width: min(GardenPlantingLayout.width, geometry.size.width - 40))
                                .padding(20)
                        }
                    }
                }
                .navigationTitle(model.section.rawValue)
            } else {
                ContentUnavailableView {
                    Label("花园正在打开", systemImage: "leaf")
                } description: {
                    Text(model.errorMessage ?? "正在读取已保存的多肉。")
                } actions: {
                    Button("重新读取") { Task { await model.load() } }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $model.search, placement: .toolbar, prompt: "搜索多肉")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if model.section == .shop || model.section == .collection {
                    HStack(spacing: 10) {
                        Picker("按形态筛选", selection: morphologySelection) {
                            Text("全部形态").tag(nil as SucculentMorphology?)
                            ForEach(SucculentMorphology.allCases) { morphology in
                                Text(morphology.title).tag(Optional(morphology))
                            }
                        }
                        .pickerStyle(.menu)
                        .help("按形态筛选")
                        .accessibilityLabel("按形态筛选")
                        GardenStagePicker(model: model)
                        if model.section == .collection {
                            Button("添加多肉") { model.openShop() }
                        }
                    }
                } else if model.section == .leaves {
                    Button("获取叶片") { model.openShop(stage: .sprout) }
                }
            }
        }
        .frame(minWidth: 760, minHeight: 600)
        .task { if model.garden == nil { await model.load() } }
        .overlay(alignment: .topTrailing) {
            GardenNoticeBanner(model: model).padding(12)
        }
        .animation(.easeInOut(duration: 0.18), value: model.notice?.id)
    }

    private var morphologySidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("形态").font(.headline)
                Spacer()
                Button { morphologySelection.wrappedValue = nil } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(morphologySelection.wrappedValue == nil)
                .help("取消形态筛选")
                .accessibilityLabel("取消形态筛选")
                .accessibilityIdentifier("garden.morphology.clear")
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 8)
            List(selection: morphologySelection) {
                ForEach(SucculentMorphology.allCases) { morphology in
                    Text(morphology.title).tag(morphology)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .accessibilityLabel(model.section == .shop ? "商店形态分类" : "我的多肉形态分类")
        }
        .frame(width: 112)
    }

    private var morphologySelection: Binding<SucculentMorphology?> {
        Binding(
            get: { model.section == .shop ? model.shopMorphology : model.collectionMorphology },
            set: { if model.section == .shop { model.shopMorphology = $0 } else { model.collectionMorphology = $0 } }
        )
    }

    @ViewBuilder
    private func sectionContent(garden: SucculentGarden, date: Date, availableHeight: CGFloat) -> some View {
        switch model.section {
        case .shop: GardenShopView(model: model, garden: garden, date: date, availableHeight: availableHeight)
        case .collection: GardenCollectionView(model: model, garden: garden, date: date, availableHeight: availableHeight)
        case .leaves: GardenLeavesView(model: model, garden: garden, date: date, availableHeight: availableHeight)
        case .pots: GardenPotsView(model: model, garden: garden)
        case .settings: GardenSettingsView(model: model)
        }
    }
}
