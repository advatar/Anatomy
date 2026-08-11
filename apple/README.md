# Anatomy Atelier for Apple platforms

This directory contains the native SwiftUI and RealityKit version of Anatomy
Atelier. One app target supports iOS/iPadOS, macOS, tvOS, and visionOS. The
Vision Pro presentation includes a dedicated immersive space; it is not a
windowed web view.

## Requirements

- Xcode 26 or newer
- XcodeGen 2.46 or newer when changing `project.yml`
- Blender 5.1 or newer and Node.js when regenerating the RealityKit assets

## Generate the project

```sh
cd apple
xcodegen generate
open AnatomyAtelier.xcodeproj
```

The generated Xcode project is checked in so the app can also be opened
without installing XcodeGen. Regenerate it after changing the project spec or
adding source files.

## Command-line verification

Build each destination serially. For example:

```sh
xcodebuild -project apple/AnatomyAtelier.xcodeproj \
  -scheme AnatomyAtelier \
  -destination 'generic/platform=macOS' \
  CODE_SIGNING_ALLOWED=NO build
```

Simulator tests must run serially:

```sh
xcodebuild -project apple/AnatomyAtelier.xcodeproj \
  -scheme AnatomyAtelier \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  CODE_SIGNING_ALLOWED=NO test
```

## Anatomy asset pipeline

The original GLB files in `public/models` remain the source of truth. Rebuild
all nine shipping USDZ files and their validation manifest with:

```sh
apple/Tools/convert_models.sh
```

The repeatable pipeline decodes the web-only mesh compression, reduces each
mesh to 50% of its original triangles within a 0.1% geometric error target,
limits runtime textures to 1024 pixels, exports USD Preview Surface materials,
checks every output with `usdchecker --arkit`, verifies USDZ round-trip bounds,
and smoke-compiles the complete Reality Composer Pro package. Detailed hashes,
topology, texture color spaces, and validation deltas are recorded in
`Packages/AnatomyRealityContent/asset-manifest.json`.

The app loads the compiled assets asynchronously through RealityKit and keeps
the current specimen plus the next two specimens warm. The Vision Pro viewer
uses the same content in a true immersive space at an approximately 38 cm
presentation size. Hotspots and their coordinates are carried over from the
original JavaScript anatomy catalog.
