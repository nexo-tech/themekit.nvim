-- Picker keymaps module
-- Data-driven keymap tables (no conditional logic!)

local M = {}

-- Helper: Navigate and preview theme
-- Executes a navigation action, re-renders, and previews the selected theme
local function navigate_and_preview(navigate_fn, state_mod, renderer)
    navigate_fn()
    renderer.render()
    -- Preview theme
    local theme = state_mod.get_selected_theme()
    if theme then
        local apply = require('themekit.commands.apply')
        apply.apply_theme(theme, { silent = true })
    end
end

-- Helper: Create keymap handler functions
local function create_handlers()
    local state_mod = require("themekit.commands.picker.state")
    local renderer = require("themekit.commands.picker.renderer")
    local search = require("themekit.commands.picker.search")
    local lifecycle = require("themekit.commands.picker.lifecycle")

    return {
        -- Navigation
        move_down = function()
            navigate_and_preview(function() state_mod.move_selection(1) end, state_mod, renderer)
        end,

        move_up = function()
            navigate_and_preview(function() state_mod.move_selection(-1) end, state_mod, renderer)
        end,

        jump_first = function()
            navigate_and_preview(function() state_mod.jump_to_first() end, state_mod, renderer)
        end,

        jump_last = function()
            navigate_and_preview(function() state_mod.jump_to_last() end, state_mod, renderer)
        end,

        -- Actions
        apply_theme = function()
            lifecycle.apply_and_close()
        end,

        close_and_revert = function()
            lifecycle.close(true)  -- Revert to original
        end,

        -- Search mode (re-apply keymaps after mode change)
        enter_search = function()
            state_mod.enter_search()
            M.setup(state_mod.ui_state.buffer_id)  -- Re-apply keymaps for search mode
            renderer.render()
        end,

        exit_search_keep_filter = function()
            state_mod.exit_search()
            M.setup(state_mod.ui_state.buffer_id)  -- Re-apply keymaps for normal mode
            renderer.render()
        end,

        -- Search editing
        search_backspace = function()
            search.handle_backspace()
        end,

        search_clear = function()
            search.handle_clear()
        end,

        -- Contextual Escape
        handle_escape = function()
            if state_mod.search_state.active or state_mod.search_state.filtered_themes then
                state_mod.clear_search()
                M.setup(state_mod.ui_state.buffer_id)  -- Re-apply keymaps for normal mode
                renderer.render()
            else
                lifecycle.close(true)  -- Revert to original
            end
        end,
    }
end

-- Normal mode keymaps (no search active)
M.normal_mode = {
    -- Navigation
    { 'n', 'j',      'move_down' },
    { 'n', 'k',      'move_up' },
    { 'n', '<Down>', 'move_down' },
    { 'n', '<Up>',   'move_up' },
    { 'n', '<C-n>',  'move_down' },
    { 'n', '<C-p>',  'move_up' },
    { 'n', 'gg',     'jump_first', { nowait = false } },
    { 'n', 'G',      'jump_last' },

    -- Actions
    { 'n', '<CR>',   'apply_theme' },
    { 'n', '<Space>', 'apply_theme' },
    { 'n', 'l',      'apply_theme' },

    -- Search entry
    { 'n', 'f',      'enter_search' },
    { 'n', '/',      'enter_search' },

    -- Close actions (context-aware via handler)
    { 'n', '<Esc>',  'handle_escape' },
    { 'n', 'q',      'close_and_revert' },
    { 'n', 'h',      'close_and_revert' },
}

-- Search mode keymaps (search active)
M.search_mode = {
    -- Navigation still works via arrows
    { 'n', '<Down>', 'move_down' },
    { 'n', '<Up>',   'move_up' },
    { 'n', '<C-n>',  'move_down' },
    { 'n', '<C-p>',  'move_up' },

    -- Actions
    { 'n', '<CR>',   'exit_search_keep_filter' },
    { 'n', '<Esc>',  'handle_escape' },

    -- Search editing
    { 'n', '<BS>',   'search_backspace' },
    { 'n', '<C-h>',  'search_backspace' },
    { 'n', '<C-u>',  'search_clear' },
}

-- Searchable characters (handled specially)
local searchable_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_."

-- Apply keymaps based on current mode
function M.setup(buffer_id)
    local state_mod = require("themekit.commands.picker.state")
    local search = require("themekit.commands.picker.search")
    local handlers = create_handlers()

    -- Choose keymap set based on mode
    local mode_maps = state_mod.search_state.active and M.search_mode or M.normal_mode

    -- Apply keymaps
    for _, mapping in ipairs(mode_maps) do
        local mode, key, action, opts = mapping[1], mapping[2], mapping[3], mapping[4]
        opts = opts or {}
        opts.buffer = buffer_id
        opts.silent = opts.silent ~= false
        opts.nowait = (opts.nowait ~= false)

        vim.keymap.set(mode, key, handlers[action], opts)
    end

    -- In search mode, map all searchable characters
    if state_mod.search_state.active then
        for char in searchable_chars:gmatch(".") do
            vim.keymap.set('n', char, function()
                search.handle_char(char)
            end, {
                buffer = buffer_id,
                silent = true,
                nowait = true,
            })
        end
    end
end

return M
