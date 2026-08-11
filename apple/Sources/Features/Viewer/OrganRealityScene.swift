import CoreGraphics
import os
import RealityKit
import SwiftUI

#if os(macOS)
import AppKit
private typealias PlatformColor = NSColor
#else
import UIKit
private typealias PlatformColor = UIColor
#endif

enum OrganPresentationMode {
    case windowed
    case immersive
}

@MainActor
enum OrganRealityScene {
    static let rootName = "organ-scene-root"
    static let specimenName = "organ-specimen"

    private static let markerPrefix = "hotspot-"
    private static let fittedEdge: Float = 3.8
    private static let logger = Logger(subsystem: "com.advatar.anatomyatelier", category: "RealityAssets")

    static func make(organ: Organ, mode: OrganPresentationMode) async -> Entity {
        let root = Entity()
        root.name = rootName

        let specimen = Entity()
        specimen.name = specimenName
        specimen.orientation = simd_mul(
            simd_quatf(angle: -0.28, axis: SIMD3<Float>(0, 1, 0)),
            simd_quatf(angle: 0.05, axis: SIMD3<Float>(1, 0, 0))
        )
        root.addChild(specimen)

        do {
            let asset = try await OrganAssetStore.shared.entity(for: organ)
            normalize(asset, in: specimen)
        } catch {
            logger.error("Could not load \(organ.assetName, privacy: .public).usdz: \(error.localizedDescription, privacy: .public)")
            specimen.addChild(fallbackModel(for: organ))
        }

        addHotspots(for: organ, to: specimen)
        addLighting(to: root)
        apply(mode: mode, to: root)
        return root
    }

    static func update(
        _ root: Entity,
        selectedHotspotID: Organ.Hotspot.ID?,
        mode: OrganPresentationMode
    ) {
        apply(mode: mode, to: root)
        guard let specimen = root.findEntity(named: specimenName) else { return }

        for child in specimen.children where child.name.hasPrefix(markerPrefix) {
            let id = String(child.name.dropFirst(markerPrefix.count))
            let scale: Float = id == selectedHotspotID ? 1.45 : 1
            child.scale = SIMD3<Float>(repeating: scale)
        }
    }

    static func hotspotID(for entity: Entity) -> Organ.Hotspot.ID? {
        guard entity.name.hasPrefix(markerPrefix) else { return nil }
        return String(entity.name.dropFirst(markerPrefix.count))
    }

    static func markerName(for hotspotID: Organ.Hotspot.ID) -> String {
        markerPrefix + hotspotID
    }

    static func apply(mode: OrganPresentationMode, to root: Entity) {
        switch mode {
        case .windowed:
            // The virtual camera starts at the origin and looks down -Z.
            root.position = SIMD3<Float>(0, 0, -5)
            root.scale = SIMD3<Float>(repeating: 1)
        case .immersive:
            // The normalized 3.8-unit specimen becomes about 38 cm tall.
            root.position = SIMD3<Float>(0, 1.25, -1.05)
            root.scale = SIMD3<Float>(repeating: 0.1)
        }
    }

    private static func normalize(_ asset: Entity, in specimen: Entity) {
        specimen.addChild(asset)
        let bounds = asset.visualBounds(recursive: true, relativeTo: specimen)
        let longestEdge = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
        guard longestEdge.isFinite, longestEdge > 0 else { return }

        let uniformScale = fittedEdge / longestEdge
        asset.position = (asset.position - bounds.center) * uniformScale
        asset.scale *= SIMD3<Float>(repeating: uniformScale)
    }

    private static func addHotspots(for organ: Organ, to specimen: Entity) {
        for hotspot in organ.hotspots {
            let marker = ModelEntity(
                mesh: .generateSphere(radius: 0.065),
                materials: [material(for: hotspot.color)]
            )
            marker.name = markerName(for: hotspot.id)
            marker.position = hotspot.position
            marker.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.12)]))
            marker.components.set(InputTargetComponent(allowedInputTypes: .all))
            specimen.addChild(marker)
        }
    }

    private static func addLighting(to root: Entity) {
        let light = Entity()
        light.name = "key-light"
        light.components.set(DirectionalLightComponent(color: .white, intensity: 2_400))
        light.orientation = simd_quatf(
            angle: -0.72,
            axis: simd_normalize(SIMD3<Float>(1, -0.6, 0))
        )
        root.addChild(light)
    }

    private static func fallbackModel(for organ: Organ) -> Entity {
        let material = material(for: organ.accent)
        let model = ModelEntity(mesh: .generateSphere(radius: 1.25), materials: [material])
        model.name = "asset-load-fallback"
        model.scale = SIMD3<Float>(0.82, 1.15, 0.72)
        return model
    }

    private static func material(for accent: Organ.Accent) -> SimpleMaterial {
        let color = PlatformColor(
            red: accent.red,
            green: accent.green,
            blue: accent.blue,
            alpha: 1
        )
        return SimpleMaterial(color: color, roughness: 0.35, isMetallic: false)
    }
}
