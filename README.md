# LotGUI SDK & Samples

[한국어](#한국어) · [English](#english)

## 한국어

LotGUI 라이브러리와 사용자 애플리케이션 예제를 분리한 배포용 저장소입니다.
Vulkan 파이프라인, 위젯 내부 구현 및 OS 백엔드의 구현 소스는 포함하지 않습니다.
공개 헤더와 예제 소스는 제공하며, **정적 라이브러리 SDK는 각 OS에서 별도로 빌드**합니다.
현재 Windows/macOS SDK 바이너리가 업로드되어 있다는 뜻은 아닙니다.

| 디렉터리 | 내용 |
|---|---|
| `sdk/include` | 공개 헤더 (이것만으로는 링크할 수 없음) |
| `sdk/<OS-CPU-toolchain>` | 별도 내보내기한 헤더·정적 라이브러리·CMake 패키지 |
| `examples/platform_probe` | 네이티브 창, 기본 위젯, 입력·IME 예제 |
| `examples/list_control_demo` | 테이블, 검색·필터, 셀 편집 예제 |
| `examples/ribbon_demo` | 리본과 동적 플러그인 예제 |
| `examples/custom_draw` | `Widget` 상속 및 사용자 그리기 콜백 예제 |
| `docs` | API 사용 및 플랫폼별 배포 안내 |

예제는 `find_package(LotUI CONFIG REQUIRED)`로 설치된 SDK를 사용합니다.
개발용 원본 저장소를 `add_subdirectory()`로 넣거나 프레임워크 `.cpp`를 컴파일하지 않습니다.

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
each OS/CPU/toolchain SDK independently; Windows and macOS binaries have not been
produced by the Linux-side preparation work.

See [SDK distribution](docs/sdk-distribution.md), [custom drawing](docs/custom-draw.md)
and [verification status](docs/verification.md).

## License

The copied public headers and original example sources retain their existing MIT
license and copyright notices. See [LICENSE](LICENSE) and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). This split does not retroactively
change the license of already published code or decide a future binary SDK license.
