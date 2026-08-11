enum OrganCatalog {
    static let all: [Organ] = [
        Organ(
            id: "heart",
            name: "Heart",
            scientificName: "Cor",
            summary: "A muscular pump that sustains circulation through four coordinated chambers.",
            systemImage: "heart.fill",
            accent: .init(red: 0.72, green: 0.16, blue: 0.18),
            hotspots: OrganHotspotCatalog.heart
        ),
        Organ(
            id: "brain",
            name: "Brain",
            scientificName: "Encephalon",
            summary: "The central organ of perception, movement, memory, and cognition.",
            systemImage: "brain.head.profile",
            accent: .init(red: 0.72, green: 0.39, blue: 0.46),
            hotspots: OrganHotspotCatalog.brain
        ),
        Organ(
            id: "lungs",
            name: "Lungs",
            scientificName: "Pulmones",
            summary: "Paired respiratory organs that exchange oxygen and carbon dioxide.",
            systemImage: "lungs.fill",
            accent: .init(red: 0.73, green: 0.35, blue: 0.38),
            hotspots: OrganHotspotCatalog.lungs
        ),
        Organ(
            id: "liver",
            name: "Liver",
            scientificName: "Hepar",
            summary: "A metabolic organ that processes nutrients, toxins, and blood proteins.",
            systemImage: "cross.case.fill",
            accent: .init(red: 0.48, green: 0.18, blue: 0.14),
            hotspots: OrganHotspotCatalog.liver
        ),
        Organ(
            id: "kidneys",
            name: "Kidneys",
            scientificName: "Renes",
            summary: "Paired filters that regulate fluid balance and remove metabolic waste.",
            systemImage: "drop.fill",
            accent: .init(red: 0.56, green: 0.18, blue: 0.22),
            hotspots: OrganHotspotCatalog.kidneys
        ),
        Organ(
            id: "eyeball",
            name: "Eye",
            scientificName: "Oculus",
            summary: "An optical organ that focuses light and translates it into neural signals.",
            systemImage: "eye.fill",
            accent: .init(red: 0.25, green: 0.46, blue: 0.58),
            hotspots: OrganHotspotCatalog.eyeball
        ),
        Organ(
            id: "intestine",
            name: "Intestine",
            scientificName: "Intestinum",
            summary: "A folded tract specialized for digestion, absorption, and transport.",
            systemImage: "waveform.path.ecg",
            accent: .init(red: 0.69, green: 0.38, blue: 0.32),
            hotspots: OrganHotspotCatalog.intestine
        ),
        Organ(
            id: "pancreas",
            name: "Pancreas",
            scientificName: "Pancreas",
            summary: "A gland that coordinates digestion and blood-glucose regulation.",
            systemImage: "pill.fill",
            accent: .init(red: 0.77, green: 0.48, blue: 0.30),
            hotspots: OrganHotspotCatalog.pancreas
        ),
        Organ(
            id: "skin",
            name: "Skin",
            scientificName: "Cutis",
            summary: "A layered protective organ that senses and regulates the body surface.",
            systemImage: "square.3.layers.3d",
            accent: .init(red: 0.70, green: 0.46, blue: 0.37),
            hotspots: OrganHotspotCatalog.skin
        ),
    ]
}
