import SwiftUI

struct LibraryView: View {
    @Environment(AnatomyAppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            GeometryReader { proxy in
                let wide = proxy.size.width >= 820

                Group {
                    if wide {
                        HStack(spacing: 0) {
                            organRail(selection: $model.selectedOrganID)
                                .frame(width: min(330, proxy.size.width * 0.3))
                            Divider()
                            viewer
                        }
                    } else {
                        VStack(spacing: 0) {
                            organStrip(selection: $model.selectedOrganID)
                            Divider()
                            viewer
                        }
                    }
                }
                .background(AtelierPalette.canvas)
            }
            .navigationTitle("Anatomy Atelier")
            #if os(visionOS)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    VisionImmersionButton()
                }
            }
            #endif
        }
    }

    private var viewer: some View {
        VStack(spacing: 0) {
            OrganRealityView(mode: .windowed)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(model.selectedOrgan.name)
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    Spacer()
                    Text(model.selectedOrgan.scientificName.uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(.secondary)
                }
                Text(model.selectedOrgan.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
                if let hotspot = model.selectedHotspot {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Selected: \(hotspot.name)", systemImage: "scope")
                            .font(.callout.weight(.semibold))
                        Text(hotspot.scientificName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(AtelierPalette.ink)
                }
            }
            .padding(24)
            .background(.regularMaterial)
        }
        .task(id: model.selectedOrganID) {
            await OrganAssetStore.shared.warm(organsToWarm)
        }
    }

    private var organsToWarm: [Organ] {
        guard let selectedIndex = model.organs.firstIndex(where: { $0.id == model.selectedOrganID }) else {
            return [model.selectedOrgan]
        }
        return (0..<min(3, model.organs.count)).map { offset in
            model.organs[(selectedIndex + offset) % model.organs.count]
        }
    }

    private func organRail(selection: Binding<Organ.ID>) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                introduction
                ForEach(model.organs) { organ in
                    OrganButton(organ: organ, isSelected: organ.id == selection.wrappedValue) {
                        model.select(organ)
                    }
                }
            }
            .padding(20)
        }
    }

    private func organStrip(selection: Binding<Organ.ID>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(model.organs) { organ in
                    OrganButton(organ: organ, isSelected: organ.id == selection.wrappedValue) {
                        model.select(organ)
                    }
                    .frame(width: 180)
                }
            }
            .padding(14)
        }
        .frame(height: 100)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THE COLLECTION")
                .font(.caption.weight(.bold))
                .tracking(2.4)
                .foregroundStyle(AtelierPalette.rose)
            Text("Learn anatomy like an artist.")
                .font(.system(.title2, design: .serif, weight: .semibold))
            Text("Select a specimen, then explore it in native three-dimensional space.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 12)
    }
}

private struct OrganButton: View {
    let organ: Organ
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: organ.systemImage)
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(isSelected ? .white : AtelierPalette.rose)
                VStack(alignment: .leading, spacing: 2) {
                    Text(organ.name)
                        .font(.headline)
                    Text(organ.scientificName)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.78) : .secondary)
                }
                Spacer(minLength: 4)
            }
            .padding(12)
            .contentShape(.rect)
            .background(isSelected ? AtelierPalette.ink : .clear, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Explore \(organ.name)")
    }
}

enum AtelierPalette {
    static let canvas = Color(red: 0.969, green: 0.941, blue: 0.906)
    static let ink = Color(red: 0.176, green: 0.118, blue: 0.122)
    static let rose = Color(red: 0.637, green: 0.247, blue: 0.251)
}
