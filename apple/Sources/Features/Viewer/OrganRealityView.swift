import RealityKit
import SwiftUI

struct OrganRealityView: View {
    let mode: OrganPresentationMode
    @Environment(AnatomyAppModel.self) private var model

    var body: some View {
        #if os(visionOS)
        visionRealityView
            .id(model.selectedOrganID)
        #else
        cameraRealityView
            .id(model.selectedOrganID)
        #endif
    }

    #if os(visionOS)
    private var visionRealityView: some View {
        RealityView { (content: inout RealityViewContent) in
            let root = await OrganRealityScene.make(organ: model.selectedOrgan, mode: mode)
            content.add(root)
        } update: { content in
            guard let root = content.entities.first(where: { $0.name == OrganRealityScene.rootName }) else { return }
            OrganRealityScene.update(
                root,
                selectedHotspotID: model.selectedHotspotID,
                mode: mode
            )
        }
        .gesture(selectionGesture)
    }
    #else
    private var cameraRealityView: some View {
        RealityView { (content: inout RealityViewCameraContent) in
            let root = await OrganRealityScene.make(organ: model.selectedOrgan, mode: mode)
            content.add(root)
            content.camera = .virtual
            content.cameraTarget = root
        } update: { content in
            guard let root = content.entities.first(where: { $0.name == OrganRealityScene.rootName }) else { return }
            OrganRealityScene.update(
                root,
                selectedHotspotID: model.selectedHotspotID,
                mode: mode
            )
            content.cameraTarget = root
        }
        #if !os(tvOS)
        .gesture(selectionGesture)
        .realityViewCameraControls(.orbit)
        #endif
    }
    #endif

    #if !os(tvOS)
    private var selectionGesture: some Gesture {
        TapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                guard let hotspotID = OrganRealityScene.hotspotID(for: value.entity) else { return }
                model.selectedHotspotID = hotspotID
            }
    }
    #endif
}
