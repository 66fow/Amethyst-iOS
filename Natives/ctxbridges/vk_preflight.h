#pragma once

#include <stdbool.h>
#include <stdint.h>

typedef struct {
    bool ok;
    uint32_t apiVersion;
    char error[256];
} ame_vk_preflight_t;

// loads the Vulkan library and checks it can make a Metal surface, no instance is created
ame_vk_preflight_t ame_vk_preflight(const char *dylibPath);
