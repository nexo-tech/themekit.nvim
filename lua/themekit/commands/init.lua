local M = {}

M.init = function()
    -- Apply is needed at startup for theme loading
    require("themekit.commands.apply").setup_command()

    -- Defer picker and check commands — only load modules on first invocation
    vim.api.nvim_create_user_command('ThemePicker', function()
        require("themekit.commands.picker").open_picker()
    end, { desc = "Open theme picker window" })

    vim.api.nvim_create_user_command('ThemeCheck', function(opts)
        require("themekit.commands.check").check_theme(opts.args)
    end, {
        nargs = '?',
        complete = function()
            return require("themekit.library").list_available_themes()
        end,
        desc = 'Check theme key resolution status',
    })

    vim.api.nvim_create_user_command('ThemeCheckLineNumbers', function()
        require("themekit.commands.check").check_line_numbers()
    end, { desc = 'Check line number highlight configuration' })
end

return M
