# SDK distribution / SDK·예제 분리

The framework implementation stays in the development repository. This repository
contains application examples, public C++ headers and matching binary SDK packages.
Headers include declarations and inline/template code required by C++ consumers.

## Windows portable consumer build

The included `sdk/packages/windows-x64-llvm-mingw-20260616.zip` provides a
Release SDK built with the same portable compiler used by `tools/build-portable.ps1`.
VS Code's default build task downloads the toolchain and unpacks this SDK.
It also downloads Vulkan headers and a font, and creates a Vulkan import library;
the full Vulkan SDK and MSVC Build Tools are unnecessary for this route.
See [portable build](portable-build.md). The manual platform instructions below
remain useful for producing other SDK variants.

## Build each SDK on its target platform

Use the updated development LotGUI checkout. Build and export separately for each
OS, CPU architecture and compiler. The exporter does not cross-compile.

### Windows x64 / MSVC

```powershell
# D:\vulkan\LotGUI
cmake -S . -B build-sdk -A x64 -DBUILD_TESTING=ON -DLOTUI_EXAMPLE_FONT_FILE="../imgui/misc/fonts/NotoSansKR-Regular.ttf"
cmake --build build-sdk --config Release
ctest --test-dir build-sdk -C Release --output-on-failure
python tools/export_samples.py --destination ../LotGUI_Sample --build-dir build-sdk --triplet windows-x64-msvc --config Release
```

Use matching MSVC toolset, CPU architecture and CRT (`/MD` Release or `/MDd` Debug
with normal CMake defaults). Build/export Debug independently with `--config Debug`;
Debug and Release archives can coexist in one matching triplet. These are static
`.lib` archives, not a new DLL ABI.

### macOS / Apple Clang

```sh
cmake -S . -B build-sdk -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 -DBUILD_TESTING=ON -DLOTUI_EXAMPLE_FONT_FILE=../imgui/misc/fonts/NotoSansKR-Regular.ttf
cmake --build build-sdk --parallel
ctest --test-dir build-sdk --output-on-failure
python3 tools/export_samples.py --destination ../LotGUI_Sample --build-dir build-sdk --triplet macos-arm64-clang --config Release
```

Use the macOS Vulkan SDK/MoltenVK with the correct deployment target. Build Intel
separately with `CMAKE_OSX_ARCHITECTURES=x86_64` and `macos-x64-clang`. A universal
binary requires matching slices in every dependency; copying ARM64 archives does
not produce one. The backend uses Cocoa, QuartzCore and a native Metal-layer surface.

### Linux / GCC, X11

```sh
cmake -S . -B build-sdk -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -DLOTUI_EXAMPLE_FONT_FILE=../imgui/misc/fonts/NotoSansKR-Regular.ttf
cmake --build build-sdk --parallel
ctest --test-dir build-sdk --output-on-failure
python3 tools/export_samples.py --destination ../LotGUI_Sample --build-dir build-sdk --triplet linux-x64-gcc --config Release
```

Match libstdc++, glibc, compiler and architecture. The implemented native backend
is X11; no native Wayland support is claimed. GUI execution needs a display and
working Vulkan driver. Headless widget/custom-draw tests do not need a display.

## Producer installation

The new full standalone component is `DesktopSDK`. The existing `SDK` component
is the smaller embedded-engine SDK. **Do not install both into one prefix**:
each provides a different `LotUIConfig.cmake`.

```sh
cmake --install build-sdk --config Release --component DesktopSDK --prefix /path/to/sdk
```

The export helper stages this installation under `sdk/<triplet>`, checks that no
framework implementation/shaders/debug symbols are included and records the build
configuration/source commit. It copies an allowlist of application examples and
public headers, never the framework source tree. It does not invoke Git or change
repository visibility. Expanded SDK libraries are ignored by Git by default;
distribute validated per-platform archives through Releases or `sdk/packages`.

## Consumer build without private sources

From this repository, point to the correct full SDK, not `sdk/include`:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DLOTGUI_SDK_ROOT=sdk/linux-x64-gcc -DLOTGUI_FONT_FILE=/path/to/licensed/NotoSansKR-Regular.ttf
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

Windows uses the README's Visual Studio example; macOS uses its own triplet.
The consumer only calls `find_package(LotUI CONFIG REQUIRED)`, never
`add_subdirectory()` on the development repository or compiles framework `.cpp`.
CMake selects the Win32 or POSIX plugin loader and imports OS system dependencies.

Full SDKs require Vulkan and the compatible FreeType/HarfBuzz binary development
packages; optional Declarative also requires TinyXML-2. Use `CMAKE_PREFIX_PATH`
for those installations. Dependencies built from pinned sources by the producer
must be separately installed as binary development packages; the LotGUI export
does not automatically bundle them or download source in the consumer build.

For manual builds, the Noto Sans KR font is not downloaded or substituted automatically.
Set `LOTGUI_FONT_FILE` to a verified official copy and retain its matching OFL notice.
Keep `resources/fonts`, the demo plugin and legal notices beside the executable.
Vulkan/MoltenVK and any dynamic text dependency must be supplied by the target
system or packaged and tested separately; do not distribute an entire Vulkan SDK.

```sh
cmake --install build --config Release --prefix package
```

This stages sample executables/resources/plugin, not all external DLL/dylib/so
files automatically. Validate IME, DPI changes, resize, focus, plugin load/unload
and resource lookup after launching from a different working directory on each OS.

The current static C++ ABI requires compatible compiler/runtime versions. Source
separation alone does not create a stable cross-compiler DLL/C ABI. No licensing
change is implied for previously published MIT headers or examples.
