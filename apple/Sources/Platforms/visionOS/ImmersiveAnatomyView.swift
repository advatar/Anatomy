#if os(visionOS)
import SwiftUI

struct ImmersiveAnatomyView: View {
    @Environment(AnatomyAppModel.self) private var model
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        ZStack(alignment: .bottom) {
            OrganRealityView(mode: .immersive)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.selectedOrgan.name)
                        .font(.headline)
                    Text("Look and tap to inspect")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let hotspot = model.selectedHotspot {
                    Label(hotspot.name, systemImage: "scope")
                        .font(.callout.weight(.semibold))
                }

                Button("Leave", systemImage: "rectangle.portrait.and.arrow.right") {
                    Task {
                        await dismissImmersiveSpace()
                        model.isImmersiveSpaceOpen = false
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .glassBackgroundEffect(in: .rect(cornerRadius: 20))
            .padding(.bottom, 36)
        }
        .onDisappear {
            model.isImmersiveSpaceOpen = false
        }
    }
}
#endif
