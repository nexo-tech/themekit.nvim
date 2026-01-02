-- Color blending utilities

local config = require("themekit.config")
local parser = require("themekit.color.parser")

local M = {}

-- Blend RGB components with ratio: result = c1 * ratio + c2 * (1 - ratio)
-- Returns: r, g, b (all 0-255)
function M.blend_rgb(r1, g1, b1, r2, g2, b2, ratio)
    return
        math.floor(r1 * ratio + r2 * (1 - ratio) + 0.5),
        math.floor(g1 * ratio + g2 * (1 - ratio) + 0.5),
        math.floor(b1 * ratio + b2 * (1 - ratio) + 0.5)
end

-- Blend two hex colors: result = fg * ratio + bg * (1 - ratio)
-- Returns: hex color string or fg_hex if parsing fails
function M.blend_colors(fg_hex, bg_hex, ratio)
    local r1, g1, b1 = parser.parse(fg_hex)
    local r2, g2, b2 = parser.parse(bg_hex)
    if not r1 or not r2 then return fg_hex end

    local r, g, b = M.blend_rgb(r1, g1, b1, r2, g2, b2, ratio)
    return parser.format(r, g, b)
end

-- Blend RGBA color onto background using alpha channel, return solid hex color
-- Returns: hex color string without alpha
function M.blend_alpha(fg_hex, bg_hex)
    local r1, g1, b1, a = parser.parse(fg_hex)
    if not r1 then return fg_hex end

    -- If fully opaque, just return as solid color
    if a == 255 then
        return parser.format(r1, g1, b1)
    end

    -- Parse background or use default
    bg_hex = bg_hex or config.DEFAULT_BG
    local r2, g2, b2 = parser.parse(bg_hex)
    if not r2 then r2, g2, b2 = 0, 0, 0 end

    -- Blend using alpha value
    local alpha = a / 255
    local r, g, b = M.blend_rgb(r1, g1, b1, r2, g2, b2, alpha)
    return parser.format(r, g, b)
end

-- Apply dim effect by blending foreground towards background
-- Used for the 'dim' modifier
function M.apply_dim(fg_hex, bg_hex, ratio)
    ratio = ratio or config.DIM_BLEND_RATIO
    return M.blend_colors(fg_hex, bg_hex, ratio)
end

return M
