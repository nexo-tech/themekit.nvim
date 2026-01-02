-- Lualine theme integration
-- Applies ThemeKit theme colors to Lualine statusline

local color = require("themekit.color")

local M = {}

-- Apply Lualine theme from ThemeKit theme
-- theme: theme data table
-- palette: resolved color palette
function M.apply(theme, palette)
    local statusline_attrs = theme['ui.statusline']
    if not statusline_attrs then return end

    local ok_lualine, lualine = pcall(require, "lualine")
    if not ok_lualine then return end

    local resolved_fg = statusline_attrs.fg and color.resolve(statusline_attrs.fg, palette)
    local resolved_bg = statusline_attrs.bg and color.resolve(statusline_attrs.bg, palette)

    lualine.setup({
        options = {
            theme = {
                normal = {
                    a = { fg = resolved_fg, bg = resolved_bg },
                    b = { fg = resolved_fg, bg = resolved_bg },
                    c = { fg = resolved_fg, bg = resolved_bg }
                }
            }
        }
    })
end

return M
