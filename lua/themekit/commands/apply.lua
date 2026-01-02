local loader = require("themekit.loader")
local state = require("themekit.state")
local utils = require("themekit.commands.utils")

local M = {}

function M.apply_theme(theme_name, opts)
    opts = opts or { silent = false }

    -- Get the theme safely
    local theme, err = utils.get_theme_safe(theme_name)
    if not theme then
        utils.notify_error(err)
        return
    end

    -- Apply the theme using the loader
    loader.apply(theme, theme_name)
    state.set_current_theme(theme_name)

    if not opts.silent then
        utils.notify_success("Applied theme: " .. theme_name)
    end
end

function M.setup_command()
    vim.api.nvim_create_user_command('ThemeApply', function(args)
        M.apply_theme(args.args)
    end, {
        nargs = 1,
        complete = function(arg_lead)
            return utils.complete_theme_names(arg_lead)
        end,
        desc = "Apply a theme by name"
    })
end

return M
