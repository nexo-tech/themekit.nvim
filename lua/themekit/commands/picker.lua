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
    preview_mode = false,
    original_theme = nil,
    scroll_offset = 0,
    visible_lines = 0
}

-- Utility functions
local function create_highlight_groups()
    -- Create highlight groups if they don't exist
    -- Use Visual highlight for selected item - it has a clear background that shows selection
    local highlights = {
        ["ThemePickerBorder"] = { link = "FloatBorder" },
        ["ThemePickerTitle"] = { link = "FloatTitle" },
        ["ThemePickerPrompt"] = { link = "FloatTitle" },
        ["ThemePickerCursor"] = { link = "CursorLine" },
        ["ThemePickerSelected"] = { link = "Visual" },  -- Changed from PmenuSel to Visual for better visibility
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
    
    -- Calculate available space for theme list (header + footer take about 8 lines)
    local header_footer_lines = 8
    state.visible_lines = math.max(5, height - header_footer_lines)
    
    local row = math.floor((editor_height - height) / 2) - 1
    local col = math.floor((editor_width - width) / 2)
    
    return {
        row = row,
        col = col,
        width = width,
        height = height
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
    vim.api.nvim_win_set_option(state.window_id, "cursorcolumn", false)
    
    -- Completely hide the cursor - make it invisible
    vim.cmd('highlight Cursor blend=100')
    vim.api.nvim_win_set_option(state.window_id, "guicursor", "a:Cursor/lCursor")
    
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
    state.scroll_offset = 0
    state.visible_lines = 0
    state.original_theme = nil
end

local function update_scroll_offset()
    -- Ensure the selected item is visible within the window
    local header_lines = 4  -- Title, separator, prompt, empty line
    local selected_line = state.selected_index
    
    -- Calculate which line the selected theme should appear on in the visible area
    local target_line = selected_line - state.scroll_offset
    
    -- If selected item is above visible area, scroll up
    if target_line < 1 then
        state.scroll_offset = selected_line - 1
    -- If selected item is below visible area, scroll down
    elseif target_line > state.visible_lines then
        state.scroll_offset = selected_line - state.visible_lines
    end
    
    -- Ensure scroll offset doesn't go below 0
    state.scroll_offset = math.max(0, state.scroll_offset)
    
    -- Ensure we don't scroll past the end of the list
    local max_scroll = math.max(0, #state.themes - state.visible_lines)
    state.scroll_offset = math.min(state.scroll_offset, max_scroll)
end

local function render_content()
    if not state.buffer_id or not vim.api.nvim_buf_is_valid(state.buffer_id) then
        return
    end

    update_scroll_offset()
    
    local lines = {}
    local highlights = {}
    
    -- Add title
    table.insert(lines, config.title)
    table.insert(highlights, { "ThemePickerTitle", 0, 0, -1 })
    
    -- Add separator
    table.insert(lines, string.rep("─", #config.title))
    table.insert(highlights, { "ThemePickerComment", 1, 0, -1 })
    
    -- Add prompt with scroll indicator
    local scroll_indicator = ""
    if #state.themes > state.visible_lines then
        local current_page = math.floor(state.scroll_offset / state.visible_lines) + 1
        local total_pages = math.ceil(#state.themes / state.visible_lines)
        scroll_indicator = string.format(" [%d/%d]", current_page, total_pages)
    end
    table.insert(lines, config.prompt .. "(" .. #state.themes .. " available)" .. scroll_indicator)
    table.insert(highlights, { "ThemePickerPrompt", 2, 0, -1 })
    
    -- Add separator
    table.insert(lines, "")
    table.insert(highlights, { "ThemePickerComment", 3, 0, -1 })
    
    -- Add themes list (only visible portion)
    if #state.themes > 0 then
        local start_idx = state.scroll_offset + 1
        local end_idx = math.min(state.scroll_offset + state.visible_lines, #state.themes)
        
        for i = start_idx, end_idx do
            local theme = state.themes[i]
            if theme and theme ~= "" then
                local prefix = "  "
                if i == state.selected_index then
                    prefix = "> "
                end
                local line = prefix .. theme
                table.insert(lines, line)
                
                if i == state.selected_index then
                    table.insert(highlights, { "ThemePickerSelected", #lines - 1, 0, -1 })
                else
                    table.insert(highlights, { "ThemePickerNormal", #lines - 1, 0, -1 })
                end
            end
        end
        
        -- Fill remaining visible lines if needed
        while #lines < 4 + state.visible_lines do
            table.insert(lines, "")
            table.insert(highlights, { "ThemePickerNormal", #lines - 1, 0, -1 })
        end
    else
        table.insert(lines, "  No themes available")
        table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })
    end
    
    -- Add footer
    table.insert(lines, "")
    table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })
    table.insert(lines, "─────────────────────────────────────────────────────────")
    table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })
    table.insert(lines, " j/k: Navigate  │  Enter: Apply  │  Esc/q: Cancel")
    table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })
    
    -- Set buffer content
    vim.api.nvim_buf_set_option(state.buffer_id, "modifiable", true)
    vim.api.nvim_buf_set_lines(state.buffer_id, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(state.buffer_id, "modifiable", false)
    
    -- Apply highlights
    vim.api.nvim_buf_clear_namespace(state.buffer_id, -1, 0, -1)
    for _, hl in ipairs(highlights) do
        vim.api.nvim_buf_add_highlight(state.buffer_id, -1, hl[1], hl[2], hl[3], hl[4])
    end
    
    -- Move cursor out of the way (to top) since we're using highlighting for selection
    vim.api.nvim_win_set_cursor(state.window_id, { 1, 0 })
end

local function move_selection(direction)
    if #state.themes == 0 then
        return
    end
    
    local new_index = state.selected_index + direction
    
    if new_index >= 1 and new_index <= #state.themes then
        state.selected_index = new_index
        render_content()
        
        -- Apply theme instantly for preview
        local selected_theme = state.themes[state.selected_index]
        if selected_theme and selected_theme ~= "" then
            apply.apply_theme(selected_theme, { silent = true })
        end
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
            -- Update the original theme to the selected one
            state.original_theme = selected_theme
            close_window()
            vim.notify("🎨 Applied theme: " .. selected_theme, vim.log.levels.INFO)
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
    vim.keymap.set("n", "<C-n>", function() move_selection(1) end, opts)
    vim.keymap.set("n", "<C-p>", function() move_selection(-1) end, opts)
    vim.keymap.set("n", "gg", function() 
        state.selected_index = 1
        render_content()
        local selected_theme = state.themes[state.selected_index]
        if selected_theme and selected_theme ~= "" then
            apply.apply_theme(selected_theme, { silent = true })
        end
    end, opts)
    vim.keymap.set("n", "G", function() 
        state.selected_index = #state.themes
        render_content()
        local selected_theme = state.themes[state.selected_index]
        if selected_theme and selected_theme ~= "" then
            apply.apply_theme(selected_theme, { silent = true })
        end
    end, opts)
    
    -- Selection
    vim.keymap.set("n", "<CR>", apply_selected_theme, opts)
    vim.keymap.set("n", "<Space>", apply_selected_theme, opts)
    vim.keymap.set("n", "l", apply_selected_theme, opts)

    
    -- Close
    vim.keymap.set("n", "<Esc>", function()
        -- Revert to original theme if it exists
        if state.original_theme and state.original_theme ~= "" then
            apply.apply_theme(state.original_theme, { silent = true })
            vim.notify("🎨 Reverted to original theme: " .. state.original_theme, vim.log.levels.INFO)
        end
        close_window()
    end, opts)
    vim.keymap.set("n", "q", function()
        -- Revert to original theme if it exists
        if state.original_theme and state.original_theme ~= "" then
            apply.apply_theme(state.original_theme, { silent = true })
            vim.notify("🎨 Reverted to original theme: " .. state.original_theme, vim.log.levels.INFO)
        end
        close_window()
    end, opts)
    vim.keymap.set("n", "h", function()
        -- Revert to original theme if it exists
        if state.original_theme and state.original_theme ~= "" then
            apply.apply_theme(state.original_theme, { silent = true })
            vim.notify("🎨 Reverted to original theme: " .. state.original_theme, vim.log.levels.INFO)
        end
        close_window()
    end, opts)
    
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
    
    -- Store original theme - we'll use the first theme as the "original" for this session
    -- When user applies a theme with Enter, it becomes the new "original" theme
    state.original_theme = apply.current_theme or 0
    
    -- Reset state
    state.selected_index = library.find_theme_index(apply.current_theme)
    
    print(#state.themes, state.selected_index)
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
    
    -- Apply first theme for initial preview
    if #state.themes > 0 then
        local the_theme = state.themes[state.selected_index]
        if the_theme and the_theme ~= "" then
            apply.apply_theme(the_theme, { silent = true })
        end
    end
    
    -- Set autocommands for cleanup
    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = state.buffer_id,
        callback = function()
            -- Revert to original theme on buffer leave
            if state.original_theme and state.original_theme ~= "" then
                apply.apply_theme(state.original_theme, { silent = true })
            end
            close_window()
        end,
        once = true
    })
    
    vim.api.nvim_create_autocmd("WinLeave", {
        callback = function()
            if state.window_id and vim.api.nvim_win_is_valid(state.window_id) then
                -- Revert to original theme on window leave
                if state.original_theme and state.original_theme ~= "" then
                    apply.apply_theme(state.original_theme, { silent = true })
                end
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
