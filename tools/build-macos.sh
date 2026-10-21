#!/bin/bash
# Apple Silicon consumer build. Uses the packaged SDK, not framework sources.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
if [[ -f "$root/.tools/macos.env" ]]; then
    source "$root/.tools/macos.env"
fi

mode="${1:-build}"
example="${2:-ribbon_demo}"
case "$mode" in
    build|--test) [[ $# -le 1 ]] ;;
    --run)
        [[ $# -eq 2 ]]
        case "$example" in
            ribbon_demo|list_control_demo|platform_probe|custom_draw_demo) ;;
            *) echo "Unknown example: $example" >&2; exit 2 ;;
        esac ;;
    *) echo "Usage: bash tools/build-macos.sh [--test|--run example]" >&2; exit 2 ;;
esac
if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
    echo "This SDK requires native macOS ARM64 (Apple Silicon)." >&2
    exit 1
fi
macos_version="$(sw_vers -productVersion)"
if [[ "${macos_version%%.*}" -lt 27 ]]; then
    echo "The included SDK was built with a macOS 27.0 deployment target; macOS 27+ is required." >&2
    exit 1
fi
for tool in cmake ninja xcrun unzip shasum; do
    command -v "$tool" >/dev/null || { echo "Required tool missing: $tool" >&2; exit 1; }
done
compiler="$(xcrun --find clang++)"
font="${LOTGUI_FONT_FILE:-$root/resources/fonts/NotoSansKR-Regular.ttf}"
if [[ -z "${LOTGUI_FONT_FILE:-}" && ! -f "$font" &&
      -f "$root/../imgui/misc/fonts/NotoSansKR-Regular.ttf" ]]; then
    font="$root/../imgui/misc/fonts/NotoSansKR-Regular.ttf"
fi
if [[ ! -f "$font" ]]; then
    echo "Set LOTGUI_FONT_FILE to an official Noto Sans KR .ttf. See docs/macos-build.md." >&2
    exit 1
fi

archive="sdk/packages/macos-arm64-clang-20261020.zip"
(cd "$root" && shasum -a 256 -c "$archive.sha256")
sdk_hash="$(shasum -a 256 "$root/$archive")"
sdk_hash="${sdk_hash%% *}"
sdk_directory="$root/.tools/sdk-macos/$sdk_hash"
sdk_root="$sdk_directory/macos-arm64-clang"
if [[ ! -f "$sdk_directory/.ready" || ! -f "$sdk_root/lib/cmake/LotUI/LotUIConfig.cmake" ]]; then
    mkdir -p "$sdk_directory"
    unzip -oq "$root/$archive" -d "$sdk_directory"
    touch "$sdk_directory/.ready"
fi

vulkan_root="${VULKAN_SDK:-}"
if [[ -z "$vulkan_root" && -f "$root/../VulkanSdk/Apple/macOS/include/vulkan/vulkan.h" ]]; then
    vulkan_root="$root/../VulkanSdk/Apple/macOS"
fi
vulkan_args=(-DLOTGUI_BUILD_NATIVE_EXAMPLES=ON)
if [[ -n "$vulkan_root" ]]; then
    if [[ ! -f "$vulkan_root/include/vulkan/vulkan.h" || ! -f "$vulkan_root/lib/libvulkan.dylib" ]]; then
        echo "VULKAN_SDK must contain include/vulkan/vulkan.h and lib/libvulkan.dylib." >&2
        exit 1
    fi
    vulkan_args+=("-DVulkan_INCLUDE_DIR=$vulkan_root/include" "-DVulkan_LIBRARY=$vulkan_root/lib/libvulkan.dylib")
    export DYLD_LIBRARY_PATH="$vulkan_root/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
    if [[ -z "${VK_DRIVER_FILES:-}" && -f "$vulkan_root/share/vulkan/icd.d/MoltenVK_icd.json" ]]; then
        export VK_DRIVER_FILES="$vulkan_root/share/vulkan/icd.d/MoltenVK_icd.json"
    fi
fi
build_directory="$root/out/macos"
cmake -S "$root" -B "$build_directory" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON "-DCMAKE_CXX_COMPILER=$compiler" \
    "-DLOTGUI_SDK_ROOT=$sdk_root" "-DLOTGUI_FONT_FILE=$font" "${vulkan_args[@]}"
cmake --build "$build_directory" --parallel
if [[ "$mode" == --test ]]; then
    ctest --test-dir "$build_directory" --output-on-failure
    "$build_directory/platform_probe" --smoke
    "$build_directory/custom_draw_demo" --smoke
    "$build_directory/ribbon_demo" --smoke
    "$build_directory/ribbon_demo" --input-test-v1
    "$build_directory/ribbon_demo" --input-test
    "$build_directory/list_control_demo" --video-demo
elif [[ "$mode" == --run ]]; then
    exec "$build_directory/$example"
fi
