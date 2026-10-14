// 倍率只改变之后的成长速度；领取限额仍按本地自然日计算。
import SwiftUI

struct GardenSettingsView: View {
    let model: GardenModel
    @AppStorage(GardenMultiplierDisplay.showXKey) private var showX = false
    @AppStorage(GardenMultiplierDisplay.showYKey) private var showY = true
    @State private var rate = 1.0
    @State private var intervalSpecies: SucculentSpecies = .huangli

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("成长速率").font(.headline)
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Text("倍率").fixedSize()
                        TextField("", value: $rate,
                                  format: .number.precision(.fractionLength(0...2)))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .accessibilityLabel("成长倍率")
                        Text("×").fixedSize()
                        Button("应用") { Task { await model.changeRate(rate) } }
                            .disabled(model.isBusy)
                        Spacer(minLength: 0)
                    }
                    HStack(spacing: 8) {
                        ForEach([1.0, 10.0, 100.0, 1000.0], id: \.self) { value in
                            Button("\(Int(value))×") {
                                rate = value
                                Task { await model.changeRate(value) }
                            }
                                .disabled(model.isBusy)
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 20) {
                Toggle("显示x", isOn: $showX)
                    .accessibilityIdentifier("garden.multiplier.showX")
                Toggle("显示y", isOn: $showY)
                    .accessibilityIdentifier("garden.multiplier.showY")
                Spacer(minLength: 0)
            }
            .toggleStyle(.switch)
            GardenMultiplierControls(model: model)
            Text("成长间隔").font(.headline)
            Picker("多肉", selection: $intervalSpecies) {
                ForEach(SucculentSpecies.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 280, alignment: .leading)
            let garden = model.garden ?? SucculentGarden()
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                ForEach(0..<(intervalSpecies.stages.count - 1), id: \.self) { index in
                    let current = intervalSpecies.stages[index]
                    let next = intervalSpecies.stages[index + 1]
                    let seconds = GardenGrowthTime.interval(species: intervalSpecies, from: current, to: next,
                                                            rate: garden.effectiveRate(for: intervalSpecies))
                    GridRow {
                        Text("\(intervalSpecies.stageTitle(for: current)) → \(intervalSpecies.stageTitle(for: next))")
                        Text(GardenGrowthTime.text(seconds))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .groupBoxStyle(PlainGardenGroupBoxStyle())
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .onAppear { rate = model.garden?.growthRate ?? 1 }
        .onChange(of: model.garden?.growthRate) { _, value in rate = value ?? 1 }
    }
}

private struct PlainGardenGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

// 每次仅应用选中的一项覆盖；先结算旧进度，再写入乘数，不更改价格和领取额度。
private struct GardenMultiplierControls: View {
    let model: GardenModel
    @State private var morphology: SucculentMorphology = .crassulaceaeType
    @State private var species: SucculentSpecies = .huangli
    @State private var x = 1.0
    @State private var y = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("类型时间乘数 x").font(.headline)
            HStack(spacing: 10) {
                Picker("形态", selection: $morphology) {
                    ForEach(SucculentMorphology.allCases) { Text($0.title).tag($0) }
                }
                .labelsHidden().frame(width: 140)
                multiplierField($x, label: "类型时间乘数 x")
                Button("应用") { apply(isType: true, reset: false) }
                    .accessibilityIdentifier("garden.multiplier.x.apply")
                Button("恢复默认") { apply(isType: true, reset: true) }
                Spacer(minLength: 0)
            }
            Text("植物时间乘数 y").font(.headline)
            HStack(spacing: 10) {
                Picker("品种", selection: $species) {
                    ForEach(SucculentSpecies.allCases) { Text($0.title).tag($0) }
                }
                .labelsHidden().frame(width: 140)
                multiplierField($y, label: "植物时间乘数 y")
                Button("应用") { apply(isType: false, reset: false) }
                    .accessibilityIdentifier("garden.multiplier.y.apply")
                Button("恢复默认") { apply(isType: false, reset: true) }
                Spacer(minLength: 0)
            }
            Text("实际间隔 = 基础间隔 × x × y ÷ 成长倍率")
                .font(.caption).foregroundStyle(.secondary)
            Text("x、y 越大成长越慢。y 初值参考生长特性估计，可自行调整。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .disabled(model.isBusy || model.garden == nil)
        .onAppear { refresh() }
        .onChange(of: morphology) { _, _ in x = model.garden?.growthMultipliers.x(for: morphology) ?? morphology.defaultTimeMultiplier }
        .onChange(of: species) { _, _ in y = model.garden?.growthMultipliers.y(for: species) ?? species.defaultTimeMultiplier }
        .onChange(of: model.garden?.growthMultipliers) { _, _ in refresh() }
    }

    private func multiplierField(_ value: Binding<Double>, label: String) -> some View {
        TextField("", value: value, format: .number.precision(.fractionLength(2)))
            .textFieldStyle(.roundedBorder).frame(width: 74)
            .accessibilityLabel(label)
    }

    private func refresh() {
        x = model.garden?.growthMultipliers.x(for: morphology) ?? morphology.defaultTimeMultiplier
        y = model.garden?.growthMultipliers.y(for: species) ?? species.defaultTimeMultiplier
    }

    private func apply(isType: Bool, reset: Bool) {
        guard var multipliers = model.garden?.growthMultipliers else { return }
        if isType {
            if reset { x = morphology.defaultTimeMultiplier }
            multipliers.morphology[morphology.rawValue] = reset ? nil : x
        } else {
            if reset { y = species.defaultTimeMultiplier }
            multipliers.species[species.rawValue] = reset ? nil : y
        }
        let message = reset ? "\(isType ? "类型" : "植物")时间乘数已恢复默认" : "\(isType ? "类型" : "植物")时间乘数已保存，成长间隔已更新"
        Task { await model.changeMultipliers(multipliers, message: message) }
    }
}
