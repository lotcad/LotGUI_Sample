#include "progress_widget.h"
#include "core/widget_tree.h"
#include <cmath>
#include <iostream>
#include <limits>
#include <memory>
#include <stdexcept>

void require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
int main() {
    auto widget = std::make_unique<ProgressWidget>(0.25F);
    auto* progress = widget.get();
    lotui::WidgetTree tree(std::move(widget));
    tree.layout({10.0F, 20.0F, 200.0F, 40.0F}, {15.0F, 20.0F, 100.0F, 40.0F});
    std::vector<lotui::PaintCommand> commands;
    tree.paint(commands);
    require(commands.size() == 2, "background and progress fill expected");
    require(commands[1].bounds.width == 50.0F, "25 percent fill width expected");
    require(commands[0].clip.x == 15.0F && commands[0].clip.width == 100.0F,
            "custom drawing must retain parent clip");
    progress->setValue(2.0F);
    require(progress->value() == 1.0F, "value must clamp to 1");
    progress->setValue(std::numeric_limits<float>::quiet_NaN());
    require(progress->value() == 0.0F, "nonfinite value must be normalized");
    bool called = false;
    auto callbackWidget = std::make_unique<ProgressWidget>(0.5F,
        [&called](auto& output, auto bounds, auto clip, float value) {
            called = true;
            bounds.height *= value;
            output.push_back({bounds, clip, {1.0F, 0.5F, 0.1F, 1.0F}});
        });
    lotui::WidgetTree callbackTree(std::move(callbackWidget));
    callbackTree.layout({0, 0, 100, 80});
    commands.clear();
    callbackTree.paint(commands);
    require(called && commands.size() == 1 && commands[0].bounds.height == 40.0F,
            "application custom-draw callback must run");
    std::cout << "custom draw inheritance, callback, clipping and bounds passed\n";
}
