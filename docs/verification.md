# Verification status

## macOS ARM64 consumer and local SDK (2026-10-21)

Sample revision tested: `1e08202`.

- Tested on Apple M1, macOS 27.0.1, Apple Clang 21.0.0, CMake 4.0.3,
  Ninja, and the locally installed Vulkan 1.4.350 SDK/MoltenVK.
- Used the existing local `sdk/macos-arm64-clang` Release SDK. Its metadata
  records source commit `8f51524a0e164ef602580018bc387c5f8c9f0087`,
  `sourceDirty: true`, exported on 2026-10-20. The framework SDK itself was
  not rebuilt during this consumer validation. All nine LotUI archives and
  three bundled dependency archives have ARM64 slices. Their Mach-O build
  commands record SDK 27.0 and minimum macOS 27.0; this package does not
  establish compatibility with earlier macOS releases.
- Copied the SDK and shared public headers into a different prefix containing
  a space (`build-macos-verify/relocated sdk`). Configured and built all four
  native examples, the plugin, and `custom_draw_contract` in a fresh Ninja
  Release build against that prefix. No framework implementation sources
  were compiled. Both sample CTest cases passed.
- A separate temporary SDK consumer linked `LotUI::Declarative` and
  `LotUI::VulkanEmbedded`. Its additional CTest passed valid/invalid LotML
  parsing, widget lookup/layout/paint, embedded CPU texture create/update/release,
  and empty paint-batch checks. This does not validate embedded GPU drawing.
- Seven GUI checks exited successfully: `platform_probe --smoke`,
  `custom_draw_demo --smoke`, `ribbon_demo --smoke`, ribbon V1/V2 input tests,
  installed `ribbon_demo --capture-plugin`, and installed
  `list_control_demo --video-demo`. Every check ran with `/private/tmp` as
  its working directory; installed paths also contained spaces.
- The platform probe reported 960x640 logical pixels, a 1920x1280 framebuffer,
  and DPI scale 2.0. The ribbon V2 callback received `한글`. The installed
  ribbon capture was visually checked for Korean labels, plugin controls,
  and the table. The scripted list demo completed in approximately 22 seconds.
- Checked the newly included Windows SDK ZIP without running Windows binaries:
  SHA256 matched `tools/portable-lock.json`, archive CRC validation passed,
  and all 42 packaged public headers matched `sdk/include` after normalizing
  line endings.

Runtime configuration and remaining limits:

- GUI checks require access to the desktop and Metal GPU. They used
  `VK_DRIVER_FILES` pointing at the local `MoltenVK_icd.json`.
- `cmake --install` stages examples, plugin, fonts, and legal notices, but the
  installed executables have no `LC_RPATH` for Vulkan. Launching the installed
  ribbon without a loader search path failed with
  `Library not loaded: @rpath/libvulkan.1.dylib`. The installed GUI checks
  passed with `DYLD_LIBRARY_PATH` pointing to the local Vulkan SDK's `lib`.
  This is not a standalone runtime package or clean-machine deployment check.
- The original expanded local macOS SDK remains untracked. The tested archives
  and shared headers are now packaged as
  `sdk/packages/macos-arm64-clang-20261020.zip`, with a SHA256 sidecar and
  `share/LotUI` license notices added from this repository. Original producer
  metadata, including `sourceDirty: true`, is preserved; a reproducible clean
  producer revision remains future work.
- Physical Korean IME composition, clipboard integration, interactive resize,
  DPI transitions between displays, and focus changes still need manual checks.
  Programmatic Korean text submission and the initial Retina scale do not
  establish those results. Aggregate-initializer compiler warnings remain;
  there were no compile or link errors.
- Windows/MSVC, Windows/LLVM-MinGW, and Linux were not executed in this Mac
  validation. The Windows results below are earlier validation records.

Local evidence is under the ignored `build-macos-verify` directory:
`Testing/Temporary/LastTest.log`, `runtime-logs/results.json`, individual runtime
logs, `plugin.png`, and `sdk-api-probe/build/Testing/Temporary/LastTest.log`.

The VS Code macOS task builds with the packaged SDK via `tools/build-macos.sh`.
It generates `out/macos/compile_commands.json` for the Mac IntelliSense
configuration. Build and test actions use installed local development tools;
the Windows portable downloader is not executed on macOS. The packaged-SDK
workflow built all examples and passed its two CTest cases and six GUI runs
(three smoke checks, ribbon V1/V2 input checks, and the scripted list demo).

## Windows portable SDK (2026-10-20)

- Built a Release static DesktopSDK using LLVM-MinGW 20260616 / Clang 22.1.8,
  FreeType 2.14.3, HarfBuzz 14.2.1, and TinyXML-2 11.0.0 on Windows x64.
- Included matching public headers and SDK binaries as a versioned ZIP under
  `sdk/packages`; consumer configuration does not compile framework sources.
- Built every sample with the downloaded compiler, CMake and Ninja, Vulkan headers
  and an import library generated from Khronos' loader definition. No Vulkan SDK
  shader compiler is needed by the consumer.
- Both CTest cases passed. `platform_probe`, `custom_draw_demo`, and `ribbon_demo`
  smoke checks passed on Intel Iris Xe Vulkan. Ribbon V1/V2 input checks passed,
  including the programmatic Korean text submission callback.
- `list_control_demo --video-demo` completed its scripted GUI interactions and
  exited successfully with only Windows built-ins on PATH.
- Repeated first-run downloads, build and tests in a separate checkout copy with
  spaces in its path, an empty tool cache, PATH restricted to Windows built-ins,
  and VULKAN_SDK cleared. Installed Visual Studio tools were not used.
- This is an isolated-path check on a development PC, not a clean Windows VM
  certification. Physical Korean IME, DPI/resize and clipboard still need manual
  runtime checks.

## Earlier Linux preparation

Source baseline inspected: LotGUI commit `908834e3b1b1100e44fc33b638ab67dfc7275061`.

Verified in the Linux preparation environment:

- Framework CMake configuration/build using GCC 13.3, X11 and Vulkan 1.3.275.
- 20 framework CTest cases passed, including embedded texture lifetime tests.
- This build intentionally disabled FreeType, Declarative and native examples;
  no text shaping, IME or windowed smoke-test result is implied.
- The DesktopSDK component installs only headers, static archives, relocatable
  CMake package files, metadata and license notices.
- Copied the installed SDK into another directory, configured the independent
  sample checkout against that relocated prefix, built and passed the
  `custom_draw_contract` CTest without adding framework source to the consumer.
- Ten POSIX/common example translation units passed C++17 syntax checks using
  only the distributed public headers. The Win32-only plugin loader was not
  compiled on Linux.
- Three export-boundary tests passed: allowed public files only, destination
  protection, required platform triplet; consumer-owned docs remain intact.

Still required before platform releases:

- Full FreeType/HarfBuzz and optional TinyXML-2 SDK build/consumer checks.
- Windows/MSVC configure, compile, link, install and relocated SDK consumer
  checks on that actual platform. The macOS consumer checks above cover the
  existing local SDK; macOS SDK production and clean deployment remain open.
- Native runtime checks for each OS: resize/DPI, focus, Korean IME, clipboard,
  table interactions, plugin load/unload and resources from another working dir.
- Validate external runtime dependencies and notices in a clean installation.

No prebuilt Windows/macOS SDK was created or uploaded by that earlier Linux work. The Linux
validation package is a local test artifact, not a published full desktop release.
