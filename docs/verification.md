# Verification status

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

No prebuilt Windows/macOS SDK was created or uploaded by this work. The Linux
validation package is a local test artifact, not a published full desktop release.
