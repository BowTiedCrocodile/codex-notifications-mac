#!/bin/zsh
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: generate-app-icons.sh <source-1024.png> <output-dir>" >&2
  exit 1
fi

src="$1"
out_dir="$2"

if [[ ! -f "$src" ]]; then
  echo "Source file not found: $src" >&2
  exit 1
fi

mkdir -p "$out_dir"

sizes=(16 32 128 256 512 1024)
for size in "${sizes[@]}"; do
  sips -z "$size" "$size" "$src" --out "$out_dir/icon_${size}x${size}.png" >/dev/null
  if [[ "$size" -lt 1024 ]]; then
    local_2x=$((size * 2))
    sips -z "$local_2x" "$local_2x" "$src" --out "$out_dir/icon_${size}x${size}@2x.png" >/dev/null
  fi
done

echo "Generated icons in $out_dir"
