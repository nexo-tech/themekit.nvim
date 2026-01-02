-- Color module public API
-- Provides color parsing, blending, and resolution with palette support

local config = require("themekit.config")
local parser = require("themekit.color.parser")
local blender = require("themekit.color.blender")
local resolver = require("themekit.color.resolver")
local fallbacks = require("themekit.color.fallbacks")
local background = require("themekit.color.background")

local M = {}

-- Re-export parser functions
M.parse = parser.parse
M.format = parser.format
M.is_valid_hex = parser.is_valid_hex

-- Re-export blending functions
M.blend_rgb = blender.blend_rgb
M.blend_colors = blender.blend_colors
M.blend_alpha = blender.blend_alpha
M.apply_dim = blender.apply_dim

-- Re-export resolver
M.resolve = resolver.resolve
M.clear_cache = resolver.clear_cache

-- Re-export constants from config (single source of truth)
M.HEX_SHORT_MULTIPLIER = config.HEX_SHORT_MULTIPLIER
M.DEFAULT_BG = config.DEFAULT_BG
M.DIM_BLEND_RATIO = config.DIM_BLEND_RATIO

-- Re-export background utilities
M.resolve_background = background.resolve_from_theme
M.get_background = background.get_from_palette

-- Re-export fallbacks
M.fallbacks = fallbacks

return M
