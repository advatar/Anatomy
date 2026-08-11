"""Blender-side exporter for Anatomy Atelier's optimized glTF intermediates."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import struct
import subprocess
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector


ASSET_IDS = ("brain", "eyeball", "heart", "intestine", "kidneys", "liver", "lungs", "pancreas", "skin")


def parse_arguments() -> argparse.Namespace:
    arguments = sys.argv[sys.argv.index("--") + 1 :]
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", required=True, type=Path)
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    return parser.parse_args(arguments)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def glb_document(path: Path) -> dict:
    with path.open("rb") as stream:
        if stream.read(4) != b"glTF":
            raise ValueError(f"Not a GLB file: {path}")
        stream.read(8)
        json_length = struct.unpack("<I", stream.read(4))[0]
        if stream.read(4) != b"JSON":
            raise ValueError(f"GLB has no leading JSON chunk: {path}")
        return json.loads(stream.read(json_length).decode("utf-8"))


def node_matrix(node: dict) -> Matrix:
    if "matrix" in node:
        values = node["matrix"]
        return Matrix(tuple(tuple(values[column * 4 + row] for column in range(4)) for row in range(4)))

    translation = Matrix.Translation(Vector(node.get("translation", (0, 0, 0))))
    rotation_values = node.get("rotation", (0, 0, 0, 1))
    rotation = Quaternion((rotation_values[3], rotation_values[0], rotation_values[1], rotation_values[2])).to_matrix().to_4x4()
    scale_values = node.get("scale", (1, 1, 1))
    scale = Matrix.Diagonal(Vector((*scale_values, 1)))
    return translation @ rotation @ scale


def document_metrics(path: Path) -> dict:
    document = glb_document(path)
    accessors = document.get("accessors", [])
    meshes = document.get("meshes", [])
    nodes = document.get("nodes", [])
    points: list[Vector] = []

    def visit(node_index: int, parent: Matrix) -> None:
        node = nodes[node_index]
        world = parent @ node_matrix(node)
        mesh_index = node.get("mesh")
        if mesh_index is not None:
            for primitive in meshes[mesh_index].get("primitives", []):
                accessor = accessors[primitive["attributes"]["POSITION"]]
                minimum = accessor.get("min")
                maximum = accessor.get("max")
                if minimum is not None and maximum is not None:
                    if accessor.get("normalized"):
                        component_type = accessor["componentType"]
                        divisors = {5120: 127, 5121: 255, 5122: 32767, 5123: 65535}
                        divisor = divisors.get(component_type)
                        if divisor is None:
                            raise ValueError(f"Unsupported normalized component type {component_type}")

                        def normalized(values: list[float]) -> list[float]:
                            converted = [value / divisor for value in values]
                            return [max(value, -1) for value in converted] if component_type in (5120, 5122) else converted

                        minimum = normalized(minimum)
                        maximum = normalized(maximum)
                    for x in (minimum[0], maximum[0]):
                        for y in (minimum[1], maximum[1]):
                            for z in (minimum[2], maximum[2]):
                                points.append(world @ Vector((x, y, z)))
        for child_index in node.get("children", []):
            visit(child_index, world)

    scene_index = document.get("scene", 0)
    scene = document.get("scenes", [{}])[scene_index]
    for node_index in scene.get("nodes", []):
        visit(node_index, Matrix.Identity(4))

    if not points:
        raise ValueError(f"No mesh bounds in {path}")

    triangle_count = 0
    vertex_count = 0
    primitive_count = 0
    normal_primitive_count = 0
    tangent_primitive_count = 0
    for mesh in meshes:
        for primitive in mesh.get("primitives", []):
            primitive_count += 1
            attributes = primitive.get("attributes", {})
            normal_primitive_count += int("NORMAL" in attributes)
            tangent_primitive_count += int("TANGENT" in attributes)
            vertex_count += accessors[primitive["attributes"]["POSITION"]]["count"]
            index_accessor = primitive.get("indices")
            triangle_count += accessors[index_accessor]["count"] // 3 if index_accessor is not None else 0

    return {
        "bounds": {
            "min": [round(min(point[index] for point in points), 6) for index in range(3)],
            "max": [round(max(point[index] for point in points), 6) for index in range(3)],
        },
        "triangles": triangle_count,
        "vertices": vertex_count,
        "meshes": len(meshes),
        "primitives": primitive_count,
        "materials": len(document.get("materials", [])),
        "textures": len(document.get("images", [])),
        "animations": len(document.get("animations", [])),
        "normalPrimitives": normal_primitive_count,
        "tangentPrimitives": tangent_primitive_count,
    }


def blender_bounds() -> dict:
    points = [
        object_.matrix_world @ Vector(corner)
        for object_ in bpy.context.scene.objects
        if object_.type == "MESH"
        for corner in object_.bound_box
    ]
    if not points:
        raise ValueError("Imported scene contains no mesh objects")
    return {
        "min": [round(min(point[index] for point in points), 6) for index in range(3)],
        "max": [round(max(point[index] for point in points), 6) for index in range(3)],
    }


def maximum_bound_delta(first: dict, second: dict) -> float:
    values = []
    for edge in ("min", "max"):
        values.extend(abs(first[edge][index] - second[edge][index]) for index in range(3))
    return max(values)


def texture_report() -> list[dict]:
    ignored = {"Render Result", "Viewer Node"}
    return sorted(
        (
            {
                "name": image.name,
                "width": image.size[0],
                "height": image.size[1],
                "colorSpace": image.colorspace_settings.name,
            }
            for image in bpy.data.images
            if image.name not in ignored and image.size[0] > 0
        ),
        key=lambda item: item["name"],
    )


def export_asset(asset_id: str, source_path: Path, input_path: Path, output_path: Path) -> dict:
    source_metrics = document_metrics(source_path)
    optimized_metrics = document_metrics(input_path)

    if optimized_metrics["normalPrimitives"] != optimized_metrics["primitives"]:
        raise RuntimeError(f"Optimized {asset_id} has a primitive without normals")
    if optimized_metrics["animations"] != source_metrics["animations"]:
        raise RuntimeError(f"Optimization changed the animation count for {asset_id}")
    if optimized_metrics["primitives"] > source_metrics["primitives"]:
        raise RuntimeError(f"Optimization increased draw-call candidates for {asset_id}")

    bpy.ops.wm.read_factory_settings(use_empty=True)
    result = bpy.ops.import_scene.gltf(filepath=str(input_path))
    if "FINISHED" not in result:
        raise RuntimeError(f"Blender failed to import {input_path}")

    before_export_bounds = blender_bounds()
    input_textures = texture_report()
    for texture in input_textures:
        expected_color_space = "sRGB" if "basecolor" in texture["name"].lower() else "Non-Color"
        if texture["colorSpace"] != expected_color_space:
            raise RuntimeError(
                f"Unexpected color space for {asset_id}/{texture['name']}: "
                f"{texture['colorSpace']} (expected {expected_color_space})"
            )
    output_path.unlink(missing_ok=True)
    result = bpy.ops.wm.usd_export(
        filepath=str(output_path),
        export_animation=False,
        export_hair=False,
        export_uvmaps=True,
        export_normals=True,
        export_materials=True,
        generate_preview_surface=True,
        generate_materialx_network=False,
        export_textures_mode="NEW",
        overwrite_textures=True,
        relative_paths=True,
        triangulate_meshes=True,
        usdz_downscale_size="1024",
        merge_parent_xform=True,
        convert_scene_units="METERS",
        meters_per_unit=1.0,
        root_prim_path=f"/{asset_id}",
    )
    if "FINISHED" not in result or not output_path.exists():
        raise RuntimeError(f"Blender failed to export {output_path}")

    validation = subprocess.run(
        ("/usr/bin/usdchecker", "--arkit", str(output_path)),
        capture_output=True,
        text=True,
        check=False,
    )
    if validation.returncode != 0:
        raise RuntimeError(f"USDZ validation failed for {asset_id}:\n{validation.stdout}\n{validation.stderr}")

    bpy.ops.wm.read_factory_settings(use_empty=True)
    result = bpy.ops.wm.usd_import(filepath=str(output_path))
    if "FINISHED" not in result:
        raise RuntimeError(f"Blender failed to re-import {output_path}")
    round_trip_bounds = blender_bounds()
    output_textures = texture_report()
    if any(max(texture["width"], texture["height"]) > 1024 for texture in output_textures):
        raise RuntimeError(f"USDZ texture limit was not applied for {asset_id}")
    round_trip_delta = maximum_bound_delta(before_export_bounds, round_trip_bounds)
    if round_trip_delta > 0.0001:
        raise RuntimeError(f"Coordinate drift for {asset_id}: {round_trip_delta}")

    source_bounds_delta = maximum_bound_delta(source_metrics["bounds"], optimized_metrics["bounds"])
    if source_bounds_delta > 0.005:
        raise RuntimeError(f"Simplification changed {asset_id} bounds by {source_bounds_delta}")

    return {
        "id": asset_id,
        "sourcePath": f"public/models/{asset_id}.glb",
        "outputPath": f"AnatomyRealityContent.rkassets/{asset_id}.usdz",
        "sourceSHA256": sha256(source_path),
        "outputSHA256": sha256(output_path),
        "sourceBytes": source_path.stat().st_size,
        "outputBytes": output_path.stat().st_size,
        "source": {**source_metrics, "bytes": source_path.stat().st_size},
        "optimized": {**optimized_metrics, "bytes": output_path.stat().st_size},
        "triangleRatio": round(optimized_metrics["triangles"] / source_metrics["triangles"], 4),
        "maximumSourceBoundsDelta": round(source_bounds_delta, 6),
        "maximumUSDZRoundTripBoundsDelta": round(round_trip_delta, 6),
        "inputTextures": input_textures,
        "textures": output_textures,
        "arkitValidated": True,
    }


def main() -> None:
    arguments = parse_arguments()
    arguments.output_dir.mkdir(parents=True, exist_ok=True)
    expected_outputs = {f"{asset_id}.usdz" for asset_id in ASSET_IDS}
    for existing in arguments.output_dir.glob("*.usdz"):
        if existing.name not in expected_outputs:
            existing.unlink()

    assets = []
    for asset_id in ASSET_IDS:
        print(f"Exporting {asset_id}", flush=True)
        assets.append(
            export_asset(
                asset_id,
                arguments.source_dir / f"{asset_id}.glb",
                arguments.input_dir / f"{asset_id}.glb",
                arguments.output_dir / f"{asset_id}.usdz",
            )
        )

    manifest = {
        "pipeline": {
            "blender": bpy.app.version_string,
            "gltfTransform": "4.2.1",
            "simplificationRatio": 0.5,
            "maximumSimplificationError": 0.001,
            "baseColorJPEGQuality": 88,
            "maximumTextureDimension": 1024,
            "metersPerUnit": 1,
        },
        "assets": assets,
    }
    arguments.manifest.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        traceback.print_exc()
        sys.stdout.flush()
        sys.stderr.flush()
        os._exit(1)
