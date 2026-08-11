enum OrganHotspotCatalog {
    static let heart = [
        hotspot("aorta", "Aorta", "Aorta", -0.35, 1.65, 0.55, 0xee7c6a),
        hotspot("left-atrium", "Left atrium", "Atrium sinistrum", 0.82, 0.65, 0.50, 0xf2a33b),
        hotspot("right-atrium", "Right atrium", "Atrium dextrum", -0.90, 0.35, 0.55, 0x6393d8),
        hotspot("left-ventricle", "Left ventricle", "Ventriculus sinister", 0.70, -0.75, 0.65, 0xf2a33b),
        hotspot("right-ventricle", "Right ventricle", "Ventriculus dexter", -0.65, -0.68, 0.66, 0xee7c6a),
        hotspot("mitral", "Mitral valve", "Valva atrioventricularis sinistra", 0.18, -1.35, 0.48, 0xd89bc4),
    ]

    static let brain = [
        hotspot("frontal", "Frontal lobe", "Lobus frontalis", -0.70, 0.65, 0.80, 0xee7c6a),
        hotspot("parietal", "Parietal lobe", "Lobus parietalis", 0.15, 1.10, 0.65, 0xf2a33b),
        hotspot("temporal", "Temporal lobe", "Lobus temporalis", 0.75, -0.10, 0.82, 0x6393d8),
        hotspot("cerebellum", "Cerebellum", "Cerebellum", 0.72, -0.90, 0.55, 0xd89bc4),
    ]

    static let lungs = [
        hotspot("trachea", "Trachea", "Trachea", 0, 1.60, 0.20, 0x6393d8),
        hotspot("right-lung", "Right lung", "Pulmo dexter", -1.20, 0.10, 0.70, 0xee7c6a),
        hotspot("left-lung", "Left lung", "Pulmo sinister", 1.20, 0.10, 0.70, 0xf2a33b),
        hotspot("bronchus", "Primary bronchus", "Bronchus principalis", -0.03, 0.30, 0.35, 0xd89bc4),
        hotspot("base", "Lung base", "Basis pulmonis", -1.14, -1.20, 1.00, 0x7fa88a),
    ]

    static let liver = [
        hotspot("right-lobe", "Right lobe", "Lobus hepatis dexter", -0.75, 0.35, 0.75, 0xee7c6a),
        hotspot("left-lobe", "Left lobe", "Lobus hepatis sinister", 0.85, 0.25, 0.75, 0xf2a33b),
        hotspot("portal", "Portal vein", "Vena portae hepatis", 0.10, -0.30, 0.82, 0x6393d8),
    ]

    static let kidneys = [
        hotspot("cortex", "Renal cortex", "Cortex renalis", -0.90, 0.55, 0.70, 0xee7c6a),
        hotspot("medulla", "Renal medulla", "Medulla renalis", 0.85, 0.20, 0.70, 0xf2a33b),
        hotspot("ureter", "Ureter", "Ureter", 0.40, -1.10, 0.50, 0x6393d8),
    ]

    static let eyeball = [
        hotspot("cornea", "Cornea", "Cornea", -0.94, 0.05, 1.47, 0x6393d8),
        hotspot("iris", "Iris", "Iris", -1.22, -0.53, 1.15, 0xf2a33b),
        hotspot("optic", "Optic nerve", "Nervus opticus", 1.61, -0.18, 0.54, 0xd89bc4),
    ]

    static let intestine = [
        hotspot("duodenum", "Duodenum", "Duodenum", 0.60, 0.80, 0.75, 0xf2a33b),
        hotspot("jejunum", "Jejunum", "Jejunum", -0.45, 0.10, 0.82, 0xee7c6a),
        hotspot("colon", "Colon", "Colon", 0.75, -0.55, 0.72, 0x6393d8),
    ]

    static let pancreas = [
        hotspot("head", "Pancreatic head", "Caput pancreatis", -1.32, -0.36, 0.55, 0xee7c6a),
        hotspot("body", "Pancreatic body", "Corpus pancreatis", 0.05, 0.25, 0.45, 0xf2a33b),
        hotspot("tail", "Pancreatic tail", "Cauda pancreatis", 1.55, 0.30, 0.35, 0x6393d8),
        hotspot("duct", "Pancreatic duct", "Ductus pancreaticus", -0.61, 0.39, 0.50, 0xd89bc4),
    ]

    static let skin = [
        hotspot("epidermis", "Epidermis", "Epidermis", -0.05, 0.88, 1.40, 0xee7c6a),
        hotspot("dermis", "Dermis", "Dermis", 0.29, 0.05, 1.40, 0xf2a33b),
        hotspot("hypodermis", "Hypodermis", "Tela subcutanea", -0.39, -1.15, 1.40, 0x6393d8),
        hotspot("follicle", "Hair follicle", "Folliculus pili", 0.89, -0.44, 1.40, 0xd89bc4),
    ]

    private static func hotspot(
        _ id: String,
        _ name: String,
        _ scientificName: String,
        _ x: Float,
        _ y: Float,
        _ z: Float,
        _ color: UInt32
    ) -> Organ.Hotspot {
        Organ.Hotspot(
            id: id,
            name: name,
            scientificName: scientificName,
            position: SIMD3<Float>(x, y, z),
            color: Organ.Accent(hex: color)
        )
    }
}

private extension Organ.Accent {
    init(hex: UInt32) {
        red = Double((hex >> 16) & 0xff) / 255
        green = Double((hex >> 8) & 0xff) / 255
        blue = Double(hex & 0xff) / 255
    }
}
