// 100 句本地箴言；以安装种子和本地日期确定每日选择，重开与时间线重载不会换句子。
import Foundation

struct ProverbCatalog: Sendable {
    let sayings: [String]

    init(sayings: [String]) throws {
        guard sayings.count == 100, Set(sayings).count == 100,
              sayings.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw CatalogError.invalidCatalog
        }
        self.sayings = sayings
    }

    static func bundled() throws -> ProverbCatalog {
        let bundle = Bundle(for: ResourceAnchor.self)
        guard let url = bundle.url(forResource: "proverbs", withExtension: "json") else {
            throw CatalogError.missingResource
        }
        return try ProverbCatalog(sayings: JSONDecoder().decode([String].self, from: Data(contentsOf: url)))
    }

    func saying(for date: Date, seed: UInt64, calendar: Calendar = .autoupdatingCurrent) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let day = "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
        var hash = seed ^ 14_695_981_039_346_656_037
        for byte in day.utf8 {
            hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        return sayings[Int(hash % UInt64(sayings.count))]
    }

    enum CatalogError: Error {
        case invalidCatalog
        case missingResource
    }
}

private final class ResourceAnchor: NSObject {}
