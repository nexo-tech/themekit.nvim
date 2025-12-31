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
    is_closing = false,            -- guard against double close
    preview_mode = false,
    original_theme = nil,
    scroll_offset = 0,
    visible_lines = 0,
    -- Search state
    search_mode = false,           -- true when actively typing search
    search_query = "",             -- current search string
    filtered_themes = nil,         -- filtered theme list (nil = show all)
    selected_theme_name = nil,     -- track theme name (not just index)
    match_highlights = {},         -- positions of matched characters for highlighting
}

-- Fuzzy matching functions
local function fuzzy_match(str, query)
    if query == "" then return 1000, {} end

    str = str:lower()
    query = query:lower()

    local str_idx = 1
    local match_positions = {}
    local score = 0
    local consecutive = 0

    for i = 1, #query do
        local char = query:sub(i, i)
        local found = str:find(char, str_idx, true)

        if not found then
            return nil  -- No match
        end

        -- Score based on position
        if found == str_idx then
            consecutive = consecutive + 1
            score = score + 10 + consecutive * 5
        else
            consecutive = 0
            score = score + 1
        end

        -- Bonus for word boundary
        if found == 1 or str:sub(found-1, found-1):match('[^%w]') then
            score = score + 15
        end

        table.insert(match_positions, found)
        str_idx = found + 1
    end

    return score, match_positions
end

local function filter_themes(query)
    if query == "" then
        state.filtered_themes = nil
        state.match_highlights = {}
        return
    end

    local matches = {}
    state.match_highlights = {}

    for _, theme in ipairs(state.themes) do
        local score, positions = fuzzy_match(theme, query)
        if score then
            table.insert(matches, {
                name = theme,
                score = score,
                positions = positions
            })
        end
    end

    -- Sort by score (highest first)
    table.sort(matches, function(a, b) return a.score > b.score end)

    -- Extract theme names and store highlights
    state.filtered_themes = {}
    for _, match in ipairs(matches) do
        table.insert(state.filtered_themes, match.name)
        state.match_highlights[match.name] = match.positions
    end

    -- Reset selection to first match
    state.selected_index = 1
    state.scroll_offset = 0
end

-- Forward declare render_content for search functions
local render_content

-- Search mode functions
local function enter_search_mode()
    state.search_mode = true
    state.search_query = ""
    -- Store current theme name before filtering
    local current_list = state.filtered_themes or state.themes
    state.selected_theme_name = current_list[state.selected_index]
    render_content()
end

local function exit_search_mode_keep_filter()
    state.search_mode = false
    render_content()
end

local function clear_search()
    state.search_mode = false
    state.search_query = ""
    local old_selected = state.selected_theme_name
    state.filtered_themes = nil
    state.match_highlights = {}

    -- Restore selection to same theme name if possible
    if old_selected then
        for i, theme in ipairs(state.themes) do
            if theme == old_selected then
                state.selected_index = i
                break
            end
        end
    end

    render_content()
end

local function handle_search_char(char)
    state.search_query = state.search_query .. char
    filter_themes(state.search_query)
    render_content()
end

local function handle_search_backspace()
    if #state.search_query > 0 then
        state.search_query = state.search_query:sub(1, -2)
        filter_themes(state.search_query)
        render_content()
    end
end

local function handle_search_clear()
    state.search_query = ""
    filter_themes("")
    render_content()
end

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
        ["ThemePickerComment"] = { link = "Comment" },
        ["ThemePickerSearchMatch"] = { fg = "#ffd700", bold = true },  -- Gold for matched characters
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
    -- Guard against double close
    if state.is_closing then return end
    state.is_closing = true

    if state.window_id and vim.api.nvim_win_is_valid(state.window_id) then
        vim.api.nvim_win_close(state.window_id, true)
    end
    if state.buffer_id and vim.api.nvim_buf_is_valid(state.buffer_id) then
        vim.api.nvim_buf_delete(state.buffer_id, { force = true })
    end
    state.window_id = nil
    state.buffer_id = nil
    state.is_open = false
    state.is_closing = false
    state.selected_index = 1
    state.scroll_offset = 0
    state.visible_lines = 0
    state.original_theme = nil
    -- Clear search state
    state.search_mode = false
    state.search_query = ""
    state.filtered_themes = nil
    state.selected_theme_name = nil
    state.match_highlights = {}
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

