# Custom drawing without framework source

`examples/custom_draw/progress_widget.h` uses the **existing** public API:

- derive from `lotui::Widget`;
- implement `measure()` and override protected `onPaint()`;
- append backend-neutral `PaintCommand` values;
- keep `bounds()` and `clip()` in every emitted command;
- let LotGUI handle rendering, pipeline creation and input dispatch.

`ProgressWidget::Painter` also demonstrates an application callback: replace the
appearance without modifying the library. A slider changes both the derived
widget and callback-based view in `custom_draw_demo`.

```cpp
void onPaint(std::vector<lotui::PaintCommand>& commands) const override {
    commands.push_back({bounds(), clip(), {0.08F, 0.44F, 1.0F, 1.0F}});
}
```

The current command API draws colored/textured rectangles with corner radius.
Text can be emitted through `TextLayout::appendPaintCommands`. Arbitrary lines,
paths and raw Vulkan callbacks are **not** advertised as existing DrawContext APIs.
They need separate API design if requested.

`custom_draw_contract` exercises inherited drawing, callback replacement, clipping,
fill width and non-finite value normalization without a native window. Its checks
remain active in Release builds. To run only that contract against a core-capable SDK:

```sh
cmake -S . -B build-contract -DLOTGUI_SDK_ROOT=/path/to/sdk -DLOTGUI_BUILD_NATIVE_EXAMPLES=OFF
cmake --build build-contract
ctest --test-dir build-contract --output-on-failure
```
