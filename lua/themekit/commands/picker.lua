local library = require("themekit.library")
local apply = require("themekit.commands.apply")

local M = {}

-- UI Configuration
local config = {
    width = 60,
    height = 15,
    border = "rounded",
    title = " 🎨 Theme Picker ",
    prompt = "Select a theme: ",
    highlight_groups = {
        border = "FloatBorder",
        title = "FloatTitle",
        prompt = "FloatTitle",
        cursor = "CursorLine",
        selected = "PmenuSel",
        normal = "Normal",
        comment = "Comment"
    }
}

-- State management
local state = {
    themes = {},
    selected_index = 1,
    window_id = nil,
    buffer_id = nil,
    is_open = false,
    preview_mode = false
}

-- Utility functions
local function create_highlight_groups()
    -- Create highlight groups if they don't exist
    local highlights = {
        ["ThemePickerBorder"] = { link = "FloatBorder" },
        ["ThemePickerTitle"] = { link = "FloatTitle" },
        ["ThemePickerPrompt"] = { link = "FloatTitle" },
        ["ThemePickerCursor"] = { link = "CursorLine" },
        ["ThemePickerSelected"] = { link = "PmenuSel" },
        ["ThemePickerNormal"] = { link = "Normal" },
        ["ThemePickerComment"] = { link = "Comment" }
    }

    for name, attrs in pairs(highlights) do
        if attrs.link then
            vim.api.nvim_set_hl(0, name, { link = attrs.link })
        else
            vim.api.nvim_set_hl(0, name, attrs)
        end
    end
end

local function get_window_position()
    local editor_width = vim.o.columns
    local editor_height = vim.o.lines
    local width = math.min(config.width, editor_width - 4)
    local height = math.min(config.height, editor_height - 4)
    
    -- Adjust height based on number of themes
    local min_height = 8  -- Minimum height for title, prompt, footer
    local theme_height = #state.themes
    local adjusted_height = math.max(min_height, math.min(height, theme_height + min_height))
    
    local row = math.floor((editor_height - adjusted_height) / 2) - 1
    local col = math.floor((editor_width - width) / 2)
    
    return {
        row = row,
        col = col,
        width = width,
        height = adjusted_height
    }
end

local function create_window()
    if state.is_open then
        return
    end

    local pos = get_window_position()
    
    -- Create buffer
    state.buffer_id = vim.api.nvim_create_buf(false, true)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(state.buffer_id, "modifiable", false)
    vim.api.nvim_buf_set_option(state.buffer_id, "buftype", "nofile")
    vim.api.nvim_buf_set_option(state.buffer_id, "swapfile", false)
    vim.api.nvim_buf_set_option(state.buffer_id, "bufhidden", "wipe")
    
    -- Create window
    state.window_id = vim.api.nvim_open_win(state.buffer_id, true, {
        relative = "editor",
        row = pos.row,
        col = pos.col,
        width = pos.width,
        height = pos.height,
        style = "minimal",
        border = config.border
    })
    
    -- Set window options
    vim.api.nvim_win_set_option(state.window_id, "cursorline", false)
    vim.api.nvim_win_set_option(state.window_id, "number", false)
    vim.api.nvim_win_set_option(state.window_id, "relativenumber", false)
    vim.api.nvim_win_set_option(state.window_id, "signcolumn", "no")
    vim.api.nvim_win_set_option(state.window_id, "foldcolumn", "0")
    vim.api.nvim_win_set_option(state.window_id, "list", false)
    vim.api.nvim_win_set_option(state.window_id, "wrap", false)
    
    state.is_open = true
end

local function close_window()
    if state.window_id and vim.api.nvim_win_is_valid(state.window_id) then
        vim.api.nvim_win_close(state.window_id, true)
    end
    if state.buffer_id and vim.api.nvim_buf_is_valid(state.buffer_id) then
        vim.api.nvim_buf_delete(state.buffer_id, { force = true })
    end
    state.window_id = nil
    state.buffer_id = nil
    state.is_open = false
    state.selected_index = 1
end

