-- Modifier and underline style processing

local M = {}

-- Underline style mapping (Helix -> Neovim)
M.underline_styles = {
    line = 'underline',
    curl = 'undercurl',
    dashed = 'underdashed',
    dotted = 'underdotted',
    double_line = 'underdouble',
}

-- Modifier mapping (Helix -> Neovim)
M.modifier_map = {
    bold = 'bold',
    italic = 'italic',
    underlined = 'underline',
    reversed = 'reverse',
    crossed_out = 'strikethrough',
    slow_blink = nil,  -- Neovim doesn't support blinking
    rapid_blink = nil,
    hidden = nil,
    dim = 'dim',
}

-- Process modifiers in a single pass
-- Returns: (style_string, has_dim)
-- style_string: comma-separated Neovim modifiers (e.g., "bold,italic")
-- has_dim: boolean indicating if dim modifier was present
function M.process(modifiers)
    if not modifiers then return nil, false end

    local style_parts = {}
    local has_dim = false

    for _, mod in ipairs(modifiers) do
        if mod == 'dim' then
            has_dim = true
        else
            local mapped = M.modifier_map[mod]
            if mapped then
                table.insert(style_parts, mapped)
            end
        end
    end

    local style = #style_parts > 0 and table.concat(style_parts, ',') or nil
    return style, has_dim
end

-- Get underline style from underline attributes
-- Returns: (style_string, sp_color)
-- style_string: Neovim underline style (e.g., "undercurl")
-- sp_color: underline color if specified, otherwise nil
function M.get_underline_style(underline_attrs)
    if not underline_attrs then return nil, nil end

    local style = M.underline_styles[underline_attrs.style] or 'underline'
    local color = underline_attrs.color or nil

    return style, color
end

return M
