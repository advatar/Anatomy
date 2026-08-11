import SwiftUI

@main
struct AnatomyAtelierApp: App {
    @State private var model = AnatomyAppModel()

    #if os(visionOS)
    @State private var immersionStyle: ImmersionStyle = .mixed
    #endif

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environment(model)
        }

        #if os(visionOS)
        ImmersiveSpace(id: ImmersiveSpaceID.anatomy) {
            ImmersiveAnatomyView()
                .environment(model)
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed, .full)
        #endif
    }
}

enum ImmersiveSpaceID {
    static let anatomy = "anatomy-atelier-immersive-space"
}
