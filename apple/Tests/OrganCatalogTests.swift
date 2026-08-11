import XCTest
import RealityKit
@testable import AnatomyAtelier

final class OrganCatalogTests: XCTestCase {
    func testCatalogContainsUniqueIdentifiers() {
        let identifiers = OrganCatalog.all.map(\.id)
        XCTAssertEqual(identifiers.count, 9)
        XCTAssertEqual(Set(identifiers).count, identifiers.count)
    }

    func testEveryOrganHasUniquelyNamedHotspots() {
        for organ in OrganCatalog.all {
            let identifiers = organ.hotspots.map(\.id)
            XCTAssertFalse(identifiers.isEmpty, "\(organ.name) has no hotspots")
            XCTAssertEqual(Set(identifiers).count, identifiers.count, "\(organ.name) has duplicate hotspots")
        }
    }

    @MainActor
    func testAppModelSelectsTheFirstOrganByDefault() {
        let model = AnatomyAppModel()
        XCTAssertEqual(model.selectedOrgan.id, "heart")
    }

    @MainActor
    func testSelectingAnOrganClearsTheSelectedPart() throws {
        let model = AnatomyAppModel()
        model.selectedHotspotID = "left-ventricle"
        let brain = try XCTUnwrap(model.organs.first(where: { $0.id == "brain" }))

        model.select(brain)

        XCTAssertEqual(model.selectedOrganID, "brain")
        XCTAssertNil(model.selectedHotspotID)
    }

    @MainActor
    func testWindowedSpecimenStartsInFrontOfVirtualCamera() {
        let root = Entity()
        OrganRealityScene.apply(mode: .windowed, to: root)

        XCTAssertEqual(root.position.x, 0, accuracy: 0.001)
        XCTAssertEqual(root.position.y, 0, accuracy: 0.001)
        XCTAssertLessThan(root.position.z, -1)
    }

    @MainActor
    func testEveryCatalogAssetLoadsAsRealityKitContent() async throws {
        for organ in OrganCatalog.all {
            let entity = try await OrganAssetStore.shared.entity(for: organ)
            let bounds = entity.visualBounds(recursive: true, relativeTo: entity)
            XCTAssertGreaterThan(bounds.extents.x, 0, "\(organ.name) has no visible width")
            XCTAssertGreaterThan(bounds.extents.y, 0, "\(organ.name) has no visible height")
            XCTAssertGreaterThan(bounds.extents.z, 0, "\(organ.name) has no visible depth")
        }
    }

    @MainActor
    func testSceneCarriesAuthoredHotspotsIntoNormalizedAssetSpace() async {
        let organ = OrganCatalog.all[0]
        let root = await OrganRealityScene.make(organ: organ, mode: .windowed)

        XCTAssertNil(root.findEntity(named: "asset-load-fallback"))
        for hotspot in organ.hotspots {
            guard let marker = root.findEntity(named: OrganRealityScene.markerName(for: hotspot.id)) else {
                XCTFail("Missing \(hotspot.name) marker")
                continue
            }
            XCTAssertEqual(marker.position.x, hotspot.position.x, accuracy: 0.001)
            XCTAssertEqual(marker.position.y, hotspot.position.y, accuracy: 0.001)
            XCTAssertEqual(marker.position.z, hotspot.position.z, accuracy: 0.001)
        }
    }
}