render_content = function()
    if not state.buffer_id or not vim.api.nvim_buf_is_valid(state.buffer_id) then
        return
    end

    update_scroll_offset()

    local lines = {}
    local highlights = {}

    -- Determine which list to display
    local display_themes = state.filtered_themes or state.themes
    local total_themes = #display_themes

    -- Add title
    table.insert(lines, config.title)
    table.insert(highlights, { "ThemePickerTitle", 0, 0, -1 })

    -- Add separator
    table.insert(lines, string.rep("─", #config.title))
    table.insert(highlights, { "ThemePickerComment", 1, 0, -1 })

    -- Add prompt - different for search mode
    if state.search_mode then
        local cursor_indicator = "▊"
        local prompt_text = string.format("Search: %s%s (%d matches)",
            state.search_query, cursor_indicator, total_themes)
        table.insert(lines, prompt_text)
    else
        local scroll_indicator = ""
        if total_themes > state.visible_lines then
            local current_page = math.floor(state.scroll_offset / state.visible_lines) + 1
            local total_pages = math.ceil(total_themes / state.visible_lines)
            scroll_indicator = string.format(" [%d/%d]", current_page, total_pages)
        end

        local filter_info = state.filtered_themes and
            string.format(" (filtered: %d/%d)", #state.filtered_themes, #state.themes) or
            string.format(" (%d available)", #state.themes)

        table.insert(lines, config.prompt .. filter_info .. scroll_indicator)
    end
    table.insert(highlights, { "ThemePickerPrompt", 2, 0, -1 })

    -- Add separator
    table.insert(lines, "")
    table.insert(highlights, { "ThemePickerComment", 3, 0, -1 })

    -- Add themes list (only visible portion)
    if total_themes > 0 then
        local start_idx = state.scroll_offset + 1
        local end_idx = math.min(state.scroll_offset + state.visible_lines, total_themes)

        for i = start_idx, end_idx do
            local theme = display_themes[i]
            if theme and theme ~= "" then
                local prefix = "  "
                if i == state.selected_index then
                    prefix = "> "
                end
                local line = prefix .. theme
                local line_num = #lines
                table.insert(lines, line)

                -- Base highlight for the line
                if i == state.selected_index then
                    table.insert(highlights, { "ThemePickerSelected", line_num, 0, -1 })
                else
                    table.insert(highlights, { "ThemePickerNormal", line_num, 0, -1 })
                end

                -- Add match highlighting if in search results
                if state.match_highlights[theme] then
                    for _, pos in ipairs(state.match_highlights[theme]) do
                        local col = #prefix + pos - 1
                        table.insert(highlights, { "ThemePickerSearchMatch", line_num, col, col + 1 })
                    end
                end
            end
        end

        -- Fill remaining visible lines if needed
        while #lines < 4 + state.visible_lines do
            table.insert(lines, "")
            table.insert(highlights, { "ThemePickerNormal", #lines - 1, 0, -1 })
        end
    else
        local no_match_msg = state.search_query ~= "" and "  No themes match your search" or "  No themes available"
        table.insert(lines, no_match_msg)
        table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })
    end

    -- Add footer
    table.insert(lines, "")
    table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })
    table.insert(lines, "─────────────────────────────────────────────────────────")
    table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })

    -- Dynamic footer text based on mode
    local footer_text
    if state.search_mode then
        footer_text = " j/k: Navigate  │  Enter: Exit search  │  Esc: Clear"
    elseif state.filtered_themes then
        footer_text = " j/k: Navigate  │  Enter: Apply  │  Esc: Show all  │  f/: Search"
    else
        footer_text = " j/k: Navigate  │  Enter: Apply  │  Esc/q: Cancel  │  f/: Search"
    end
    table.insert(lines, footer_text)
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
    local display_themes = state.filtered_themes or state.themes
    if #display_themes == 0 then
        return
    end

    local new_index = state.selected_index + direction

    if new_index >= 1 and new_index <= #display_themes then
        state.selected_index = new_index
        -- Track theme name for selection persistence
        state.selected_theme_name = display_themes[new_index]
        render_content()

        -- Apply theme instantly for preview
        local selected_theme = display_themes[state.selected_index]
        if selected_theme and selected_theme ~= "" then
            apply.apply_theme(selected_theme, { silent = true })
        end
    end
end

