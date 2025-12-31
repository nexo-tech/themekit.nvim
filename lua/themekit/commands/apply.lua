local library = require("themekit.library")
local loader = require("themekit.loader")

local M = {}

M.current_theme = nil

function M.apply_theme(theme_name, opts)
    opts = opts or { silent = false }
    if not theme_name or theme_name == "" then
        vim.notify("Theme name is required", vim.log.levels.ERROR)
        return
    end

    -- Get the theme from library
    local theme = library.get_theme(theme_name)

    if not theme then
        if library.theme_exists(theme_name) then
            vim.notify("Failed to load theme '" .. theme_name .. "' - check theme file syntax", vim.log.levels.ERROR)
        else
            local available = library.list_available_themes()
            vim.notify(
                "Theme '" .. theme_name .. "' not found. Available: " .. table.concat(available, ", "),
                vim.log.levels.ERROR)
        end
        return
    end

    -- Apply the theme using the loader
    loader.apply(theme)
    M.current_theme = theme_name

    if not opts.silent then
        vim.notify("Applied theme: " .. theme_name, vim.log.levels.INFO)
    end
end

function M.setup_command()
    -- Create the command
    vim.api.nvim_create_user_command('ThemeApply', function(args)
        M.apply_theme(args.args)
    end, {
        nargs = 1,
        complete = function(ArgLead, CmdLine, CursorPos)
            local themes = library.list_available_themes()
            local matches = {}

            for _, theme in ipairs(themes) do
                if string.match(theme, "^" .. ArgLead) then
                    table.insert(matches, theme)
                end
            end

            return matches
        end,
        desc = "Apply a theme by name"
    })
end

return M
