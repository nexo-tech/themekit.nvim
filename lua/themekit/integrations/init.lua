-- Plugin integrations public API
-- Provides integration with external plugins (lualine, telescope, etc.)

local lualine = require("themekit.integrations.lualine")

local M = {}

-- Re-export lualine integration
M.apply_lualine = lualine.apply

return M
