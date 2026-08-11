import AnatomyRealityContent
import RealityKit

@MainActor
final class OrganAssetStore {
    static let shared = OrganAssetStore()

    private let cacheLimit = 3
    private var prototypes: [Organ.ID: Entity] = [:]
    private var inFlight: [Organ.ID: Task<Entity, any Error>] = [:]
    private var recency: [Organ.ID] = []

    private init() {}

    func entity(for organ: Organ) async throws -> Entity {
        let prototype = try await prototype(for: organ)
        return prototype.clone(recursive: true)
    }

    func warm(_ organs: [Organ]) async {
        for organ in organs {
            guard !Task.isCancelled else { return }
            _ = try? await prototype(for: organ)
        }
    }

    private func prototype(for organ: Organ) async throws -> Entity {
        if let cached = prototypes[organ.id] {
            touch(organ.id)
            return cached
        }

        if let loading = inFlight[organ.id] {
            let entity = try await loading.value
            touch(organ.id)
            return entity
        }

        let assetName = organ.assetName
        let loading = Task { @MainActor in
            try await Entity(named: assetName, in: anatomyRealityContentBundle)
        }
        inFlight[organ.id] = loading

        do {
            let entity = try await loading.value
            inFlight[organ.id] = nil
            prototypes[organ.id] = entity
            touch(organ.id)
            trimCache()
            return entity
        } catch {
            inFlight[organ.id] = nil
            throw error
        }
    }

    private func touch(_ id: Organ.ID) {
        recency.removeAll(where: { $0 == id })
        recency.append(id)
    }

    private func trimCache() {
        while recency.count > cacheLimit {
            let evicted = recency.removeFirst()
            prototypes[evicted] = nil
        }
    }
}
