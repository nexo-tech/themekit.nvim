-- Highlight command building and application

local color = require("themekit.color")
local modifiers = require("themekit.highlight.modifiers")

local M = {}

-- Helper: Resolve foreground and background colors from attributes
local function resolve_colors(attrs, palette)
    local resolved_bg = attrs.bg and color.resolve(attrs.bg, palette) or nil
    local resolved_fg = attrs.fg and color.resolve(attrs.fg, palette, resolved_bg) or nil
    return resolved_fg, resolved_bg
end

-- Helper: Apply dim modifier to foreground if present
local function apply_dim_if_needed(fg, has_dim, bg, palette)
    if not has_dim or not fg then return fg end
    local dim_bg = bg or color.get_background(palette)
    return color.apply_dim(fg, dim_bg)
end

-- Helper: Build style string including underline
local function build_style_string(base_style, underline_attrs)
    if not underline_attrs then
        return base_style or ''
    end

    local ul_style = modifiers.get_underline_style(underline_attrs)
    if base_style and base_style ~= '' then
        return base_style .. ',' .. ul_style
    else
        return ul_style
    end
end

-- Helper: Execute highlight command
local function execute_highlight(group, fg, bg, style, underline_attrs, palette, resolved_bg)
    -- Special case: underline with color requires guisp
    if underline_attrs then
        local _, ul_color = modifiers.get_underline_style(underline_attrs)
        if ul_color then
            local sp = color.resolve(ul_color, palette, resolved_bg)
            local fg_part = fg and 'guifg=' .. fg or ''
            local bg_part = bg and 'guibg=' .. bg or ''
            vim.cmd('silent! ' .. string.format(
                'highlight %s guisp=%s gui=%s %s %s',
                group, sp, style, fg_part, bg_part
            ))
            return
        end
    end

    -- Regular highlight command
    local parts = { 'highlight', group }
    if style ~= '' then table.insert(parts, 'gui=' .. style) end
    if fg then table.insert(parts, 'guifg=' .. fg) end
    if bg then table.insert(parts, 'guibg=' .. bg) end

    vim.cmd('silent! ' .. table.concat(parts, ' '))
end

-- Set highlight for a single group using vim.cmd
-- Uses vim.cmd instead of nvim_set_hl for compatibility (see CLAUDE.md)
-- group: highlight group name
-- attrs: theme attributes (fg, bg, modifiers, underline)
-- palette: color palette for resolution
function M.apply(group, attrs, palette)
    -- Stage 1: Resolve colors
    local resolved_fg, resolved_bg = resolve_colors(attrs, palette)

    -- Stage 2: Process modifiers
    local base_style, has_dim = modifiers.process(attrs.modifiers)

    -- Stage 3: Apply dim effect if needed
    resolved_fg = apply_dim_if_needed(resolved_fg, has_dim, resolved_bg, palette)

    -- Stage 4: Build final style string (including underline)
    local style = build_style_string(base_style, attrs.underline)

    -- Stage 5: Execute highlight command
    execute_highlight(group, resolved_fg, resolved_bg, style, attrs.underline, palette, resolved_bg)
end

-- Apply highlight to multiple groups at once
-- groups: array of highlight group names
-- attrs: theme attributes to apply to all groups
-- palette: color palette for resolution
function M.apply_groups(groups, attrs, palette)
    for _, group in ipairs(groups) do
        M.apply(group, attrs, palette)
    end
end

return M
