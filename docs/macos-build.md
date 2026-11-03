# macOS ARM64 / VS Code

The included Release SDK targets macOS 27.0 or later on Apple Silicon with
Apple Clang. Its archive objects record a minimum OS version of 27.0; older
macOS versions require a separately rebuilt SDK and matching dependencies.
It contains
public headers and static LotUI, FreeType, HarfBuzz and TinyXML-2 archives.
Applications compile their own example sources against this SDK. Framework
implementation sources are not included or required.

## First setup

Prepare Apple Clang from Xcode or Command Line Tools, CMake 3.20 or newer,
Ninja, a macOS Vulkan SDK with Vulkan Loader/MoltenVK, and an official
Noto Sans KR `.ttf` with its matching OFL notice. The script uses installed
tools and does not download or install these prerequisites.

Create `.tools/macos.env` for machine-specific paths. This ignored file is
read by the build task, including when VS Code is opened from Finder:

```sh
mkdir -p .tools
# Put these exports in .tools/macos.env, using your actual absolute paths:
export VULKAN_SDK="/absolute/path/to/VulkanSDK/macOS"
export LOTGUI_FONT_FILE="/absolute/path/to/NotoSansKR-Regular.ttf"
```

`VULKAN_SDK` must contain `include/vulkan/vulkan.h`, `lib/libvulkan.dylib`,
and a usable MoltenVK installation. Environment variables inherited by the
process can also supply these settings. The script adds `/opt/homebrew/bin`
and `/usr/local/bin` to its process PATH to locate CMake and Ninja.

When no font is configured, `resources/fonts/NotoSansKR-Regular.ttf` is used,
with an existing sibling `../imgui/misc/fonts/NotoSansKR-Regular.ttf` as a
development-checkout fallback. The sibling `../VulkanSdk/Apple/macOS` SDK is
also detected if `VULKAN_SDK` is unset. Fonts are never downloaded or substituted.

## Build and develop

Open this repository folder in VS Code. The existing tasks choose their
macOS commands automatically:

- **Cmd+Shift+B**: `LotGUI: build (portable)`.
- **Terminal → Run Task → LotGUI: run example (portable)**: choose an example.
- **Terminal → Run Task → LotGUI: test (portable)**: run both CTest cases,
  three GUI smoke checks, ribbon plugin V1/V2 input checks, and the scripted
  list demo. GUI tests need a desktop session and Metal GPU access.

The label is shared with the Windows tasks. macOS uses installed local tools;
it does not run PowerShell or download the Windows toolchain.

Equivalent terminal commands:

```sh
bash tools/build-macos.sh
bash tools/build-macos.sh --run ribbon_demo
bash tools/build-macos.sh --test
```

The script verifies `sdk/packages/macos-arm64-clang-20261020.zip` against its
SHA256 sidecar and extracts into `.tools/sdk-macos/<checksum>`. Matching headers
are next to the extracted SDK prefix. Results are built in `out/macos`.
The optional C/C++ extension's **Mac** configuration reads
`out/macos/compile_commands.json`; build once before using code completion.
Edit the application sources under `examples` and run the build task again.

## Rebuild the macOS SDK for GraphCanvas

The checked-in macOS SDK predates `GraphCanvas`, so its standard sample build
skips `graph_canvas_demo`. On an Apple Silicon Mac with a sibling `../LotGUI`
checkout and the prerequisites above, rebuild the producer and package its
public headers and Release libraries:

```sh
cmake -S ../LotGUI -B ../LotGUI/build-macos-sdk -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DLOTUI_BUILD_EXAMPLES=OFF -DLOTUI_BUILD_DESKTOP_SDK=ON \
  -DLOTUI_STAGE_SAMPLE_SDK=OFF -DLOTUI_VULKAN_SDK_ROOT="$VULKAN_SDK"
bash tools/package-macos-sdk.sh ../LotGUI/build-macos-sdk ../LotGUI
bash tools/build-macos.sh --test
```

The packaging helper checks that the installed widget archive exports
`GraphCanvas`, updates the ZIP and SHA256 sidecar, and copies the public header
allowlist from the matching producer. `build-macos.sh` then detects the symbol,
enables the new example, and runs its smoke test. It prefers the new
`macos-arm64-clang-20261104.zip` when present, retaining the older archive for
comparison. Packaging requires native
macOS ARM64; the current Windows checkout cannot produce that archive.

## Runtime and installation

The task sets `DYLD_LIBRARY_PATH` to the configured Vulkan SDK's `lib` directory
and, when present, `VK_DRIVER_FILES` to its `MoltenVK_icd.json`.
For separately installed executables, supply these paths explicitly:

```sh
cmake --install out/macos --prefix out/macos-package
export DYLD_LIBRARY_PATH="$VULKAN_SDK/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
export VK_DRIVER_FILES="$VULKAN_SDK/share/vulkan/icd.d/MoltenVK_icd.json"
./out/macos-package/bin/ribbon_demo
```

Keep the plugin, `resources/fonts`, and `legal` directories beside the executable.
Installation does not bundle the Vulkan Loader or MoltenVK and is not a
standalone `.app` package. The SDK is ARM64 Release only; do not mix it with
Intel, MSVC, or LLVM-MinGW binaries. Original producer metadata records a dirty
source tree. See [verification status](verification.md) for tested behavior
and remaining manual input/deployment checks.
