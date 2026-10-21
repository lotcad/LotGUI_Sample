# Verification status

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
- Windows/MSVC and macOS/Apple Clang configure, compile, link, install and relocated
  SDK consumer checks on those actual platforms.
- Native runtime checks for each OS: resize/DPI, focus, Korean IME, clipboard,
  table interactions, plugin load/unload and resources from another working dir.
- Validate external runtime dependencies and notices in a clean installation.

No prebuilt Windows/macOS SDK was created or uploaded by that earlier Linux work. The Linux
validation package is a local test artifact, not a published full desktop release.
