local check = require("themekit.commands.check")
local apply = require("themekit.commands.apply")
local picker = require("themekit.commands.picker")

local M = {}

M.init = function()
    check.setup_command()
    apply.setup_command()
    picker.setup_command()
end

return M
