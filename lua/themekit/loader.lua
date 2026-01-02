-- Color module provides parsing, blending, and resolution with palette support
local color = require("themekit.color")
-- Highlight module provides highlight building, modifiers, and cursor highlighting
local highlight = require("themekit.highlight")
-- Handlers module provides theme key handlers
local handlers = require("themekit.handlers")
-- Integrations module provides plugin integrations
local integrations = require("themekit.integrations")
-- Config module provides constants and settings
local config = require("themekit.config")

local M = {}

-- Setup Vim environment for theme application
local function setup_vim_environment(theme_name, theme)
    vim.opt.termguicolors = true
    vim.cmd('silent! highlight clear')
    if vim.fn.exists('syntax_on') then vim.cmd('silent! syntax reset') end
    vim.o.background = 'dark'
    vim.g.colors_name = theme_name or 'helix_theme'

    -- Auto-enable cursorline if theme defines selected line number highlight
    -- This provides Helix-style line number highlighting out of the box
    if theme and theme['ui.linenr.selected'] then
        local current_cursorline = vim.opt.cursorline:get()

        -- Enable cursorline if not already enabled
        if not current_cursorline then
            vim.opt.cursorline = true

            -- Set to 'number' only if cursorlineopt is empty/default
            -- This preserves any user customization of cursorlineopt
            local current_opt = vim.opt.cursorlineopt:get()
            if not current_opt or #current_opt == 0 then
                vim.opt.cursorlineopt = 'number'  -- Helix-style: highlight only line number
            end
        end
    end
end

-- Prepare palette with pre-resolved background for alpha blending
local function prepare_palette(theme)
    local palette = theme.palette or {}

    -- Pre-resolve background for alpha blending context
    local resolved_bg = color.resolve_background(theme, palette)
    if resolved_bg then
        palette._resolved_bg = resolved_bg
    end

    return palette
end

-- Get sorted theme keys by specificity (dot count)
-- Less specific keys first - implements Helix's "longest matching key" rule
local function get_sorted_theme_keys(theme)
    local sorted_keys = {}
    for key, _ in pairs(theme) do
        if key ~= 'palette' and key ~= 'inherits' then
            table.insert(sorted_keys, key)
        end
    end

    table.sort(sorted_keys, function(a, b)
        local dots_a = select(2, a:gsub("%.", ""))
        local dots_b = select(2, b:gsub("%.", ""))
        return dots_a < dots_b  -- Less specific first
    end)

    return sorted_keys
end

-- Apply fallback highlights for common elements
local function apply_fallbacks(theme, palette, theme_handlers)
    -- Operator/punctuation fallbacks from ui.text
    local ui_text_fg = theme['ui.text']
    if ui_text_fg then
        local default_fg = type(ui_text_fg) == 'table' and ui_text_fg.fg or ui_text_fg
        if not theme['operator'] then
            theme_handlers['operator']({ fg = default_fg }, palette)
        end
        if not theme['punctuation'] then
            theme_handlers['punctuation']({ fg = default_fg }, palette)
        end
    end

    -- Smart fallback for ui.linenr.selected (Helix compatibility)
    -- Auto-generate brighter version if not defined
    if theme['ui.linenr'] and not theme['ui.linenr.selected'] then
        local linenr_attrs = theme['ui.linenr']
        local fg = type(linenr_attrs) == 'table' and linenr_attrs.fg or linenr_attrs
        if fg then
            local resolved_fg = color.resolve(fg, palette)
            if resolved_fg then
                -- Make it 30% brighter by blending with white
                local brighter_fg = color.blend_colors(resolved_fg, '#ffffff', config.LINE_NUMBER_BRIGHTNESS_RATIO)
                theme_handlers['ui.linenr.selected']({
                    fg = brighter_fg,
                    modifiers = { 'bold' }
                }, palette)
            end
        end
    end
end

-- Apply terminal colors from palette
local function apply_terminal_colors(palette)
    if not palette then return end

    local term_colors = {
        black = 0, red = 1, green = 2, yellow = 3,
        blue = 4, magenta = 5, cyan = 6, white = 7,
        light_black = 8, light_red = 9, light_green = 10, light_yellow = 11,
        light_blue = 12, light_magenta = 13, light_cyan = 14, light_white = 15
    }

    for name, color_value in pairs(palette) do
        local idx = term_colors[name]
        if idx then
            vim.g['terminal_color_' .. idx] = color_value
        end
    end
end

-- Main apply function - orchestrates theme application
function M.apply(theme, theme_name)
    -- Clear caches
    color.clear_cache()
    highlight.clear_cursor()

    -- Setup Vim environment (pass theme for cursorline detection)
    setup_vim_environment(theme_name, theme)

    -- Prepare palette with background resolution
    local palette = prepare_palette(theme)

    -- Get theme keys sorted by specificity
    local sorted_keys = get_sorted_theme_keys(theme)

    -- Apply theme keys in order (more specific override less specific)
    local theme_handlers = handlers.get_handlers()
    for _, theme_key in ipairs(sorted_keys) do
        local handler = theme_handlers[theme_key]
        if handler then
            handler(theme[theme_key], palette)
        end
    end

    -- Apply fallback highlights
    apply_fallbacks(theme, palette, theme_handlers)

    -- Flush buffered cursor highlights
    highlight.flush_cursor()

    -- Apply terminal colors
    apply_terminal_colors(palette)

    -- Integrate with external plugins
    integrations.apply_lualine(theme, palette)
end

function M.get_supported_theme_keys()
    return handlers.get_supported_keys()
end

function M.is_theme_key_supported(key)
    return handlers.has_handler(key)
end

function M.add_theme_handler(key, handler)
    handlers.add_handler(key, handler)
end

return M
