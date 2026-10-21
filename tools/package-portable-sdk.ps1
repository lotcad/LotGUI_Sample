# Maintainer tool. Consumers only need build-portable.ps1 and the resulting ZIP.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProducerBuild,
    [Parameter(Mandatory = $true)][string]$ProducerSource,
    [string]$SourceRevision = 'local working tree'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$cmake = Join-Path $root '.tools/cmake-3.31.8-windows-x86_64/bin/cmake.exe'
$cache = Get-Content (Join-Path $ProducerBuild 'CMakeCache.txt') -Raw
if ($cache -notmatch 'llvm-mingw-20260616-ucrt-x86_64' -or
    $cache -notmatch 'CMAKE_BUILD_TYPE:STRING=Release' -or
    $cache -notmatch 'LOTUI_STAGE_SAMPLE_SDK:BOOL=OFF') {
    throw 'Use a Release producer build with pinned LLVM-MinGW and LOTUI_STAGE_SAMPLE_SDK=OFF.'
}
$stage = Join-Path $root ('.tools/package-' + [Guid]::NewGuid().ToString('N'))
$prefix = Join-Path $stage 'windows-x64-llvm-mingw'
New-Item -ItemType Directory -Force $prefix | Out-Null
& $cmake --install $ProducerBuild --config Release --component DesktopSDK --prefix $prefix
if ($LASTEXITCODE -ne 0) { throw 'DesktopSDK installation failed.' }

# Export only the public header allowlist, with headers from the actual producer.
$publicRoot = (Resolve-Path (Join-Path $root 'sdk/include')).Path
foreach ($header in Get-ChildItem -LiteralPath $publicRoot -Recurse -File) {
    $relative = $header.FullName.Substring($publicRoot.Length + 1)
    $source = Join-Path $ProducerSource $relative
    if (!(Test-Path -LiteralPath $source)) { throw "Missing public header: $relative" }
    $destination = Join-Path $stage (Join-Path 'include' $relative)
    New-Item -ItemType Directory -Force (Split-Path $destination -Parent) | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination
}

# The producer's archive export omits HarfBuzz's pthread dependency on MinGW.
# Preserve it in this package so consumers do not need special linker flags.
$config = Join-Path $prefix 'lib/cmake/LotUI/LotUIConfig.cmake'
Add-Content -LiteralPath $config -Encoding ASCII -Value @'

if(MINGW)
    find_dependency(Threads)
    set_property(TARGET LotUI::harfbuzz APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES Threads::Threads)
endif()
'@
$legal = Join-Path $prefix 'share/LotUI'
New-Item -ItemType Directory -Force "$legal/licenses" | Out-Null
Copy-Item -LiteralPath "$root/LICENSE", "$root/THIRD_PARTY_NOTICES.md" -Destination $legal
Copy-Item -Path "$root/licenses/*" -Destination "$legal/licenses"
@{
    sourceRevision = $SourceRevision
    compiler = 'LLVM-MinGW 20260616 / Clang 22.1.8'
    configuration = 'Release'
    architecture = 'x86_64'
    headers = '../include'
    dependencies = @('FreeType 2.14.3', 'HarfBuzz 14.2.1', 'TinyXML-2 11.0.0')
} | ConvertTo-Json | Set-Content "$prefix/build-info-Release.json" -Encoding ASCII

New-Item -ItemType Directory -Force "$root/sdk/packages" | Out-Null
$archive = Join-Path $root 'sdk/packages/windows-x64-llvm-mingw-20260616.zip'
Compress-Archive -Path "$stage/include", $prefix -DestinationPath $archive -Force
$lockFile = Join-Path $PSScriptRoot 'portable-lock.json'
$lock = Get-Content -LiteralPath $lockFile -Raw | ConvertFrom-Json
$lock.sdk.sha256 = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
$lock | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $lockFile -Encoding ASCII
Write-Host "SDK package and lock updated: $archive"
