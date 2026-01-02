-- Hex color parsing and formatting utilities

local config = require("themekit.config")

local M = {}

-- Format RGB values (0-255) as hex color string
function M.format(r, g, b)
    return string.format('#%02x%02x%02x', r, g, b)
end

-- Parse hex color components into r, g, b, a values (0-255)
-- Supports: #RGB, #RGBA, #RRGGBB, #RRGGBBAA
-- Returns: r, g, b, a (all 0-255) or nil on invalid input
function M.parse(hex)
    if not hex or not hex:match('^#') then return nil end

    local r, g, b, a
    local len = #hex - 1

    if len == 6 then
        -- #RRGGBB
        r = tonumber(hex:sub(2, 3), 16)
        g = tonumber(hex:sub(4, 5), 16)
        b = tonumber(hex:sub(6, 7), 16)
        a = 255
    elseif len == 8 then
        -- #RRGGBBAA
        r = tonumber(hex:sub(2, 3), 16)
        g = tonumber(hex:sub(4, 5), 16)
        b = tonumber(hex:sub(6, 7), 16)
        a = tonumber(hex:sub(8, 9), 16)
    elseif len == 3 then
        -- #RGB
        r = tonumber(hex:sub(2, 2), 16) * config.HEX_SHORT_MULTIPLIER
        g = tonumber(hex:sub(3, 3), 16) * config.HEX_SHORT_MULTIPLIER
        b = tonumber(hex:sub(4, 4), 16) * config.HEX_SHORT_MULTIPLIER
        a = 255
    elseif len == 4 then
        -- #RGBA
        r = tonumber(hex:sub(2, 2), 16) * config.HEX_SHORT_MULTIPLIER
        g = tonumber(hex:sub(3, 3), 16) * config.HEX_SHORT_MULTIPLIER
        b = tonumber(hex:sub(4, 4), 16) * config.HEX_SHORT_MULTIPLIER
        a = tonumber(hex:sub(5, 5), 16) * config.HEX_SHORT_MULTIPLIER
    else
        return nil
    end

    return r, g, b, a
end

-- Check if a string is a valid hex color
function M.is_valid_hex(str)
    return str and str:match('^#%x+$') ~= nil
end

return M
