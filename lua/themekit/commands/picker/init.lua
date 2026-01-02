-- Picker module public API
-- Facade that orchestrates all picker modules

local state = require("themekit.commands.picker.state")
local keymaps = require("themekit.commands.picker.keymaps")
local renderer = require("themekit.commands.picker.renderer")
local lifecycle = require("themekit.commands.picker.lifecycle")

local M = {}

-- Re-export configuration for user customization
M.config = renderer.config

-- Main entry point - opens the theme picker
function M.open_picker()
    local library = require("themekit.library")
    local theme_state = require("themekit.state")

    -- Create highlight groups
    lifecycle.create_highlight_groups()

    -- Get available themes
    local themes = library.list_available_themes()
    if #themes == 0 then
        vim.notify("🎨 No themes found. Create themes in ~/.config/nvim/themes/", vim.log.levels.WARN)
        return
    end

    -- Find current theme index
    local current_theme = theme_state.get_current_theme()
    local current_index = library.find_theme_index(current_theme) or 1

    -- Initialize state
    state.init({
        themes = themes,
        selected_index = math.min(current_index, #themes),
        original_theme = current_theme or themes[1],
    })

    -- Create window
    lifecycle.create_window()

    -- Setup keymaps (normal mode initially)
    keymaps.setup(state.ui_state.buffer_id)

    -- Render initial content
    renderer.render()

    -- Setup autocmds
    lifecycle.setup_autocmds()

    -- Preview current selection
    local initial_theme = state.get_selected_theme()
    if initial_theme then
        local apply = require('themekit.commands.apply')
        apply.apply_theme(initial_theme, { silent = true })
    end
end

-- Setup command
function M.setup_command()
    vim.api.nvim_create_user_command('ThemePicker', M.open_picker, {
        desc = "Open theme picker window"
    })
end

return M
