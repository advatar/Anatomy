import Foundation

struct Organ: Identifiable, Hashable, Sendable {
    struct Accent: Hashable, Sendable {
        let red: Double
        let green: Double
        let blue: Double
    }

    struct Hotspot: Identifiable, Hashable, Sendable {
        let id: String
        let name: String
        let scientificName: String
        let position: SIMD3<Float>
        let color: Accent
    }

    let id: String
    let name: String
    let scientificName: String
    let summary: String
    let systemImage: String
    let accent: Accent
    let hotspots: [Hotspot]

    var assetName: String { id }

    func hotspot(id: Hotspot.ID?) -> Hotspot? {
        guard let id else { return nil }
        return hotspots.first(where: { $0.id == id })
    }
}
