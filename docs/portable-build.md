# Windows portable build / VS Code 자동 빌드

## 사용자

Windows 10/11 x64에서 저장소를 ZIP으로 받거나 clone한 뒤, VS Code에서 폴더를 열고
**Ctrl+Shift+B**를 누릅니다. 기본 작업은 `LotGUI: build (portable)`입니다.
인터넷은 최초 다운로드에 필요하며, 이후에는 캐시를 재사용합니다.
관리자 권한과 별도의 Visual Studio/Build Tools, Python, Git, CMake, Vulkan SDK
설치가 필요하지 않습니다. Windows 내장 PowerShell, curl, tar를 사용합니다.
VS Code의 Workspace Trust 안내가 나오면 이 프로젝트의 내용을 확인하고 신뢰해야
프로젝트 작업을 실행할 수 있습니다. C/C++ 확장은 코드 탐색을 위한 선택 사항입니다.

실행: **Terminal → Run Task → LotGUI: run example (portable)**에서 예제를 선택합니다.
결과는 `out/portable`에 생성됩니다. `LotGUI: test (portable)`는 자동 테스트 2개,
GUI smoke 검사 3개와 리본 플러그인 V1/V2 입력 검사를 실행합니다.
테스트 중 GUI 창이 잠시 나타났다가 닫힙니다.

VS Code 없이도 저장소 폴더에서 다음 명령을 실행할 수 있습니다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build-portable.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build-portable.ps1 -Run ribbon_demo
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build-portable.ps1 -Test
```

다운로드와 압축 해제에 약 1.5 GB의 여유 공간을 확보하세요. 모든 도구는 `.tools`에
저장됩니다. 설치된 Visual Studio와 시스템 PATH를 변경하지 않습니다.
빌드 프로세스에서는 휴대용 도구만 PATH에 넣어 설치된 컴파일러와의 혼용을 방지합니다.
`-ExecutionPolicy Bypass`는 이 작업 프로세스에만 적용됩니다.
방화벽이나 프록시가 다운로드를 차단하면 해당 네트워크 설정이 필요합니다.

## 구성과 범위

| 항목 | 버전 / 출처 |
|---|---|
| 컴파일러 | [LLVM-MinGW 20260616, Clang 22.1.8](https://github.com/mstorsjo/llvm-mingw/releases/tag/20260616), UCRT x64 |
| 빌드 도구 | [CMake 3.31.8](https://github.com/Kitware/CMake/releases/tag/v3.31.8), [Ninja 1.12.1](https://github.com/ninja-build/ninja/releases/tag/v1.12.1) |
| LotGUI SDK | 저장소의 `sdk/packages/windows-x64-llvm-mingw-20260616.zip`, Release 정적 라이브러리 |
| Vulkan 개발 파일 | [Khronos Vulkan-Headers 1.4.341](https://github.com/KhronosGroup/Vulkan-Headers/tree/v1.4.341), Vulkan-Loader의 같은 버전 `vulkan-1.def` |
| 한글 폰트 | [Google Fonts Noto Sans KR](https://github.com/google/fonts/tree/b38c5c93af322c45f633e17ac440ec1e6c94d489/ofl/notosanskr), 공식 가변 폰트와 OFL |

다운로드 URL과 SHA256은 `tools/portable-lock.json`에 고정되어 있습니다.
해시가 다르면 사용하지 않습니다. 외부 설치 스크립트를 내려받아 실행하지 않습니다.
샘플은 SDK 헤더와 정적 라이브러리를 사용하며 프레임워크 구현 소스를 요구하지 않습니다.
SDK ZIP에는 짝이 맞는 공개 헤더, 정적 라이브러리, CMake 패키지와 배포 고지가 들어 있습니다.
컴파일러 런타임 DLL과 관련 고지는 실행 파일 옆에 복사됩니다.

실행 시 Vulkan을 지원하는 GPU와 정상 설치된 그래픽 드라이버가 필요합니다.
드라이버를 프로젝트가 설치하지는 않습니다. Windows ARM64, Debug, macOS/Linux는
이 휴대용 SDK의 대상이 아닙니다. 다른 GCC/Clang/MSVC SDK와 섞어 링크하지 마세요.
기존 MSVC 수동 빌드는 별도 `build` 폴더에서 계속 사용할 수 있습니다.

## SDK 갱신 (유지관리자)

원본 LotGUI와 FreeType 2.14.3, HarfBuzz 14.2.1, TinyXML-2 11.0.0 소스를 준비합니다.
원본 소스를 이 저장소에 복사하지 않고 외부 소스 경로에서 빌드합니다.
셰이더를 SDK에 내장하기 위한 `glslangValidator`는 SDK 생산자에게만 필요합니다.

1. `tools/build-portable.ps1 -PrepareOnly`로 고정된 도구를 준비합니다.
2. `.tools/llvm-mingw-20260616-ucrt-x86_64/bin`을 해당 터미널의 PATH 앞에 추가합니다.
3. 원본을 별도 폴더에 CMake Ninja Release로 구성합니다. C/C++ 컴파일러는 각각
   `x86_64-w64-mingw32-clang`, `x86_64-w64-mingw32-clang++`로 지정합니다.
   `BUILD_SHARED_LIBS=OFF`, `BUILD_TESTING=OFF`, `LOTUI_BUILD_EXAMPLES=OFF`,
   `LOTUI_BUILD_DESKTOP_SDK=ON`, `LOTUI_STAGE_SAMPLE_SDK=OFF`,
   `LOTUI_STAGE_3DENGINE_SDK=OFF`를 지정하고 의존성 소스와 Vulkan SDK 경로를 전달합니다.
4. 원본 빌드를 완료한 뒤 패키징합니다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/package-portable-sdk.ps1 `
  -ProducerBuild path/to/producer-build -ProducerSource path/to/LotGUI `
  -SourceRevision "source revision or working-tree description"
```

패키저는 DesktopSDK만 설치하고 공개 헤더 목록만 복사합니다. MinGW에서 HarfBuzz에
필요한 Threads 의존성을 CMake 패키지에 추가하고 SDK ZIP과 lock 파일을 갱신합니다.
새 공개 헤더가 생겼다면 `sdk/include`의 공개 헤더 목록도 먼저 갱신해야 합니다.
`-Test`로 소비자 빌드와 실행을 검증한 뒤 SDK ZIP, lock 파일, 관련 코드와 문서를
함께 커밋해야 다른 사용자의 GitHub ZIP 다운로드에도 반영됩니다.
