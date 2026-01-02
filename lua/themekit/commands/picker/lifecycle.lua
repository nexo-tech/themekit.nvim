-- Picker lifecycle module
-- Handles window creation, autocmd setup, and proper cleanup

local M = {}

-- Calculate window position (pure function)
function M.get_window_position()
    local renderer = require("themekit.commands.picker.renderer")
    local editor_width = vim.o.columns
    local editor_height = vim.o.lines
    local width = math.min(renderer.config.width, editor_width - 4)
    local height = math.min(renderer.config.height, editor_height - 4)

    local chrome_lines = renderer.config.header_lines + renderer.config.footer_lines
    local visible_lines = math.max(5, height - chrome_lines)

    local row = math.floor((editor_height - height) / 2) - 1
    local col = math.floor((editor_width - width) / 2)

    return {
        row = row,
        col = col,
        width = width,
        height = height,
        visible_lines = visible_lines
    }
end

-- Create highlight groups for picker UI
function M.create_highlight_groups()
    local highlights = {
        ["ThemePickerBorder"] = { link = "FloatBorder" },
        ["ThemePickerTitle"] = { link = "FloatTitle" },
        ["ThemePickerPrompt"] = { link = "FloatTitle" },
        ["ThemePickerSelected"] = { link = "PmenuSel" },
        ["ThemePickerNormal"] = { link = "Normal" },
        ["ThemePickerComment"] = { link = "Comment" },
        ["ThemePickerSearchMatch"] = { fg = "#ffd700", bold = true },
    }

    for name, attrs in pairs(highlights) do
        if attrs.link then
            vim.api.nvim_set_hl(0, name, { link = attrs.link })
        else
            vim.api.nvim_set_hl(0, name, attrs)
        end
    end
end

-- Create window and buffer
function M.create_window()
    local state_mod = require("themekit.commands.picker.state")
    local renderer = require("themekit.commands.picker.renderer")

    if state_mod.ui_state.is_open then return end

    local pos = M.get_window_position()

    -- Update visible_lines in state
    state_mod.navigation_state.visible_lines = pos.visible_lines

    -- Create buffer
    local buf = vim.api.nvim_create_buf(false, true)
    state_mod.ui_state.buffer_id = buf

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_name(buf, "ThemePicker")

    -- Create window
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        row = pos.row,
        col = pos.col,
        width = pos.width,
        height = pos.height,
        border = renderer.config.border,
        title = renderer.config.title,
        title_pos = "center",
        style = "minimal",
    })
    state_mod.ui_state.window_id = win

    -- Set window options
    vim.api.nvim_win_set_option(win, "cursorline", false)
    vim.api.nvim_win_set_option(win, "number", false)
    vim.api.nvim_win_set_option(win, "relativenumber", false)
    vim.api.nvim_win_set_option(win, "signcolumn", "no")
    vim.api.nvim_win_set_option(win, "wrap", false)

    state_mod.ui_state.is_open = true
end

-- Setup autocmds with proper cleanup
function M.setup_autocmds()
    local state_mod = require("themekit.commands.picker.state")

    -- Create autocmd group for cleanup
    local group = vim.api.nvim_create_augroup("ThemePickerCleanup", { clear = true })
    state_mod.session_state.autocmd_group = group

    -- Use ONLY BufLeave to avoid race condition
    -- (WinLeave can fire before BufLeave, causing double-close issues)
    vim.api.nvim_create_autocmd("BufLeave", {
        group = group,
        buffer = state_mod.ui_state.buffer_id,
        callback = function()
            M.close(true)  -- true = revert to original
        end,
        once = true
    })
end

-- Close window (single entry point - no guard flag needed!)
-- revert: boolean - if true, revert to original theme
function M.close(revert)
    local state_mod = require("themekit.commands.picker.state")

    -- Simple guard (this is the single entry point)
    if not state_mod.ui_state.is_open then return end

    -- Clear autocmds FIRST (prevent re-triggering)
    if state_mod.session_state.autocmd_group then
        vim.api.nvim_del_augroup_by_id(state_mod.session_state.autocmd_group)
        state_mod.session_state.autocmd_group = nil
    end

    -- Revert if requested
    if revert and state_mod.session_state.original_theme then
        local apply = require('themekit.commands.apply')
        apply.apply_theme(state_mod.session_state.original_theme, { silent = true })
        vim.notify("🎨 Reverted to original theme: " .. state_mod.session_state.original_theme, vim.log.levels.INFO)
    end

    -- Close window/buffer
    if state_mod.ui_state.window_id and vim.api.nvim_win_is_valid(state_mod.ui_state.window_id) then
        vim.api.nvim_win_close(state_mod.ui_state.window_id, true)
    end
    if state_mod.ui_state.buffer_id and vim.api.nvim_buf_is_valid(state_mod.ui_state.buffer_id) then
        vim.api.nvim_buf_delete(state_mod.ui_state.buffer_id, { force = true })
    end

    -- Reset state
    state_mod.reset()
end

-- Apply selected theme and close (no revert)
function M.apply_and_close()
    local state_mod = require("themekit.commands.picker.state")
    local theme = state_mod.get_selected_theme()

    if not theme then
        vim.notify("No theme selected", vim.log.levels.WARN)
        return
    end

    -- Update original theme to selected (prevents revert)
    state_mod.session_state.original_theme = theme

    -- Close without revert
    M.close(false)

    -- Apply theme (final)
    local apply = require('themekit.commands.apply')
    vim.notify("🎨 Applied theme: " .. theme, vim.log.levels.INFO)
    apply.apply_theme(theme)
end

return M
