// 显示真实等待时长：阶段基础成长时间除以已保存的有效速度（全局倍率/x/y），主页面每秒重新计算倒计时。
import Foundation

enum GardenGrowthTime {
    static func interval(species: SucculentSpecies, from stage: SucculentStage, to next: SucculentStage, rate: Double) -> TimeInterval {
        (species.startSeconds(for: next) - species.startSeconds(for: stage)) / rate
    }

    static func remaining(for plant: SucculentPlant, at date: Date, rate: Double) -> TimeInterval? {
        plant.transitionDates(after: date, rate: rate).first?.timeIntervalSince(date)
    }

    static func text(_ seconds: TimeInterval) -> String {
        var value = max(0, Int(seconds.rounded(.up)))
        let units = [(86_400, "天"), (3_600, "小时"), (60, "分"), (1, "秒")]
        var parts: [String] = []
        for (size, title) in units {
            let count = value / size
            value %= size
            if count > 0 { parts.append("\(count)\(title)") }
        }
        return parts.isEmpty ? "0秒" : parts.joined()
    }
}
