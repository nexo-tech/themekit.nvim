-- Picker state management module
-- Centralizes all state with clear ownership boundaries

local M = {}

-- Separate state tables by concern
local ui_state = {
    window_id = nil,
    buffer_id = nil,
    is_open = false,
    themes = {},  -- Canonical theme list
}

local navigation_state = {
    selected_index = 1,
    scroll_offset = 0,
    visible_lines = 0,
}

local search_state = {
    active = false,
    query = "",
    filtered_themes = nil,
    match_highlights = {},
}

local session_state = {
    original_theme = nil,
    autocmd_group = nil,
}

-- Export state tables (read-only access)
M.ui_state = ui_state
M.navigation_state = navigation_state
M.search_state = search_state
M.session_state = session_state

-- Initialize state for new picker session
function M.init(params)
    ui_state.themes = params.themes or {}
    ui_state.is_open = false
    ui_state.window_id = nil
    ui_state.buffer_id = nil

    navigation_state.selected_index = params.selected_index or 1
    navigation_state.scroll_offset = 0
    navigation_state.visible_lines = 0

    search_state.active = false
    search_state.query = ""
    search_state.filtered_themes = nil
    search_state.match_highlights = {}

    session_state.original_theme = params.original_theme
    session_state.autocmd_group = nil
end

-- Reset all state (called on close)
function M.reset()
    ui_state.window_id = nil
    ui_state.buffer_id = nil
    ui_state.is_open = false
    ui_state.themes = {}

    navigation_state.selected_index = 1
    navigation_state.scroll_offset = 0
    navigation_state.visible_lines = 0

    search_state.active = false
    search_state.query = ""
    search_state.filtered_themes = nil
    search_state.match_highlights = {}

    session_state.original_theme = nil
    session_state.autocmd_group = nil
end

-- Get the list of themes to display (filtered or all)
-- Single source of truth for "which themes to show"
function M.get_display_themes()
    return search_state.filtered_themes or ui_state.themes
end

-- Get currently selected theme name
function M.get_selected_theme()
    local themes = M.get_display_themes()
    return themes[navigation_state.selected_index]
end

-- Set selection by theme name
function M.set_selection_by_name(theme_name)
    local themes = M.get_display_themes()
    for i, name in ipairs(themes) do
        if name == theme_name then
            navigation_state.selected_index = i
            return true
        end
    end
    return false
end

-- Move selection by delta (handles wrapping)
function M.move_selection(delta)
    local themes = M.get_display_themes()
    local count = #themes
    if count == 0 then return end

    navigation_state.selected_index = navigation_state.selected_index + delta

    -- Wrap around
    if navigation_state.selected_index > count then
        navigation_state.selected_index = 1
    elseif navigation_state.selected_index < 1 then
        navigation_state.selected_index = count
    end
end

-- Jump to first theme
function M.jump_to_first()
    navigation_state.selected_index = 1
    navigation_state.scroll_offset = 0
end

-- Jump to last theme
function M.jump_to_last()
    local themes = M.get_display_themes()
    navigation_state.selected_index = #themes
end

-- Enter search mode
function M.enter_search()
    search_state.active = true
end

-- Exit search mode (keeps filter)
function M.exit_search()
    search_state.active = false
end

-- Clear search (removes filter)
function M.clear_search()
    search_state.active = false
    search_state.query = ""
    search_state.filtered_themes = nil
    search_state.match_highlights = {}
    navigation_state.selected_index = 1
    navigation_state.scroll_offset = 0
end

return M
