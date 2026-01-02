-- Picker renderer module
-- Pure functions for rendering UI (no side effects except final buffer update)

local M = {}

-- UI Configuration
M.config = {
    width = 60,
    height = 15,
    header_lines = 4,
    footer_lines = 3,
    border = "rounded",
    title = " 🎨 Theme Picker ",
    prompt = "Select a theme: ",
    cursor_indicator = "▊",
}

-- Calculate scroll offset to keep selection visible
-- Pure function: takes state, returns new offset
function M.calculate_scroll_offset(selected_index, current_offset, visible_lines, total_themes)
    local target_line = selected_index - current_offset

    -- Adjust scroll if selection is out of view
    if target_line < 1 then
        return selected_index - 1
    elseif target_line > visible_lines then
        return selected_index - visible_lines
    end

    -- Ensure we don't scroll past the end
    local max_scroll = math.max(0, total_themes - visible_lines)
    return math.min(current_offset, max_scroll)
end

-- Get footer text based on state (pure function)
function M.get_footer_text(search_active, has_filter)
    if search_active then
        return " j/k: Navigate  │  Enter: Exit search  │  Esc: Clear"
    elseif has_filter then
        return " j/k: Navigate  │  Enter: Apply  │  Esc: Show all  │  f/: Search"
    else
        return " j/k: Navigate  │  Enter: Apply  │  Esc/q: Cancel  │  f/: Search"
    end
end

-- Build lines and highlights (pure function)
-- Returns: { lines = {...}, highlights = {...} }
function M.build_content(params)
    local lines = {}
    local highlights = {}

    local display_themes = params.display_themes
    local selected_index = params.selected_index
    local scroll_offset = params.scroll_offset
    local visible_lines = params.visible_lines
    local search_mode = params.search_mode
    local search_query = params.search_query
    local all_themes_count = params.all_themes_count
    local match_highlights = params.match_highlights

    local total_themes = #display_themes

    -- Header: Title
    table.insert(lines, M.config.title)
    table.insert(highlights, { "ThemePickerTitle", 0, 0, -1 })

    -- Header: Separator
    table.insert(lines, string.rep("─", #M.config.title))
    table.insert(highlights, { "ThemePickerComment", 1, 0, -1 })

    -- Header: Prompt (differs in search mode)
    if search_mode then
        local prompt_text = string.format("Search: %s%s (%d matches)",
            search_query, M.config.cursor_indicator, total_themes)
        table.insert(lines, prompt_text)
    else
        local scroll_indicator = ""
        if total_themes > visible_lines then
            local current_page = math.floor(scroll_offset / visible_lines) + 1
            local total_pages = math.ceil(total_themes / visible_lines)
            scroll_indicator = string.format(" [%d/%d]", current_page, total_pages)
        end

        local has_filter = (total_themes ~= all_themes_count)
        local filter_info = has_filter and
            string.format(" (filtered: %d/%d)", total_themes, all_themes_count) or
            string.format(" (%d available)", all_themes_count)

        table.insert(lines, M.config.prompt .. filter_info .. scroll_indicator)
    end
    table.insert(highlights, { "ThemePickerPrompt", 2, 0, -1 })

    -- Header: Empty line
    table.insert(lines, "")
    table.insert(highlights, { "ThemePickerComment", 3, 0, -1 })

    -- Body: Theme list (visible portion only)
    if total_themes > 0 then
        local start_idx = scroll_offset + 1
        local end_idx = math.min(scroll_offset + visible_lines, total_themes)

        for i = start_idx, end_idx do
            local theme = display_themes[i]
            if theme and theme ~= "" then
                local prefix = i == selected_index and "> " or "  "
                local line = prefix .. theme
                local line_num = #lines
                table.insert(lines, line)

                -- Base highlight for the line
                if i == selected_index then
                    table.insert(highlights, { "ThemePickerSelected", line_num, 0, -1 })
                else
                    table.insert(highlights, { "ThemePickerNormal", line_num, 0, -1 })
                end

                -- Add match highlighting if in search results
                if match_highlights[theme] then
                    for _, pos in ipairs(match_highlights[theme]) do
                        local col = #prefix + pos - 1
                        table.insert(highlights, { "ThemePickerSearchMatch", line_num, col, col + 1 })
                    end
                end
            end
        end

        -- Fill remaining visible lines if needed
        while #lines < 4 + visible_lines do
            table.insert(lines, "")
            table.insert(highlights, { "ThemePickerNormal", #lines - 1, 0, -1 })
        end
    else
        local no_match_msg = search_query ~= "" and "  No themes match your search" or "  No themes available"
        table.insert(lines, no_match_msg)
        table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })
    end

    -- Footer: Empty line
    table.insert(lines, "")
    table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })

    -- Footer: Separator
    table.insert(lines, string.rep("─", M.config.width - 4))
    table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })

    -- Footer: Help text
    local has_filter = (total_themes ~= all_themes_count)
    local footer_text = M.get_footer_text(search_mode, has_filter)
    table.insert(lines, footer_text)
    table.insert(highlights, { "ThemePickerComment", #lines - 1, 0, -1 })

    return { lines = lines, highlights = highlights }
end

-- Apply rendering to buffer (only impure function)
function M.render_to_buffer(buffer_id, window_id, content)
    vim.api.nvim_buf_set_option(buffer_id, "modifiable", true)
    vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, content.lines)
    vim.api.nvim_buf_set_option(buffer_id, "modifiable", false)

    vim.api.nvim_buf_clear_namespace(buffer_id, -1, 0, -1)
    for _, hl in ipairs(content.highlights) do
        vim.api.nvim_buf_add_highlight(buffer_id, -1, hl[1], hl[2], hl[3], hl[4])
    end

    -- Move cursor out of the way
    vim.api.nvim_win_set_cursor(window_id, { 1, 0 })
end

-- Main render function (orchestrator)
function M.render()
    local state_mod = require("themekit.commands.picker.state")

    if not state_mod.ui_state.buffer_id or not vim.api.nvim_buf_is_valid(state_mod.ui_state.buffer_id) then
        return
    end

    local display_themes = state_mod.get_display_themes()

    -- Update scroll offset (pure calculation)
    state_mod.navigation_state.scroll_offset = M.calculate_scroll_offset(
        state_mod.navigation_state.selected_index,
        state_mod.navigation_state.scroll_offset,
        state_mod.navigation_state.visible_lines,
        #display_themes
    )

    -- Build content (pure function)
    local content = M.build_content({
        display_themes = display_themes,
        selected_index = state_mod.navigation_state.selected_index,
        scroll_offset = state_mod.navigation_state.scroll_offset,
        visible_lines = state_mod.navigation_state.visible_lines,
        search_mode = state_mod.search_state.active,
        search_query = state_mod.search_state.query,
        all_themes_count = #state_mod.ui_state.themes,
        match_highlights = state_mod.search_state.match_highlights,
    })

    -- Apply to buffer (only side effect)
    M.render_to_buffer(
        state_mod.ui_state.buffer_id,
        state_mod.ui_state.window_id,
        content
    )
end

return M
