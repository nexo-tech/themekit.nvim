local M = {}

M.init = function()
    local commands = require("themekit.commands")
    commands.init()
end

M.apply = function(theme_name)
    local apply = require("themekit.commands.apply")
    apply.apply_theme(theme_name, { silent = true })
end

return M
