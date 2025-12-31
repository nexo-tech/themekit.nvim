local M = {}

local initialized = false

M.init = function()
    if initialized then return end
    local commands = require("themekit.commands")
    commands.init()
    initialized = true
end

M.is_initialized = function()
    return initialized
end

M.apply = function(theme_name)
    local apply = require("themekit.commands.apply")
    apply.apply_theme(theme_name, { silent = true })
end

return M
