// 主应用与 Widget 共用花盆深链接，槽位编号统一为 0、1、2。
import Foundation

enum GardenRoute {
    static func url(layoutID: UUID, potID: UUID? = nil) -> URL {
        var parts = URLComponents()
        parts.scheme = "littlecomponent"
        parts.host = "garden"
        parts.queryItems = [URLQueryItem(name: "layout", value: layoutID.uuidString)]
        if let potID { parts.queryItems?.append(URLQueryItem(name: "pot", value: potID.uuidString)) }
        return parts.url!
    }

    static func destination(from url: URL) -> (layoutID: UUID, potID: UUID?)? {
        guard url.scheme == "littlecomponent", url.host == "garden",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let value = items.first(where: { $0.name == "layout" })?.value,
              let layout = UUID(uuidString: value) else { return nil }
        let pot = items.first(where: { $0.name == "pot" })?.value.flatMap(UUID.init(uuidString:))
        return (layout, pot)
    }

    static func url(for slot: Int) -> URL {
        // 调用方只传入三个真实槽位，固定 scheme 和整数组成的 URL 始终有效。
        URL(string: "littlecomponent://garden?slot=\(slot)")!
    }

    static func slot(from url: URL) -> Int? {
        guard url.scheme == "littlecomponent", url.host == "garden",
              let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
                .first(where: { $0.name == "slot" })?.value,
              let slot = Int(value), (0..<3).contains(slot) else { return nil }
        return slot
    }
}