local function render_content()
    if not state.buffer_id or not vim.api.nvim_buf_is_valid(state.buffer_id) then
        return
    end

    local lines = {}
    local highlights = {}
    
    -- Add title
    table.insert(lines, config.title)
    table.insert(highlights, { "ThemePickerTitle", 0, 0, -1 })
    
    -- Add separator
    table.insert(lines, string.rep("─", #config.title))
    table.insert(highlights, { "ThemePickerComment", 1, 0, -1 })
    
    -- Add prompt
    table.insert(lines, config.prompt .. "(" .. #state.themes .. " available)")
    table.insert(highlights, { "ThemePickerPrompt", 2, 0, -1 })
    
    -- Add separator
    table.insert(lines, "")
    table.insert(highlights, { "ThemePickerComment", 3, 0, -1 })
    
    -- Add themes list
    if #state.themes > 0 then
        for i, theme in ipairs(state.themes) do
            if theme and theme ~= "" then
                local prefix = i == state.selected_index and "▶ " or "  "
                local line = prefix .. theme
                table.insert(lines, line)
                
                if i == state.selected_index then
                    table.insert(highlights, { "ThemePickerSelected", #lines - 1, 0, -1 })
                else
                    table.insert(highlights, { "ThemePickerNormal", #lines - 1, 0, -1 })
                end
            end
        end
    else
        table.insert(lines, "  No themes available")
        table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })
    end
    
    -- Add footer
    table.insert(lines, "")
    table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })
    table.insert(lines, "┌─ Navigation ──────────────────────────────────────────┐")
    table.insert(highlights, { "ThemePickerComment", #lines, 0, -1 })
    table.insert(lines, "│ <CR>/<Space>/l Apply │ p Preview │ <Esc>/q/h Cancel │")
    table.insert(highlights, { "ThemePickerComment", #lines, 0, -1 })
    table.insert(lines, "└─────────────────────────────────────────────────────────┘")
    table.insert(highlights, { "ThemePickerComment", #lines, 0, -1 })
    
    -- Set buffer content
    vim.api.nvim_buf_set_option(state.buffer_id, "modifiable", true)
    vim.api.nvim_buf_set_lines(state.buffer_id, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(state.buffer_id, "modifiable", false)
    
    -- Apply highlights
    vim.api.nvim_buf_clear_namespace(state.buffer_id, -1, 0, -1)
    for _, hl in ipairs(highlights) do
        vim.api.nvim_buf_add_highlight(state.buffer_id, -1, hl[1], hl[2], hl[3], hl[4])
    end
    
    -- Set cursor position
    if #state.themes > 0 and state.selected_index >= 1 and state.selected_index <= #state.themes then
        local cursor_line = 4 + state.selected_index - 1
        vim.api.nvim_win_set_cursor(state.window_id, { cursor_line, 0 })
    else
        -- Set cursor to a safe position
        vim.api.nvim_win_set_cursor(state.window_id, { 4, 0 })
    end
end

local function move_selection(direction)
    if #state.themes == 0 then
        return
    end
    
    local new_index = state.selected_index + direction
    
    if new_index >= 1 and new_index <= #state.themes then
        state.selected_index = new_index
        render_content()
    end
end

local function apply_selected_theme()
    if #state.themes == 0 then
        vim.notify("No themes available", vim.log.levels.WARN)
        return
    end
    
    if state.selected_index >= 1 and state.selected_index <= #state.themes then
        local selected_theme = state.themes[state.selected_index]
        if selected_theme and selected_theme ~= "" then
            close_window()
            vim.notify("🎨 Applying theme: " .. selected_theme, vim.log.levels.INFO)
            apply.apply_theme(selected_theme)
        else
            vim.notify("Invalid theme selected", vim.log.levels.ERROR)
        end
    else
        vim.notify("Invalid selection index", vim.log.levels.ERROR)
    end
end

local function setup_keymaps()
    if not state.buffer_id or not vim.api.nvim_buf_is_valid(state.buffer_id) then
        return
    end
    
    local opts = { buffer = state.buffer_id, silent = true, nowait = true }
    
    -- Navigation
    vim.keymap.set("n", "j", function() move_selection(1) end, opts)
    vim.keymap.set("n", "k", function() move_selection(-1) end, opts)
    vim.keymap.set("n", "<Down>", function() move_selection(1) end, opts)
    vim.keymap.set("n", "<Up>", function() move_selection(-1) end, opts)
    vim.keymap.set("n", "gg", function() state.selected_index = 1; render_content() end, opts)
    vim.keymap.set("n", "G", function() state.selected_index = #state.themes; render_content() end, opts)
    
    -- Selection
    vim.keymap.set("n", "<CR>", apply_selected_theme, opts)
    vim.keymap.set("n", "<Space>", apply_selected_theme, opts)
    vim.keymap.set("n", "l", apply_selected_theme, opts)
    vim.keymap.set("n", "p", function()
        if #state.themes == 0 then
            vim.notify("No themes available", vim.log.levels.WARN)
            return
        end
        
        if state.selected_index >= 1 and state.selected_index <= #state.themes then
            local selected_theme = state.themes[state.selected_index]
            if selected_theme and selected_theme ~= "" then
                apply.apply_theme(selected_theme, { silent = true })
                vim.notify("🎨 Previewing: " .. selected_theme, vim.log.levels.INFO)
            else
                vim.notify("Invalid theme selected", vim.log.levels.ERROR)
            end
        else
            vim.notify("Invalid selection index", vim.log.levels.ERROR)
        end
    end, opts)
    
    -- Close
    vim.keymap.set("n", "<Esc>", close_window, opts)
    vim.keymap.set("n", "q", close_window, opts)
    vim.keymap.set("n", "h", close_window, opts)
    
    -- Search (optional)
    vim.keymap.set("n", "/", function()
        -- Could implement search functionality here
        vim.notify("Search functionality not implemented yet", vim.log.levels.INFO)
    end, opts)
end

function M.open_picker()
    -- Create highlight groups
    create_highlight_groups()
    
    -- Get available themes
    state.themes = library.list_available_themes()
    
    if #state.themes == 0 then
        vim.notify("🎨 No themes found. Create themes in ~/.config/nvim/themes/", vim.log.levels.WARN)
        return
    end
    
    -- Reset state
    state.selected_index = 1
    
    -- Ensure selected index is valid
    if #state.themes > 0 then
        state.selected_index = math.min(state.selected_index, #state.themes)
    else
        state.selected_index = 1
    end
    
    -- Create and setup window
    create_window()
    setup_keymaps()
    render_content()
    
    -- Set autocommands for cleanup
    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = state.buffer_id,
        callback = close_window,
        once = true
    })
    
    vim.api.nvim_create_autocmd("WinLeave", {
        callback = function()
            if state.window_id and vim.api.nvim_win_is_valid(state.window_id) then
                close_window()
            end
        end,
        once = true
    })
end

function M.setup_command()
    vim.api.nvim_create_user_command('ThemePicker', function()
        M.open_picker()
    end, {
        desc = "Open theme picker window"
    })
end

return M
