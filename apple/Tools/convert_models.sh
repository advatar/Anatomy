#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
apple_dir=${script_dir:h}
repo_dir=${apple_dir:h}
source_dir=${repo_dir}/public/models
package_dir=${apple_dir}/Packages/AnatomyRealityContent
output_dir=${package_dir}/Sources/AnatomyRealityContent/AnatomyRealityContent.rkassets
manifest_path=${package_dir}/asset-manifest.json
blender_bin=${BLENDER_BIN:-/Applications/Blender.app/Contents/MacOS/Blender}
gltf_transform_version=4.2.1
asset_ids=(brain eyeball heart intestine kidneys liver lungs pancreas skin)

if [[ ! -x ${blender_bin} ]]; then
  print -u2 "Blender is required at ${blender_bin}. Override with BLENDER_BIN."
  exit 1
fi

for asset_id in ${asset_ids}; do
  if [[ ! -f ${source_dir}/${asset_id}.glb ]]; then
    print -u2 "Missing source model: ${source_dir}/${asset_id}.glb"
    exit 1
  fi
done

work_dir=$(mktemp -d /tmp/anatomy-asset-pipeline.XXXXXX)
if [[ ${work_dir} != /tmp/anatomy-asset-pipeline.* ]]; then
  print -u2 "Unexpected temporary directory: ${work_dir}"
  exit 1
fi
trap 'rm -rf -- "${work_dir}"' EXIT

mkdir -p ${output_dir}

for asset_id in ${asset_ids}; do
  source_path=${source_dir}/${asset_id}.glb
  simplified_path=${work_dir}/${asset_id}-simplified.glb
  color_path=${work_dir}/${asset_id}-color.glb
  apple_path=${work_dir}/${asset_id}.glb

  print "Optimizing ${asset_id}"
  npx --yes @gltf-transform/cli@${gltf_transform_version} simplify \
    ${source_path} ${simplified_path} --ratio 0.5 --error 0.001
  npx --yes @gltf-transform/cli@${gltf_transform_version} jpeg \
    ${simplified_path} ${color_path} \
    --formats webp --slots baseColorTexture --quality 88
  npx --yes @gltf-transform/cli@${gltf_transform_version} png \
    ${color_path} ${apple_path} --formats webp
  npx --yes @gltf-transform/cli@${gltf_transform_version} validate ${apple_path} \
    > ${work_dir}/${asset_id}-validation.txt
done

${blender_bin} --background --factory-startup \
  --python ${script_dir}/export_usdz.py -- \
  --source-dir ${source_dir} \
  --input-dir ${work_dir} \
  --output-dir ${output_dir} \
  --manifest ${manifest_path}

if [[ ! -f ${manifest_path} ]]; then
  print -u2 "Exporter did not produce ${manifest_path}"
  exit 1
fi
for asset_id in ${asset_ids}; do
  if [[ ! -f ${output_dir}/${asset_id}.usdz ]]; then
    print -u2 "Exporter did not produce ${asset_id}.usdz"
    exit 1
  fi
done

compiled_smoke_test=${work_dir}/AnatomyRealityContent.reality
xcrun realitytool compile \
  --output-reality ${compiled_smoke_test} \
  --platform xrsimulator \
  --deployment-target 2.0 \
  --use-metal auto \
  --reduced-texture-file-size disabled \
  ${output_dir}

print "Converted and validated ${#asset_ids} organs."
print "Assets: ${output_dir}"
print "Manifest: ${manifest_path}"