local function apply_selected_theme()
    local display_themes = state.filtered_themes or state.themes
    if #display_themes == 0 then
        vim.notify("No themes available", vim.log.levels.WARN)
        return
    end

    if state.selected_index >= 1 and state.selected_index <= #display_themes then
        local selected_theme = display_themes[state.selected_index]
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

    -- Helper for close and revert
    local function close_and_revert()
        if state.original_theme and state.original_theme ~= "" then
            apply.apply_theme(state.original_theme, { silent = true })
            vim.notify("🎨 Reverted to original theme: " .. state.original_theme, vim.log.levels.INFO)
        end
        close_window()
    end

    -- Helper for jump to first/last
    local function jump_to_first()
        local display_themes = state.filtered_themes or state.themes
        state.selected_index = 1
        state.selected_theme_name = display_themes[1]
        render_content()
        if display_themes[1] and display_themes[1] ~= "" then
            apply.apply_theme(display_themes[1], { silent = true })
        end
    end

    local function jump_to_last()
        local display_themes = state.filtered_themes or state.themes
        state.selected_index = #display_themes
        state.selected_theme_name = display_themes[#display_themes]
        render_content()
        if display_themes[#display_themes] and display_themes[#display_themes] ~= "" then
            apply.apply_theme(display_themes[#display_themes], { silent = true })
        end
    end

    -- Navigation (j/k only work when NOT in search mode, arrows always work)
    vim.keymap.set("n", "j", function()
        if state.search_mode then
            handle_search_char("j")
        else
            move_selection(1)
        end
    end, opts)
    vim.keymap.set("n", "k", function()
        if state.search_mode then
            handle_search_char("k")
        else
            move_selection(-1)
        end
    end, opts)
    vim.keymap.set("n", "<Down>", function() move_selection(1) end, opts)
    vim.keymap.set("n", "<Up>", function() move_selection(-1) end, opts)
    vim.keymap.set("n", "<C-n>", function() move_selection(1) end, opts)
    vim.keymap.set("n", "<C-p>", function() move_selection(-1) end, opts)

    -- gg mapping for jump to first (only in normal mode)
    local opts_no_nowait = { buffer = state.buffer_id, silent = true, nowait = false }
    vim.keymap.set("n", "gg", function()
        if not state.search_mode then
            jump_to_first()
        end
    end, opts_no_nowait)
    vim.keymap.set("n", "G", function()
        if state.search_mode then
            handle_search_char("G")
        else
            jump_to_last()
        end
    end, opts)

    -- Mode-specific Enter behavior
    vim.keymap.set("n", "<CR>", function()
        if state.search_mode then
            exit_search_mode_keep_filter()
        else
            apply_selected_theme()
        end
    end, opts)

    -- Selection keys (Space always works, l is conditional)
    vim.keymap.set("n", "<Space>", apply_selected_theme, opts)
    vim.keymap.set("n", "l", function()
        if state.search_mode then
            handle_search_char("l")
        else
            apply_selected_theme()
        end
    end, opts)

    -- Mode-specific Escape behavior
    vim.keymap.set("n", "<Esc>", function()
        if state.search_mode or state.filtered_themes then
            clear_search()
        else
            close_and_revert()
        end
    end, opts)

    vim.keymap.set("n", "q", function()
        if state.search_mode then
            handle_search_char("q")
        else
            close_and_revert()
        end
    end, opts)
    vim.keymap.set("n", "h", function()
        if state.search_mode then
            handle_search_char("h")
        else
            close_and_revert()
        end
    end, opts)

    -- Search mode entry
    vim.keymap.set("n", "f", function()
        if state.search_mode then
            handle_search_char("f")
        else
            enter_search_mode()
        end
    end, opts)
    vim.keymap.set("n", "/", enter_search_mode, opts)

    -- Character input handling for remaining characters
    -- j,k,g,h,l,q,f,G are handled with conditional logic above
    local chars = "abcdeimnoprstuvwxyzABCDEFHIJKLMNOPQRSTUVWXYZ0123456789-_."
    for i = 1, #chars do
        local char = chars:sub(i, i)
        vim.keymap.set("n", char, function()
            if state.search_mode then
                handle_search_char(char)
            end
        end, opts)
    end

    -- Add single 'g' for search mode (without nowait to not break 'gg')
    vim.keymap.set("n", "g", function()
        if state.search_mode then
            handle_search_char("g")
        end
    end, opts_no_nowait)

    -- Backspace in search mode
    vim.keymap.set("n", "<BS>", function()
        if state.search_mode then
            handle_search_backspace()
        end
    end, opts)

    vim.keymap.set("n", "<C-h>", function()
        if state.search_mode then
            handle_search_backspace()
        end
    end, opts)

    -- Clear query in search mode
    vim.keymap.set("n", "<C-u>", function()
        if state.search_mode then
            handle_search_clear()
        end
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
    
    -- Reset state - default to 1 if current theme not found
    state.selected_index = library.find_theme_index(apply.current_theme) or 1

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
