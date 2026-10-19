#pragma once
#include "core/widget.h"
#include <algorithm>
#include <cmath>
#include <functional>
#include <utility>

// Application-owned custom widget: no Vulkan objects or pipeline code.
class ProgressWidget final : public lotui::Widget {
public:
    using Painter = std::function<void(std::vector<lotui::PaintCommand>&,
                                      lotui::Rect, lotui::Rect, float)>;
    explicit ProgressWidget(float value = 0.5F, Painter painter = {})
        : value_(normalize(value)), painter_(std::move(painter)) {}
    lotui::Size measure(const lotui::LayoutConstraints& constraints) const override {
        return constraints.constrain({280.0F, 64.0F});
    }
    void setValue(float value) noexcept { value_ = normalize(value); }
    float value() const noexcept { return value_; }
protected:
    void onPaint(std::vector<lotui::PaintCommand>& commands) const override {
        const auto b = bounds();
        const auto c = clip();
        if (painter_) {
            painter_(commands, b, c, value_);
            return;
        }
        commands.push_back({b, c, {0.12F, 0.15F, 0.22F, 1.0F}, lotui::invalidTextureId, 8.0F});
        auto fill = b;
        fill.width *= value_;
        if (lotui::hasArea(fill)) {
            commands.push_back({fill, c, {0.08F, 0.44F, 1.0F, 1.0F}, lotui::invalidTextureId, 8.0F});
        }
    }
private:
    static float normalize(float value) noexcept {
        return std::isfinite(value) ? std::clamp(value, 0.0F, 1.0F) : 0.0F;
    }
    float value_;
    Painter painter_;
};
