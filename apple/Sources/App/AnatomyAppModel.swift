import Foundation
import Observation

@MainActor
@Observable
final class AnatomyAppModel {
    private(set) var organs: [Organ]
    var selectedOrganID: Organ.ID
    var selectedHotspotID: Organ.Hotspot.ID?
    var isImmersiveSpaceOpen = false

    init(organs: [Organ] = OrganCatalog.all) {
        precondition(!organs.isEmpty, "Anatomy Atelier requires at least one organ")
        self.organs = organs
        selectedOrganID = organs[0].id
    }

    var selectedOrgan: Organ {
        organs.first(where: { $0.id == selectedOrganID }) ?? organs[0]
    }

    var selectedHotspot: Organ.Hotspot? {
        selectedOrgan.hotspot(id: selectedHotspotID)
    }

    func select(_ organ: Organ) {
        selectedOrganID = organ.id
        selectedHotspotID = nil
    }
}
