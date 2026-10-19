# SDK layout

`sdk/include` contains the currently published C++ headers. It is not a complete
binary SDK on its own. Full SDKs are staged separately, for example:

- `sdk/windows-x64-msvc/` (matching MSVC toolset + CRT)
- `sdk/macos-arm64-clang/` (Apple Silicon; MoltenVK required)
- `sdk/macos-x64-clang/` (Intel; build separately)
- `sdk/linux-x64-gcc/` (matching compiler/libstdc++/glibc)

Each complete prefix contains `include`, `lib/<configuration>`,
`lib/cmake/LotUI`, and `share/LotUI`. Point `LOTGUI_SDK_ROOT` to that prefix.
Release and Debug can coexist; each must be built for the same target toolchain.
The first SDK format uses static archives, not a new DLL ABI.

Generated SDK binaries are excluded from Git by default. Distribute matching
SDK archives through Releases. No prebuilt Windows/macOS binary is included
until it has been built and tested on that platform.
