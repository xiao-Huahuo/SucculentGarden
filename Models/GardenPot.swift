// 盆占用的是组件空间，植株占用的是盆内位置；两者使用独立的库存身份。
import Foundation

enum GardenPotKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case ordinary, wide, long
    var id: String { rawValue }
    var title: String { switch self { case .ordinary: "普通盆"; case .wide: "宽盆"; case .long: "长盆" } }
    var space: Int { switch self { case .ordinary: 1; case .wide: 2; case .long: 3 } }
    var capacity: Int { switch self { case .ordinary: 1; case .wide: 3; case .long: 5 } }
    var price: Int { switch self { case .ordinary: 50; case .wide: 200; case .long: 500 } }
    var assetName: String { switch self { case .ordinary: "SucculentPot"; case .wide: "WidePot47"; case .long: "LongPot47" } }
}

enum GardenLayoutSize: String, Codable, CaseIterable, Sendable {
    case small, medium
    var title: String { self == .small ? "小号" : "中号" }
    var space: Int { self == .small ? 1 : 3 }
}

struct GardenPot: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let number: Int
    let kind: GardenPotKind
    var plants: [UUID?]
    var title: String { "盆栽\(number)" }
    var isEmpty: Bool { plants.allSatisfy { $0 == nil } }

    init(id: UUID = UUID(), number: Int, kind: GardenPotKind) {
        self.id = id
        self.number = number
        self.kind = kind
        plants = Array(repeating: nil, count: kind.capacity)
    }

    static let originalIDs = (1...3).map { UUID(uuidString: "00000000-0000-0000-0000-00000000010\($0)")! }
}

struct GardenLayout: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let size: GardenLayoutSize
    var pots: [UUID]
    static let originalID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let original = GardenLayout(id: originalID, name: "桌面花盆", size: .medium, pots: GardenPot.originalIDs)
}
