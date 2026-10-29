#include "progress_widget.h"
#include "examples/platform_probe/platform_event_bridge.h"
#include "platform/platform_backend.h"
#include "renderer/vulkan/vulkan_renderer.h"
#include "widgets/linear_layout.h"
#include "widgets/slider.h"
#include <chrono>
#include <exception>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string_view>
#include <thread>

int main(int argc, char** argv) {
    try {
        const bool smoke = argc == 2 && std::string_view(argv[1]) == "--smoke";
        const bool capture = argc == 3 &&
            std::string_view(argv[1]) == "--capture";
        if (argc > 1 && !smoke && !capture) return 2;
        auto platform = lotui::createPlatformBackend();
        auto window = platform->createWindow({"LotGUI custom drawing", 640, 300, true});
        window->show();
        lotui::VulkanRenderer renderer(*window);
        auto column = std::make_unique<lotui::Column>();
        auto progress = std::make_unique<ProgressWidget>();
        auto* valueView = progress.get();
        column->addChild(std::move(progress));
        // Callback customization uses the same public PaintCommand contract.
        auto callbackView = std::make_unique<ProgressWidget>(0.5F,
            [](auto& commands, auto bounds, auto clip, float value) {
                bounds.width *= value;
                commands.push_back({bounds, clip, {1.0F, 0.45F, 0.1F, 1.0F},
                                    lotui::invalidTextureId, 4.0F});
            });
        auto* callbackValueView = callbackView.get();
        column->addChild(std::move(callbackView));
        column->addChild(std::make_unique<lotui::Slider>(
            lotui::SliderOptions{0.5, 0.0, 1.0, 0.01, {280.0F, 32.0F}},
            [valueView, callbackValueView](double value) {
                valueView->setValue(static_cast<float>(value));
                callbackValueView->setValue(static_cast<float>(value));
            }));
        lotui::WidgetTree tree(std::move(column));
        const auto layout = [](auto& widgets, const auto& metrics) {
            widgets.layout({24.0F, 24.0F,
                static_cast<float>(metrics.width) - 48.0F,
                static_cast<float>(metrics.height) - 48.0F});
        };
        layout(tree, window->metrics());
        bool running = true;
        std::vector<lotui::PaintCommand> commands;
        while (running) {
            lotui::PlatformEvent event{};
            while (window->pollEvent(event)) {
                running = lotui::example::dispatchPlatformEvent(event, tree, *window, layout) && running;
            }
            if (!running) break;
            commands.clear();
            tree.paint(commands);
            if (capture) {
                const auto frame = renderer.drawFrameCaptured(commands);
                std::ofstream output(argv[2], std::ios::binary);
                if (!output || frame.rgba.empty())
                    throw std::runtime_error("capture failed");
                output << "P6\n" << frame.width << ' ' << frame.height << "\n255\n";
                for (std::size_t pixel = 0; pixel < frame.rgba.size(); pixel += 4)
                    output.write(reinterpret_cast<const char*>(frame.rgba.data() + pixel), 3);
                if (!output) throw std::runtime_error("capture write failed");
                break;
            }
            renderer.drawFrame(commands);
            if (smoke) break;
            std::this_thread::sleep_for(std::chrono::milliseconds(8));
        }
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "custom_draw_demo: " << error.what() << '\n';
        return 1;
    }
}
