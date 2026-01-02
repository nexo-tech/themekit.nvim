-- Color resolution with palette support and caching

local parser = require("themekit.color.parser")
local blender = require("themekit.color.blender")
local fallbacks = require("themekit.color.fallbacks")
local background = require("themekit.color.background")

local M = {}

-- Color resolution cache
-- FIX: Now uses context-aware keys to prevent alpha blending bugs
local color_cache = {}

-- Create cache key that includes background context
-- This fixes the bug where same color with different backgrounds returned wrong cached value
local function make_cache_key(color, bg_color)
    return bg_color and (color .. "|" .. bg_color) or color
end

-- Clear the color cache (called when switching themes)
function M.clear_cache()
    color_cache = {}
end

-- Helper: Resolve hex color with optional alpha blending
local function resolve_hex_color(color, bg_color, palette)
    local len = #color - 1

    -- Solid color (no alpha channel)
    if len ~= 8 and len ~= 4 then
        return color
    end

    -- Alpha blending required
    local bg = bg_color or background.get_from_palette(palette)
    return blender.blend_alpha(color, bg)
end

-- Helper: Resolve palette reference recursively
local function resolve_palette_reference(color, palette, bg_color, visited)
    if not palette or not palette[color] then
        return nil
    end
    return M.resolve(palette[color], palette, bg_color, visited)
end

-- Helper: Get named color fallback
local function resolve_named_fallback(color)
    return fallbacks[color]
end

-- Resolve color from palette with cycle detection and caching
-- color: string - hex color, palette reference, or named color
-- palette: table - theme palette for resolving references
-- bg_color: string - background color for alpha blending context
-- visited: table - internal cycle detection (users shouldn't pass this)
-- Returns: resolved hex color string or nil
function M.resolve(color, palette, bg_color, visited)
    -- Validate input
    if not color or type(color) ~= 'string' then
        return nil
    end

    -- Check cache first (context-aware key)
    local cache_key = make_cache_key(color, bg_color)
    if color_cache[cache_key] then
        return color_cache[cache_key]
    end

    -- Cycle detection
    visited = visited or {}
    if visited[color] then
        return nil  -- Circular reference
    end
    visited[color] = true

    -- Resolve based on color type (dispatcher with early returns for clarity)
    local result

    if parser.is_valid_hex(color) then
        result = resolve_hex_color(color, bg_color, palette)
    else
        -- Try palette reference, then named fallback, then use as-is
        result = resolve_palette_reference(color, palette, bg_color, visited)
                 or resolve_named_fallback(color)
                 or color
    end

    -- Cache and return
    if result then
        color_cache[cache_key] = result
    end

    return result
end

return M
