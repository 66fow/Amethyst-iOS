#pragma once

#include <math.h>
#include <stdbool.h>
#include <stdint.h>

// MoltenVK only calls a swapchain optimal when the layer's drawableSize equals
// round-half-even(bounds * contentsScale), otherwise every acquire returns VK_SUBOPTIMAL_KHR
static inline void ame_vk_drawable_extent(double width, double height, double scale, uint32_t *outW, uint32_t *outH) {
    double w = rint(width * scale);
    double h = rint(height * scale);
    *outW = w < 1 ? 1 : (uint32_t)w;
    *outH = h < 1 ? 1 : (uint32_t)h;
}

// the game asked for no GL context (GLFW_NO_API), true from then on
bool AMVulkanNativeActive(void);

// layer handed to the game as its GLFW window, marks the session as Vulkan
void *AMVulkanSurfaceLayer(void);

// a GL context was requested while the MoltenVK renderer is selected
void AMVulkanNoteGLFallback(void);
