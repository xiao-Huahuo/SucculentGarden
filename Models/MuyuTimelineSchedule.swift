// 预先归档未来七个本地午夜，并每天请求更新；点击后的时间线仍保留跨日条目。
import Foundation

enum MuyuTimelineSchedule {
    static func dates(from date: Date, calendar: Calendar = .autoupdatingCurrent) -> [Date] {
        [date] + (1...7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: date))
        }
    }

    static func nextMidnight(after date: Date, calendar: Calendar = .autoupdatingCurrent) -> Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
    }
}
