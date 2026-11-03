#!/bin/bash
# Maintainer command, run on Apple Silicon after building the LotGUI producer.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
producer_build="${1:?Usage: bash tools/package-macos-sdk.sh producer-build producer-source}"
producer_source="${2:?Usage: bash tools/package-macos-sdk.sh producer-build producer-source}"
producer_build="$(cd "$producer_build" && pwd)"
producer_source="$(cd "$producer_source" && pwd)"
if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
    echo "Package the macOS ARM64 SDK on an Apple Silicon Mac." >&2
    exit 1
fi
for command in cmake zip shasum xcrun; do
    command -v "$command" >/dev/null || { echo "Missing $command" >&2; exit 1; }
done
cache="$producer_build/CMakeCache.txt"
if [[ ! -f "$cache" ]] ||
    ! grep -q '^CMAKE_BUILD_TYPE:STRING=Release$' "$cache" ||
    ! grep -q '^LOTUI_BUILD_DESKTOP_SDK:BOOL=ON$' "$cache" ||
    ! grep -q '^LOTUI_STAGE_SAMPLE_SDK:BOOL=OFF$' "$cache"; then
    echo "Use a Release producer build with DesktopSDK ON and sample staging OFF." >&2
    exit 1
fi
if [[ ! -f "$producer_source/widgets/graph_canvas.cpp" ]]; then
    echo "Producer source has no GraphCanvas." >&2
    exit 1
fi

mkdir -p "$root/.tools" "$root/sdk/packages"
stage="$(mktemp -d "$root/.tools/package-macos.XXXXXX")"
prefix="$stage/macos-arm64-clang"
cmake --build "$producer_build" --parallel
cmake --install "$producer_build" --config Release --component DesktopSDK --prefix "$prefix"
archive_lib="$prefix/lib/Release/liblotui_widgets.a"
if [[ ! -f "$archive_lib" ]] ||
    ! xcrun nm -g "$archive_lib" 2>/dev/null | grep 'GraphCanvas' >/dev/null; then
    echo "Installed LotUI widgets archive lacks GraphCanvas." >&2
    exit 1
fi

public_root="$root/sdk/include"
while IFS= read -r -d '' header; do
    relative="${header#"$public_root"/}"
    source="$producer_source/$relative"
    if [[ ! -f "$source" ]]; then
        echo "Missing producer header: $relative" >&2
        exit 1
    fi
    mkdir -p "$stage/include/$(dirname "$relative")"
    cp "$source" "$stage/include/$relative"
done < <(find "$public_root" -type f -name '*.h' -print0)

mkdir -p "$prefix/share/LotUI/licenses"
cp "$root/LICENSE" "$root/THIRD_PARTY_NOTICES.md" "$prefix/share/LotUI/"
cp "$root/licenses/"* "$prefix/share/LotUI/licenses/"
archive="$root/sdk/packages/macos-arm64-clang-20261104.zip"
temporary_archive="$stage/macos-sdk.zip"
(cd "$stage" && zip -q -r "$temporary_archive" include macos-arm64-clang)
mv "$temporary_archive" "$archive"
(cd "$root" && shasum -a 256 sdk/packages/macos-arm64-clang-20261104.zip > sdk/packages/macos-arm64-clang-20261104.zip.sha256)
echo "macOS SDK staged: $archive"
echo "Temporary package directory: $stage"
