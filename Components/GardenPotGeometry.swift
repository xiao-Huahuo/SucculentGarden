// 盆面内采用前后两排根点；用同一几何数据绘制和命中拖放，避免视图与落点错位。
import Foundation

enum GardenPotGeometry {
    static func roots(kind: GardenPotKind, width: CGFloat, height: CGFloat) -> [CGPoint] {
        let unit = width / CGFloat(kind.space)
        let factor: CGFloat = switch kind { case .ordinary: 0.45; case .wide: 1.1; case .long: 1.85 }
        let potWidth = unit * factor
        let aspect: CGFloat = switch kind { case .ordinary: 878 / 885; case .wide: 608 / 1624; case .long: 504 / 1616 }
        let potHeight = potWidth * aspect
        let left = (width - potWidth) / 2
        let top = height - potHeight
        let normalized: [CGPoint] = switch kind {
        case .ordinary: [CGPoint(x: 0.5, y: 0.29)]
        case .wide: [CGPoint(x: 0.28, y: 0.23), CGPoint(x: 0.72, y: 0.23), CGPoint(x: 0.5, y: 0.41)]
        case .long: [CGPoint(x: 0.21, y: 0.22), CGPoint(x: 0.5, y: 0.22), CGPoint(x: 0.79, y: 0.22),
                     CGPoint(x: 0.35, y: 0.40), CGPoint(x: 0.65, y: 0.40)]
        }
        return normalized.map { CGPoint(x: left + $0.x * potWidth, y: top + $0.y * potHeight) }
    }

    static func potSize(kind: GardenPotKind, width: CGFloat) -> CGSize {
        let factor: CGFloat = switch kind { case .ordinary: 0.45; case .wide: 1.1; case .long: 1.85 }
        let aspect: CGFloat = switch kind { case .ordinary: 878 / 885; case .wide: 608 / 1624; case .long: 504 / 1616 }
        let w = width / CGFloat(kind.space) * factor
        return CGSize(width: w, height: w * aspect)
    }

    static func nearestPosition(kind: GardenPotKind, point: CGPoint, width: CGFloat, height: CGFloat) -> Int {
        let points = roots(kind: kind, width: width, height: height)
        return points.indices.min { a, b in
            hypot(points[a].x - point.x, points[a].y - point.y) < hypot(points[b].x - point.x, points[b].y - point.y)
        } ?? 0
    }

    static func frames(layout: GardenLayout, garden: SucculentGarden, width: CGFloat) -> [(pot: GardenPot, rect: CGRect)] {
        let unit = width / CGFloat(layout.size.space)
        var x: CGFloat = 0
        return layout.pots.compactMap { id in
            guard let pot = garden.pot(id: id) else { return nil }
            let w = unit * CGFloat(pot.kind.space)
            defer { x += w }
            return (pot, CGRect(x: x, y: 0, width: w, height: 100))
        }
    }
}
