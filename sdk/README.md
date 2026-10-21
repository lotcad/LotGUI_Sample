# SDK layout

`sdk/include` contains the currently published C++ headers. It is not a complete
binary SDK on its own. Full SDKs are staged separately, for example:

- `sdk/windows-x64-msvc/` (matching MSVC toolset + CRT)
- `sdk/packages/windows-x64-llvm-mingw-20260616.zip` (included portable x64 Release SDK)
- `sdk/packages/macos-arm64-clang-20261020.zip` (included Apple Silicon Release SDK)
- `sdk/macos-arm64-clang/` (Apple Silicon; MoltenVK required)
- `sdk/macos-x64-clang/` (Intel; build separately)
- `sdk/linux-x64-gcc/` (matching compiler/libstdc++/glibc)

The portable archive contains matching public `include` headers alongside a
`windows-x64-llvm-mingw` prefix with `lib/Release`, `lib/cmake/LotUI`, build
metadata, and license notices. The bootstrap extracts it under `.tools/sdk`
and sets `LOTGUI_SDK_ROOT` automatically. It does not consume the MSVC SDK.
Other SDK layouts should follow their package's include configuration.
Release and Debug can coexist; each must be built for the same target toolchain.
The first SDK format uses static archives, not a new DLL ABI.

Expanded SDK binaries are excluded from Git by default. The small portable SDK
ZIP in `sdk/packages` is intentionally versioned so GitHub source ZIP downloads
also contain everything required to obtain the matching SDK. Commit this ZIP
together with `tools/portable-lock.json` when updating it. Other platform SDKs can
be distributed through Releases.

The macOS archive contains the same shared-header layout with an ARM64 prefix,
all 12 static archives, CMake exports, original build metadata, and license
notices. Its adjacent `.zip.sha256` records the package checksum. The macOS
build script verifies and extracts it into a hash-specific `.tools/sdk-macos`
directory; it does not modify an existing `sdk/macos-arm64-clang` directory.
This is the locally validated Release SDK, with `sourceDirty: true` retained
in its producer metadata. Its objects require macOS 27.0 or later; older OS
versions need a separate SDK build. It does not bundle Vulkan/MoltenVK, fonts, Xcode,
CMake, or Ninja. See [macOS build](../docs/macos-build.md) and
[verification limits](../docs/verification.md).
