# Windows PowerShell 5.1+, Windows 10/11 x64. No installed compiler or Git needed.
[CmdletBinding()]
param(
    [ValidateSet('ribbon_demo', 'list_control_demo', 'platform_probe', 'custom_draw_demo')]
    [string]$Run,
    [switch]$Test,
    [switch]$PrepareOnly
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$tools = Join-Path $root '.tools'
$downloads = Join-Path $tools 'downloads'
$lock = Get-Content (Join-Path $PSScriptRoot 'portable-lock.json') -Raw | ConvertFrom-Json

function Invoke-Checked([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program failed (exit $LASTEXITCODE)" }
}

function Get-Asset($Asset) {
    $destination = Join-Path $downloads $Asset.file
    if ((Test-Path -LiteralPath $destination) -and
        (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -eq $Asset.sha256) {
        return $destination
    }
    Write-Host "Downloading $($Asset.file)..."
    $temporary = "$destination.partial"
    Invoke-Checked "$env:SystemRoot/System32/curl.exe" @(
        '--fail', '--location', '--retry', '3', '--proto', '=https',
        '--output', $temporary, $Asset.url
    )
    if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash -ne $Asset.sha256) {
        throw "SHA256 mismatch: $($Asset.file). Download was not used."
    }
    Move-Item -LiteralPath $temporary -Destination $destination -Force
    return $destination
}

function Expand-Asset($Asset, [string]$Directory, [string]$RequiredFile) {
    # Verify the archive even on cached runs. The marker is written only after extraction.
    $archive = Get-Asset $Asset
    $marker = Join-Path $Directory ('.lotgui-' + $Asset.sha256 + '.ready')
    if (!(Test-Path -LiteralPath $marker) -or !(Test-Path -LiteralPath $RequiredFile)) {
        New-Item -ItemType Directory -Force $Directory | Out-Null
        Write-Host "Extracting $($Asset.file)..."
        Invoke-Checked "$env:SystemRoot/System32/tar.exe" @('-xf', $archive, '-C', $Directory)
        if (!(Test-Path -LiteralPath $RequiredFile)) { throw "Incomplete archive: $($Asset.file)" }
        Set-Content -LiteralPath $marker -Value $Asset.sha256 -Encoding ASCII
    }
}

$previousPath = $env:PATH
$previousInclude = $env:INCLUDE
$previousLib = $env:LIB
try {
    if ($env:OS -ne 'Windows_NT' -or ![Environment]::Is64BitOperatingSystem -or
        $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
        throw 'The portable package supports Windows 10/11 on x64 PCs.'
    }
    New-Item -ItemType Directory -Force $downloads | Out-Null
    $compilerBin = Join-Path $tools 'llvm-mingw-20260616-ucrt-x86_64/bin'
    $cmakeBin = Join-Path $tools 'cmake-3.31.8-windows-x86_64/bin'
    $ninjaBin = Join-Path $tools 'ninja'
    $vulkanInclude = Join-Path $tools 'Vulkan-Headers-1.4.341/include'
    Expand-Asset $lock.compiler $tools "$compilerBin/x86_64-w64-mingw32-clang++.exe"
    Expand-Asset $lock.cmake $tools "$cmakeBin/cmake.exe"
    Expand-Asset $lock.ninja $ninjaBin "$ninjaBin/ninja.exe"
    Expand-Asset $lock.vulkanHeaders $tools "$vulkanInclude/vulkan/vulkan.h"
    $vulkanDef = Get-Asset $lock.vulkanDef
    $font = Get-Asset $lock.font
    $fontLicense = Get-Asset $lock.fontLicense

    # A checked-in SDK archive keeps private implementation sources out of consumer builds.
    $sdkArchive = Join-Path $root $lock.sdk.file
    if (!(Test-Path -LiteralPath $sdkArchive)) {
        throw "Missing SDK package: $sdkArchive. Obtain the complete sample repository."
    }
    if ((Get-FileHash -LiteralPath $sdkArchive -Algorithm SHA256).Hash -ne $lock.sdk.sha256) {
        throw 'SDK package SHA256 mismatch.'
    }
    $sdkDirectory = Join-Path $tools 'sdk'
    $sdkRoot = Join-Path $sdkDirectory 'windows-x64-llvm-mingw'
    $sdkMarker = Join-Path $sdkDirectory ('.lotgui-' + $lock.sdk.sha256 + '.ready')
    if (!(Test-Path -LiteralPath $sdkMarker) -or
        !(Test-Path -LiteralPath "$sdkRoot/lib/cmake/LotUI/LotUIConfig.cmake")) {
        New-Item -ItemType Directory -Force $sdkDirectory | Out-Null
        Invoke-Checked "$env:SystemRoot/System32/tar.exe" @('-xf', $sdkArchive, '-C', $sdkDirectory)
        Set-Content -LiteralPath $sdkMarker -Value $lock.sdk.sha256 -Encoding ASCII
    }

    # Use only the downloaded compiler/toolchain and Windows' built-in executables.
    # This also avoids picking up an installed Visual Studio compiler by accident.
    $env:PATH = "$compilerBin;$cmakeBin;$ninjaBin;$env:SystemRoot/System32;$env:SystemRoot"
    $env:INCLUDE = ''
    $env:LIB = ''
    $vulkanDirectory = Join-Path $tools 'vulkan'
    New-Item -ItemType Directory -Force $vulkanDirectory | Out-Null
    $vulkanLibrary = Join-Path $vulkanDirectory 'libvulkan-1.a'
    Invoke-Checked "$compilerBin/llvm-dlltool.exe" @(
        '-m', 'i386:x86-64', '-d', $vulkanDef, '-l', $vulkanLibrary
    )
    if ($PrepareOnly) { Write-Host 'Portable build tools and SDK are ready.'; return }

    $buildDirectory = Join-Path $root 'out/portable'
    $cmake = Join-Path $cmakeBin 'cmake.exe'
    Invoke-Checked $cmake @(
        '-S', $root, '-B', $buildDirectory, '-G', 'Ninja',
        '-DCMAKE_BUILD_TYPE=Release', '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
        "-DCMAKE_CXX_COMPILER=$compilerBin/x86_64-w64-mingw32-clang++.exe",
        "-DCMAKE_MAKE_PROGRAM=$ninjaBin/ninja.exe", "-DLOTGUI_SDK_ROOT=$sdkRoot",
        "-DLOTGUI_FONT_FILE=$font", "-DVulkan_INCLUDE_DIR=$vulkanInclude",
        "-DVulkan_LIBRARY=$vulkanLibrary"
    )
    Invoke-Checked $cmake @('--build', $buildDirectory, '--parallel')
    # LLVM-MinGW uses its own C++ runtime; stage it beside every sample executable.
    foreach ($runtime in @('libc++.dll', 'libunwind.dll', 'libwinpthread-1.dll')) {
        Copy-Item -LiteralPath "$compilerBin/$runtime" -Destination $buildDirectory -Force
    }
    Copy-Item -LiteralPath $fontLicense -Destination "$buildDirectory/legal/licenses/NOTO-SANS-KR-OFL.txt" -Force
    New-Item -ItemType Directory -Force "$buildDirectory/legal/toolchain" | Out-Null
    Copy-Item -Path "$tools/llvm-mingw-20260616-ucrt-x86_64/LICENSE*" -Destination "$buildDirectory/legal/toolchain" -Recurse -Force
    Copy-Item -LiteralPath "$tools/Vulkan-Headers-1.4.341/LICENSE.md" -Destination "$buildDirectory/legal/licenses/VULKAN-HEADERS-LICENSE.md" -Force
    Copy-Item -LiteralPath $vulkanDef -Destination "$buildDirectory/legal/licenses/VULKAN-LOADER-vulkan-1.def" -Force
    Copy-Item -Path "$tools/Vulkan-Headers-1.4.341/LICENSES/*" -Destination "$buildDirectory/legal/licenses" -Force

    if ($Test) {
        Invoke-Checked "$cmakeBin/ctest.exe" @('--test-dir', $buildDirectory, '--output-on-failure')
        foreach ($example in @('platform_probe', 'custom_draw_demo', 'ribbon_demo')) {
            Invoke-Checked "$buildDirectory/$example.exe" @('--smoke')
        }
        Invoke-Checked "$buildDirectory/ribbon_demo.exe" @('--input-test')
        Invoke-Checked "$buildDirectory/ribbon_demo.exe" @('--input-test-v1')
    }
    Write-Host "Build succeeded: $buildDirectory"
    if ($Run) { Invoke-Checked "$buildDirectory/$Run.exe" @() }
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
} finally {
    $env:PATH = $previousPath
    $env:INCLUDE = $previousInclude
    $env:LIB = $previousLib
}
