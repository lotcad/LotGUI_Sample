# LotGUI SDK & Samples

[한국어](#한국어) · [English](#english)

## 한국어

LotGUI 라이브러리와 사용자 애플리케이션 예제를 분리한 배포용 저장소입니다.
Vulkan 파이프라인, 위젯 내부 구현 및 OS 백엔드의 구현 소스는 포함하지 않습니다.
공개 헤더와 예제 소스는 제공하며, **정적 라이브러리 SDK는 각 OS에서 별도로 빌드**합니다.
Windows x64용 LLVM-MinGW SDK와 macOS ARM64용 Apple Clang Release SDK는
`sdk/packages`에 포함되어 있습니다.

### Windows: VS Code에서 바로 빌드

1. 이 저장소를 ZIP으로 내려받아 압축을 풀거나 clone합니다.
2. VS Code에서 **폴더 열기**로 프로젝트를 엽니다.
3. **Ctrl+Shift+B**를 누릅니다.

처음 실행하면 LLVM-MinGW 컴파일러, CMake, Ninja, Vulkan 헤더와 한글 폰트를
`.tools`에 내려받고 예제를 `out/portable`에 빌드합니다. Visual Studio, Build Tools,
Git, Python, Vulkan SDK를 따로 설치할 필요가 없습니다. 첫 실행은 인터넷과 약 1.5 GB의
여유 공간이 필요합니다. 이후에는 내려받은 파일을 재사용합니다.

실행은 **Terminal → Run Task → LotGUI: run example (portable)**에서 예제를 선택합니다.
검증은 **LotGUI: test (portable)** 작업으로 실행합니다. VS Code 확장은 선택 사항입니다.

Windows 10/11 x64와 Vulkan을 지원하는 그래픽 드라이버가 필요합니다.
ARM64, 다른 컴파일러와의 SDK 혼용, Debug 빌드는 이 휴대용 패키지의 지원 범위가 아닙니다.
[자동 빌드 상세 안내](docs/portable-build.md)

### macOS ARM64: VS Code에서 빌드

macOS 27 이상에서 Apple Clang, CMake, Ninja, Vulkan SDK/MoltenVK, 공식 Noto Sans KR 폰트를
준비한 뒤 같은 VS Code 빌드·실행·테스트 작업을 사용할 수 있습니다.
macOS에서는 작업이 `tools/build-macos.sh`를 실행하고, 포함된 SDK ZIP을
검증·해제하여 `out/macos`에 빌드합니다. **Cmd+Shift+B**로 빌드하고
**Terminal → Run Task**에서 실행·테스트 작업을 선택합니다.
경로 설정과 터미널 명령은 [macOS 빌드 안내](docs/macos-build.md)를 참고하세요.

| 디렉터리 | 내용 |
|---|---|
| `sdk/include` | 공개 헤더 (이것만으로는 링크할 수 없음) |
| `sdk/<OS-CPU-toolchain>` | 별도 내보내기한 헤더·정적 라이브러리·CMake 패키지 |
| `examples/platform_probe` | 네이티브 창, 기본 위젯, 입력·IME 예제 |
| `examples/list_control_demo` | 테이블, 검색·필터, 셀 편집 예제 |
| `examples/conversation_demo` | 메신저형 대화 목록과 언어별 코드 블록 예제 |
| `examples/conversation_demo`의 `conversation_qa_demo` | 오른쪽 질문과 전체 너비 답변, 코드 복사 예제 |
| `examples/ribbon_demo` | 리본과 동적 플러그인 예제 |
| `examples/custom_draw` | `Widget` 상속 및 사용자 그리기 콜백 예제 |
| `docs` | API 사용 및 플랫폼별 배포 안내 |

예제는 `find_package(LotUI CONFIG REQUIRED)`로 설치된 SDK를 사용합니다.
개발용 원본 저장소를 `add_subdirectory()`로 넣거나 프레임워크 `.cpp`를 컴파일하지 않습니다.

기존 MSVC SDK를 사용한 수동 빌드:

```powershell
# 예: D:\vulkan\LotGUI_Sample 에서 실행
cmake -S . -B build -A x64 -DLOTGUI_SDK_ROOT="sdk/windows-x64-msvc" -DLOTGUI_FONT_FILE="../imgui/misc/fonts/NotoSansKR-Regular.ttf"
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure
```

실행 파일은 Visual Studio 구성에서 `build/Release`에 생성됩니다.
매칭되는 SDK, Vulkan, 텍스트 의존성 및 정식 폰트가 먼저 필요합니다.
[전체 안내](docs/sdk-distribution.md) · [Custom draw](docs/custom-draw.md)

## English

A distribution repository containing public LotGUI headers and application sample
sources. Framework implementation files, Vulkan pipeline sources, and OS backend
implementation files stay in the separate development repository.

Consume a prebuilt, matching **static DesktopSDK** through `find_package(LotUI)`.
Do not add the framework source tree to the application build. Build and validate
each OS/CPU/toolchain SDK independently.

On Windows 10/11 x64, open this folder in VS Code and press **Ctrl+Shift+B**.
The task downloads pinned portable LLVM-MinGW, CMake, Ninja, Vulkan headers and
Noto Sans KR, then builds against the included matching SDK archive. No Visual
Studio, Build Tools, Git, Python or Vulkan SDK installation is required. Internet
access is needed on the first run; a Vulkan-capable graphics driver is required
to run the GUI. Use **Terminal → Run Task → LotGUI: run example (portable)** to run.
See [portable build](docs/portable-build.md).

On Apple Silicon macOS 27 or later, the same VS Code tasks invoke `tools/build-macos.sh`
and build against the included ARM64 SDK archive. Apple Clang, CMake, Ninja,
Vulkan SDK/MoltenVK and an official Noto Sans KR font must already be available.
See [macOS build](docs/macos-build.md) for local configuration and runtime setup.

See [SDK distribution](docs/sdk-distribution.md), [custom drawing](docs/custom-draw.md)
and [verification status](docs/verification.md).

## License

The copied public headers and original example sources retain their existing MIT
license and copyright notices. See [LICENSE](LICENSE) and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). This split does not retroactively
change the license of already published code or decide a future binary SDK license.
