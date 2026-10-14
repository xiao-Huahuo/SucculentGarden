// 拖放只传库存对象 ID；接收端重新检查所有权，避免一片叶子被重复种植。
import CoreTransferable
import UniformTypeIdentifiers
import Foundation

struct GardenDragItem: Codable, Transferable {
    enum Kind: String, Codable { case leaf, plant }
    let kind: Kind
    let id: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .gardenItem)
    }
}

extension UTType {
    static let gardenItem = UTType(exportedAs: "local.littlecomponent.garden.item")
}
