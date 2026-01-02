-- Internal configuration for ThemeKit
-- Centralizes hardcoded constants and settings

local M = {}

-- Color processing constants
M.HEX_SHORT_MULTIPLIER = 17  -- Expands 4-bit to 8-bit color (0xF -> 0xFF)
M.DIM_BLEND_RATIO = 0.6      -- Dim modifier blends 60% foreground, 40% background
M.DEFAULT_BG = '#000000'     -- Default background (assumes dark terminal)

-- Highlight fallback constants
M.LINE_NUMBER_BRIGHTNESS_RATIO = 0.7  -- Blend 70% foreground, 30% white for brighter line numbers

-- Theme loading settings
M.themes_dir = vim.fn.stdpath('config') .. '/themes'
M.cache_themes = true  -- Enable theme caching

return M
