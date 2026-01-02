-- Background color resolution utilities
-- Centralizes logic for extracting and resolving background colors

local config = require("themekit.config")

local M = {}

-- Extract and resolve background from theme definition
-- Extracts ui.background from theme and resolves to hex color
-- theme: theme data table
-- palette: color palette table
-- Returns: resolved hex color string or nil
function M.resolve_from_theme(theme, palette)
    local ui_bg = theme['ui.background']
    if not ui_bg then return nil end

    -- Extract bg color from ui.background (can be table or string)
    local bg_color = type(ui_bg) == 'table' and ui_bg.bg
                     or (type(ui_bg) == 'string' and ui_bg or nil)
    if not bg_color then return nil end

    -- Resolve palette reference if needed
    if not bg_color:match('^#') and palette then
        bg_color = palette[bg_color]
    end

    -- Return only if valid hex
    return bg_color and bg_color:match('^#') and bg_color or nil
end

-- Get background from palette with fallback chain
-- Tries: _resolved_bg → bg0 → bg → background → DEFAULT_BG
-- palette: color palette table
-- Returns: hex color string (always returns a value)
function M.get_from_palette(palette)
    if not palette then return config.DEFAULT_BG end

    -- Fallback chain (priority order):
    -- 1. _resolved_bg - Pre-resolved background from theme (set by loader)
    -- 2. bg0         - Common theme palette naming convention
    -- 3. bg          - Short form
    -- 4. background  - Verbose form
    -- 5. DEFAULT_BG  - Hardcoded fallback (#000000)
    local bg = palette._resolved_bg or palette.bg0 or palette.bg or palette.background
    if not bg then return config.DEFAULT_BG end

    -- Resolve palette reference if needed
    if not bg:match('^#') and palette[bg] then
        bg = palette[bg]
    end

    return bg or config.DEFAULT_BG
end

return M
