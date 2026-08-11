#if os(visionOS)
import SwiftUI

struct VisionImmersionButton: View {
    @Environment(AnatomyAppModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        Button {
            Task {
                if model.isImmersiveSpaceOpen {
                    await dismissImmersiveSpace()
                    model.isImmersiveSpaceOpen = false
                } else {
                    let result = await openImmersiveSpace(id: ImmersiveSpaceID.anatomy)
                    if case .opened = result {
                        model.isImmersiveSpaceOpen = true
                    }
                }
            }
        } label: {
            Label(
                model.isImmersiveSpaceOpen ? "Leave Immersive" : "Enter Immersive",
                systemImage: model.isImmersiveSpaceOpen ? "arrow.down.right.and.arrow.up.left" : "vision.pro"
            )
        }
    }
}
#endif
