-- Picker fuzzy search module
-- Handles fuzzy matching and theme filtering

local M = {}

-- Fuzzy match scoring configuration
local scoring = {
    base_match = 10,
    consecutive_bonus = 5,
    word_boundary_bonus = 15,
}

-- Fuzzy match a string against a query
-- Returns: score (number), match_positions (array) or nil if no match
function M.fuzzy_match(str, query)
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
            score = score + scoring.base_match + consecutive * scoring.consecutive_bonus
        else
            consecutive = 0
            score = score + 1
        end

        -- Bonus for word boundary
        if found == 1 or str:sub(found-1, found-1):match('[^%w]') then
            score = score + scoring.word_boundary_bonus
        end

        table.insert(match_positions, found)
        str_idx = found + 1
    end

    return score, match_positions
end

-- Filter themes based on query
-- Updates search_state with filtered results
function M.filter_themes(query, state_module)
    local state = state_module.search_state
    local themes = state_module.ui_state.themes

    if query == "" then
        state.filtered_themes = nil
        state.match_highlights = {}
        state_module.navigation_state.selected_index = 1
        state_module.navigation_state.scroll_offset = 0
        return
    end

    local matches = {}
    state.match_highlights = {}

    for _, theme in ipairs(themes) do
        local score, positions = M.fuzzy_match(theme, query)
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
    state_module.navigation_state.selected_index = 1
    state_module.navigation_state.scroll_offset = 0
end

-- Handle character input in search mode
function M.handle_char(char)
    local state_mod = require("themekit.commands.picker.state")
    local renderer = require("themekit.commands.picker.renderer")

    state_mod.search_state.query = state_mod.search_state.query .. char
    M.filter_themes(state_mod.search_state.query, state_mod)
    renderer.render()
end

-- Handle backspace in search mode
function M.handle_backspace()
    local state_mod = require("themekit.commands.picker.state")
    local renderer = require("themekit.commands.picker.renderer")

    if #state_mod.search_state.query > 0 then
        state_mod.search_state.query = state_mod.search_state.query:sub(1, -2)
        M.filter_themes(state_mod.search_state.query, state_mod)
        renderer.render()
    end
end

-- Handle clear search (Ctrl-U)
function M.handle_clear()
    local state_mod = require("themekit.commands.picker.state")
    local renderer = require("themekit.commands.picker.renderer")

    state_mod.search_state.query = ""
    M.filter_themes("", state_mod)
    renderer.render()
end

return M
