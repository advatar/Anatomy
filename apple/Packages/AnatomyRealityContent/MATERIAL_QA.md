# WebGL to RealityKit material QA

Validation date: 2026-08-11

The source comparison is `app/lib/three/loaders.ts`; the native comparison is
the compiled macOS RealityKit scene built from this package. The native heart
was visually inspected in the running app after all nine assets passed the
RealityKit loading integration test.

| Concern | WebGL behavior | RealityKit result |
| --- | --- | --- |
| Base color | Texture sampled as sRGB | Base-color textures are tagged sRGB in `asset-manifest.json` and retain their color and tonal variation. |
| Normal and roughness maps | Linear sampling, mipmaps, anisotropy | Textures are tagged Non-Color, downsampled to 1024 for stable sampling, and compiled by Reality Composer Pro for each GPU family. Surface and vascular detail remain visible without obvious aliasing in the macOS runtime check. |
| Metalness | Forced to zero | The converted USD Preview Surface preserves the source non-metal anatomical response. No metallic appearance was observed. |
| Transmission and volume | Explicitly forced to zero | USD Preview Surface does not carry the unused WebGL volume/transmission path, avoiding an unnecessary transparent render path. |
| Clearcoat | Faint, broad WebGL clearcoat | USD Preview Surface uses its primary specular response. The native runtime has readable highlights without a visibly separate plastic clearcoat lobe. |
| Framing and orientation | Longest edge fitted to 3.8 units, then rotated x = 0.05 and y = -0.28 | `OrganRealityScene` applies the same fit and orientation, so the original hotspot coordinate space is unchanged. |

The renderers have different environment lighting and therefore cannot be
pixel-identical. The acceptance criterion is preservation of anatomical color,
surface detail, non-metal response, authored framing, and hotspot alignment;
those properties are present in the native runtime result.
