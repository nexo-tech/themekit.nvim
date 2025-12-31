local M = {}

-- Constants
local HEX_SHORT_MULTIPLIER = 17  -- Expands 4-bit to 8-bit color (0xF -> 0xFF)
local DIM_BLEND_RATIO = 0.6
local DEFAULT_BG = '#000000'

-- Color resolution cache (cleared on each apply)
local color_cache = {}

-- Format RGB values (0-255) as hex color string
local function format_hex(r, g, b)
    return string.format('#%02x%02x%02x', r, g, b)
end

-- Blend RGB components with ratio: result = c1 * ratio + c2 * (1 - ratio)
local function blend_rgb(r1, g1, b1, r2, g2, b2, ratio)
    return
        math.floor(r1 * ratio + r2 * (1 - ratio) + 0.5),
        math.floor(g1 * ratio + g2 * (1 - ratio) + 0.5),
        math.floor(b1 * ratio + b2 * (1 - ratio) + 0.5)
end

-- Parse hex color components into r, g, b, a values (0-255)
local function parse_hex_color(hex)
    if not hex or not hex:match('^#') then return nil end
    local r, g, b, a
    local len = #hex - 1
    if len == 6 then
        r = tonumber(hex:sub(2, 3), 16)
        g = tonumber(hex:sub(4, 5), 16)
        b = tonumber(hex:sub(6, 7), 16)
        a = 255
    elseif len == 8 then
        r = tonumber(hex:sub(2, 3), 16)
        g = tonumber(hex:sub(4, 5), 16)
        b = tonumber(hex:sub(6, 7), 16)
        a = tonumber(hex:sub(8, 9), 16)
    elseif len == 3 then
        r = tonumber(hex:sub(2, 2), 16) * HEX_SHORT_MULTIPLIER
        g = tonumber(hex:sub(3, 3), 16) * HEX_SHORT_MULTIPLIER
        b = tonumber(hex:sub(4, 4), 16) * HEX_SHORT_MULTIPLIER
        a = 255
    elseif len == 4 then
        r = tonumber(hex:sub(2, 2), 16) * HEX_SHORT_MULTIPLIER
        g = tonumber(hex:sub(3, 3), 16) * HEX_SHORT_MULTIPLIER
        b = tonumber(hex:sub(4, 4), 16) * HEX_SHORT_MULTIPLIER
        a = tonumber(hex:sub(5, 5), 16) * HEX_SHORT_MULTIPLIER
    else
        return nil
    end
    return r, g, b, a
end

-- Blend two colors: result = fg * ratio + bg * (1 - ratio)
local function blend_colors(fg_hex, bg_hex, ratio)
    local r1, g1, b1 = parse_hex_color(fg_hex)
    local r2, g2, b2 = parse_hex_color(bg_hex)
    if not r1 or not r2 then return fg_hex end

    local r, g, b = blend_rgb(r1, g1, b1, r2, g2, b2, ratio)
    return format_hex(r, g, b)
end

-- Blend RGBA color onto background, return solid hex color
local function blend_alpha(fg_hex, bg_hex)
    local r1, g1, b1, a = parse_hex_color(fg_hex)
    if not r1 then return fg_hex end
    if a == 255 then
        return format_hex(r1, g1, b1)
    end

    bg_hex = bg_hex or DEFAULT_BG
    local r2, g2, b2 = parse_hex_color(bg_hex)
    if not r2 then r2, g2, b2 = 0, 0, 0 end

    local alpha = a / 255
    local r, g, b = blend_rgb(r1, g1, b1, r2, g2, b2, alpha)
    return format_hex(r, g, b)
end

-- Fallback color mapping for common color names (Helix named colors)
local color_fallbacks = {
    ['default'] = nil,
    ['black'] = '#000000',
    ['red'] = '#ff0000',
    ['green'] = '#00ff00',
    ['yellow'] = '#ffff00',
    ['blue'] = '#0000ff',
    ['magenta'] = '#ff00ff',
    ['cyan'] = '#00ffff',
    ['gray'] = '#808080',
    ['grey'] = '#808080',
    ['white'] = '#ffffff',
    ['light-red'] = '#ff6b6b',
    ['light-green'] = '#90ee90',
    ['light-yellow'] = '#ffffe0',
    ['light-blue'] = '#add8e6',
    ['light-magenta'] = '#dda0dd',
    ['light-cyan'] = '#e0ffff',
    ['light-gray'] = '#d3d3d3',
    ['light-grey'] = '#d3d3d3',
    ['dark-gray'] = '#a9a9a9',
    ['dark-grey'] = '#a9a9a9',
}

-- Resolve color from palette with cycle detection and caching
local function resolve_color(color, palette, bg_color, visited)
    if not color then return nil end
    if type(color) ~= 'string' then return nil end

    -- Check cache first
    local cache_key = color
    if color_cache[cache_key] then return color_cache[cache_key] end

    -- Cycle detection
    visited = visited or {}
    if visited[color] then return nil end
    visited[color] = true

    local result

    -- Hex color
    if string.match(color, '^#%x+$') then
        local len = #color - 1
        if len == 8 or len == 4 then
            local bg = bg_color
            if not bg and palette then
                bg = palette._resolved_bg or palette.bg0 or palette.bg or palette.background
                if bg and not bg:match('^#') then
                    bg = palette[bg]
                end
            end
            result = blend_alpha(color, bg or DEFAULT_BG)
        else
            result = color
        end
    -- Palette reference
    elseif palette and palette[color] then
        result = resolve_color(palette[color], palette, bg_color, visited)
    -- Named color fallback
    elseif color_fallbacks[color] then
        result = color_fallbacks[color]
    else
        result = color
    end

    -- Cache the result
    if result then
        color_cache[cache_key] = result
    end

    return result
end

-- Underline style mapping (Helix -> Neovim)
local underline_styles = {
    line = 'underline',
    curl = 'undercurl',
    dashed = 'underdashed',
    dotted = 'underdotted',
    double_line = 'underdouble',
}

-- Modifier mapping (Helix -> Neovim)
local modifier_map = {
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

-- Process modifiers in a single pass, returns (style_string, has_dim)
local function process_modifiers(modifiers)
    if not modifiers then return nil, false end
    local style_parts = {}
    local has_dim = false
    for _, mod in ipairs(modifiers) do
        if mod == 'dim' then
            has_dim = true
        else
            local mapped = modifier_map[mod]
            if mapped then table.insert(style_parts, mapped) end
        end
    end
    local style = #style_parts > 0 and table.concat(style_parts, ',') or nil
    return style, has_dim
end

-- Set highlight using vim.cmd (more compatible)
local function set_hl(group, attrs, palette)
    -- Resolve colors
    local resolved_bg = attrs.bg and resolve_color(attrs.bg, palette) or nil
    local resolved_fg = attrs.fg and resolve_color(attrs.fg, palette, resolved_bg) or nil

    -- Process modifiers once
    local style, has_dim = process_modifiers(attrs.modifiers)

    -- Handle dim modifier by darkening foreground
    if has_dim and resolved_fg then
        local bg = resolved_bg or (palette and palette._resolved_bg) or DEFAULT_BG
        resolved_fg = blend_colors(resolved_fg, bg, DIM_BLEND_RATIO)
    end

    local bg = resolved_bg and 'guibg=' .. resolved_bg or ''
    local fg = resolved_fg and 'guifg=' .. resolved_fg or ''
    style = style or ''

    -- Handle underline with style
    if attrs.underline then
        local ul_style = underline_styles[attrs.underline.style] or 'underline'
        if style ~= '' then
            style = style .. ',' .. ul_style
        else
            style = ul_style
        end

        if attrs.underline.color then
            local sp = resolve_color(attrs.underline.color, palette, resolved_bg)
            vim.cmd('silent! ' .. string.format(
                'highlight %s guisp=%s gui=%s %s %s',
                group, sp, style, fg, bg
            ))
            return
        end
    end

    -- Build command
    local parts = { 'highlight', group }
    if style ~= '' then table.insert(parts, 'gui=' .. style) end
    if fg ~= '' then table.insert(parts, fg) end
    if bg ~= '' then table.insert(parts, bg) end

    vim.cmd('silent! ' .. table.concat(parts, ' '))
end

-- Helper to set multiple highlight groups at once
local function set_hl_groups(groups, attrs, palette)
    for _, group in ipairs(groups) do
        set_hl(group, attrs, palette)
    end
end

-- Buffer for cursor highlight groups
local cursor_highlight_buffer = {}

-- Buffer cursor highlights for merging
local function set_cursor_hl(group, attrs, palette)
    if not cursor_highlight_buffer[group] then
        cursor_highlight_buffer[group] = {}
    end

    local hl_attrs = cursor_highlight_buffer[group]
    local resolved_bg = attrs.bg and resolve_color(attrs.bg, palette) or nil
    local resolved_fg = attrs.fg and resolve_color(attrs.fg, palette, resolved_bg) or nil

    if resolved_fg then hl_attrs.fg = resolved_fg end
    if resolved_bg then hl_attrs.bg = resolved_bg end

    if attrs.modifiers then
        for _, mod in ipairs(attrs.modifiers) do
            if mod == 'bold' then hl_attrs.bold = true
            elseif mod == 'italic' then hl_attrs.italic = true
            elseif mod == 'underlined' then hl_attrs.underline = true
            elseif mod == 'crossed_out' then hl_attrs.strikethrough = true
            end
        end
    end
end

local function rebuild_cursor()
    local current = vim.opt.guicursor:get()
    local hl_map = {
        n = "CursorNormal",
        i = "CursorInsert",
        v = "CursorVisual",
        c = "CursorCommand",
    }

    local existing_shapes = {}
    for _, entry in ipairs(current) do
        local modes, rest = entry:match("^([^:]+):(.+)$")
        if modes and rest then
            local shape = rest:match("^([^%-]+)") or rest
            for mode in modes:gmatch("[^%-]") do
                existing_shapes[mode] = shape
            end
        end
    end

    local cursor_entries = {}
    for mode, hl_group in pairs(hl_map) do
        if cursor_highlight_buffer[hl_group] then
            local shape = existing_shapes[mode] or "block"
            local fallback = "l" .. hl_group
            table.insert(cursor_entries, string.format("%s:%s-%s/%s", mode, shape, hl_group, fallback))
        end
    end

    if #cursor_entries > 0 then
        vim.opt.guicursor = table.concat(cursor_entries, ",")
    end
end

local function apply_cursor_highlights()
    for group, hl_attrs in pairs(cursor_highlight_buffer) do
        vim.api.nvim_set_hl(0, group, hl_attrs)
        vim.api.nvim_set_hl(0, "l" .. group, hl_attrs)
    end

    rebuild_cursor()

    -- Clear buffer in-place (preserves table reference)
    for k in pairs(cursor_highlight_buffer) do
        cursor_highlight_buffer[k] = nil
    end
end

-- Data-driven handler mappings: theme_key -> {highlight_groups}
local handler_mappings = {
    -- Syntax: Keywords
    ['attribute'] = {'@attribute'},
    ['keyword'] = {'@keyword', 'Keyword'},
    ['keyword.directive'] = {'@preproc', 'PreProc'},
    ['keyword.function'] = {'@keyword.function'},
    ['keyword.storage'] = {'@keyword.storage', 'StorageClass'},
    ['keyword.storage.type'] = {'@keyword.storage.type', '@type.qualifier'},
    ['keyword.storage.modifier'] = {'@keyword.storage.modifier', '@storageclass'},
    ['keyword.control'] = {'@keyword.control', '@conditional', '@repeat'},
    ['keyword.control.conditional'] = {'@keyword.conditional', '@conditional', 'Conditional'},
    ['keyword.control.repeat'] = {'@keyword.repeat', 'Repeat'},
    ['keyword.control.import'] = {'@keyword.import', '@include', 'Include'},
    ['keyword.control.return'] = {'@keyword.return'},
    ['keyword.control.exception'] = {'@keyword.exception', 'Exception'},
    ['keyword.operator'] = {'@keyword.operator'},

    -- Syntax: Namespace/Punctuation/Operator
    ['namespace'] = {'@namespace', '@module'},
    ['punctuation'] = {'@punctuation'},
    ['punctuation.delimiter'] = {'@punctuation.delimiter'},
    ['punctuation.bracket'] = {'@punctuation.bracket', 'Delimiter'},
    ['punctuation.special'] = {'@punctuation.special'},
    ['operator'] = {'@operator', 'Operator'},
    ['special'] = {'Special', '@character.special'},

    -- Syntax: Variables
    ['variable'] = {'@variable', 'Identifier'},
    ['variable.builtin'] = {'@variable.builtin'},
    ['variable.parameter'] = {'@variable.parameter', '@parameter'},
    ['variable.other'] = {'@variable'},
    ['variable.other.member'] = {'@variable.member', '@property'},
    ['variable.other.member.private'] = {'@variable.member.private'},
    ['property'] = {'@property'},

    -- Syntax: Types
    ['type'] = {'@type', 'Type'},
    ['type.builtin'] = {'@type.builtin'},
    ['type.parameter'] = {'@type.parameter'},
    ['type.enum'] = {'@type.enum', '@lsp.type.enum'},
    ['type.enum.variant'] = {'@type.enum.variant', '@lsp.type.enumMember'},
    ['constructor'] = {'@constructor'},

    -- Syntax: Functions
    ['function'] = {'@function', 'Function'},
    ['function.builtin'] = {'@function.builtin'},
    ['function.method'] = {'@function.method', '@method'},
    ['function.method.private'] = {'@function.method.private'},
    ['function.macro'] = {'@function.macro', 'Macro'},
    ['function.special'] = {'@function.special'},

    -- Syntax: Tags/Labels
    ['tag'] = {'@tag', 'Tag'},
    ['tag.builtin'] = {'@tag.builtin'},
    ['label'] = {'@label', 'Label'},

    -- Syntax: Comments
    ['comment'] = {'@comment', 'Comment'},
    ['comment.line'] = {'@comment.line'},
    ['comment.line.documentation'] = {'@comment.documentation'},
    ['comment.block'] = {'@comment.block'},
    ['comment.block.documentation'] = {'@comment.block.documentation'},
    ['comment.unused'] = {'@comment.unused', 'DiagnosticUnnecessary'},

    -- Syntax: Constants
    ['constant'] = {'@constant', 'Constant'},
    ['constant.builtin'] = {'@constant.builtin'},
    ['constant.builtin.boolean'] = {'@boolean', 'Boolean'},
    ['constant.character'] = {'@character', 'Character'},
    ['constant.character.escape'] = {'@string.escape', 'SpecialChar'},
    ['constant.numeric'] = {'@number', 'Number'},
    ['constant.numeric.integer'] = {'@number.integer', 'Number'},
    ['constant.numeric.float'] = {'@number.float', 'Float'},

    -- Syntax: Strings
    ['string'] = {'@string', 'String'},
    ['string.regexp'] = {'@string.regexp', '@string.regex'},
    ['string.special'] = {'@string.special'},
    ['string.special.url'] = {'@string.special.url', '@text.uri'},
    ['string.special.path'] = {'@string.special.path'},
    ['string.special.symbol'] = {'@string.special.symbol', '@symbol'},

    -- Markup
    ['markup.heading'] = {'@markup.heading', 'Title'},
    ['markup.heading.marker'] = {'@markup.heading.marker'},
    ['markup.heading.1'] = {'@markup.heading.1', 'markdownH1', 'htmlH1'},
    ['markup.heading.2'] = {'@markup.heading.2', 'markdownH2', 'htmlH2'},
    ['markup.heading.3'] = {'@markup.heading.3', 'markdownH3', 'htmlH3'},
    ['markup.heading.4'] = {'@markup.heading.4', 'markdownH4', 'htmlH4'},
    ['markup.heading.5'] = {'@markup.heading.5', 'markdownH5', 'htmlH5'},
    ['markup.heading.6'] = {'@markup.heading.6', 'markdownH6', 'htmlH6'},
    ['markup.bold'] = {'@markup.strong'},
    ['markup.italic'] = {'@markup.italic'},
    ['markup.strikethrough'] = {'@markup.strikethrough'},
    ['markup.link'] = {'@markup.link'},
    ['markup.link.url'] = {'@markup.link.url'},
    ['markup.link.label'] = {'@markup.link.label'},
    ['markup.link.text'] = {'@markup.link.text'},
    ['markup.quote'] = {'@markup.quote', 'markdownBlockquote'},
    ['markup.raw'] = {'@markup.raw'},
    ['markup.raw.block'] = {'@markup.raw.block'},
    ['markup.raw.inline'] = {'@markup.raw.inline'},
    ['markup.list'] = {'@markup.list'},
    ['markup.list.numbered'] = {'@markup.list.numbered'},
    ['markup.list.unnumbered'] = {'@markup.list.unnumbered'},
    ['markup.list.checked'] = {'@markup.list.checked'},
    ['markup.list.unchecked'] = {'@markup.list.unchecked'},

    -- Diff
    ['diff.plus'] = {'GitSignsAdd', 'DiffAdd', '@diff.plus'},
    ['diff.minus'] = {'GitSignsDelete', 'DiffDelete', '@diff.minus'},
    ['diff.delta'] = {'GitSignsChange', 'DiffChange', '@diff.delta'},
    ['diff.delta.moved'] = {'DiffText'},
    ['diff.delta.conflict'] = {'DiffText'},
    ['diff.plus.gutter'] = {'GitSignsAddNr', 'GitSignsAddLn'},
    ['diff.minus.gutter'] = {'GitSignsDeleteNr', 'GitSignsDeleteLn'},
    ['diff.delta.gutter'] = {'GitSignsChangeNr', 'GitSignsChangeLn'},

    -- UI: Background/Gutter/Lines
    ['ui.background'] = {'Normal', 'NormalNC', 'EndOfBuffer', 'SignColumn'},
    ['ui.background.separator'] = {'WinSeparator', 'VertSplit'},
    ['ui.linenr'] = {'LineNr'},
    ['ui.linenr.selected'] = {'CursorLineNr'},
    ['ui.gutter'] = {'SignColumn', 'FoldColumn'},
    ['ui.gutter.selected'] = {'CursorLineSign'},

    -- UI: Statusline
    ['ui.statusline'] = {'StatusLine'},
    ['ui.statusline.inactive'] = {'StatusLineNC'},
    ['ui.statusline.normal'] = {'StatusLineNormal'},
    ['ui.statusline.insert'] = {'StatusLineInsert'},
    ['ui.statusline.select'] = {'StatusLineSelect'},
    ['ui.statusline.separator'] = {'StatusLineSeparator'},

    -- UI: Popup/Menu/Window
    ['ui.popup'] = {'Pmenu', 'NormalFloat'},
    ['ui.popup.info'] = {'FloatBorder', 'FloatTitle'},
    ['ui.window'] = {'WinSeparator'},
    ['ui.help'] = {'HelpCommand'},
    ['ui.text'] = {'Normal'},
    ['ui.text.focus'] = {'PmenuSel'},
    ['ui.text.inactive'] = {'Comment'},
    ['ui.text.info'] = {'MoreMsg'},
    ['ui.text.directory'] = {'Directory'},
    ['ui.menu'] = {'WildMenu', 'Pmenu'},
    ['ui.menu.selected'] = {'PmenuSel'},
    ['ui.menu.scroll'] = {'PmenuSbar'},

    -- UI: Virtual/Inlay
    ['ui.virtual'] = {'NonText'},
    ['ui.virtual.ruler'] = {'ColorColumn'},
    ['ui.virtual.jump-label'] = {'Search'},
    ['ui.virtual.indent-guide'] = {'IndentBlanklineChar', 'IblIndent'},
    ['ui.virtual.inlay-hint'] = {'LspInlayHint'},
    ['ui.virtual.inlay-hint.parameter'] = {'LspInlayHintParameter'},
    ['ui.virtual.inlay-hint.type'] = {'LspInlayHintType'},
    ['ui.virtual.whitespace'] = {'Whitespace'},
    ['ui.virtual.wrap'] = {'NonText'},

    -- UI: Selection/Highlight
    ['ui.selection'] = {'Visual'},
    ['ui.selection.primary'] = {'Visual'},
    ['ui.cursor.match'] = {'MatchParen'},
    ['ui.cursorline'] = {'CursorLine'},
    ['ui.cursorline.primary'] = {'CursorLine'},
    ['ui.cursorline.secondary'] = {'CursorLine'},
    ['ui.cursorcolumn'] = {'CursorColumn'},
    ['ui.cursorcolumn.primary'] = {'CursorColumn'},
    ['ui.cursorcolumn.secondary'] = {'CursorColumn'},
    ['ui.highlight'] = {'Search'},
    ['ui.highlight.frameline'] = {'debugPC'},

    -- UI: Debug
    ['ui.debug'] = {'Debug'},
    ['ui.debug.breakpoint'] = {'debugBreakpoint'},
    ['ui.debug.active'] = {'DapUIPlayPause', 'debugPC'},

    -- UI: Picker
    ['ui.picker.header'] = {'TelescopeTitle'},
    ['ui.picker.header.column'] = {'TelescopePreviewTitle', 'TelescopePromptTitle', 'TelescopeResultsTitle'},
    ['ui.picker.header.column.active'] = {'TelescopeSelection'},

    -- UI: Bufferline
    ['ui.bufferline'] = {'TabLine'},
    ['ui.bufferline.active'] = {'TabLineSel'},
    ['ui.bufferline.background'] = {'TabLineFill'},

    -- Diagnostics
    ['diagnostic'] = {'DiagnosticError', 'DiagnosticWarn', 'DiagnosticInfo', 'DiagnosticHint'},
    ['diagnostic.hint'] = {'DiagnosticHint', 'DiagnosticUnderlineHint'},
    ['diagnostic.info'] = {'DiagnosticInfo', 'DiagnosticUnderlineInfo'},
    ['diagnostic.warning'] = {'DiagnosticWarn', 'DiagnosticUnderlineWarn'},
    ['diagnostic.error'] = {'DiagnosticError', 'DiagnosticUnderlineError'},
    ['diagnostic.unnecessary'] = {'DiagnosticUnnecessary'},
    ['diagnostic.deprecated'] = {'DiagnosticDeprecated'},
    ['warning'] = {'WarningMsg', 'DiagnosticWarn'},
    ['error'] = {'ErrorMsg', 'DiagnosticError'},
    ['info'] = {'DiagnosticInfo'},
    ['hint'] = {'DiagnosticHint'},

    -- Misc
    ['tabstop'] = {'TabLineFill'},
}

-- Generate theme handlers from mappings
local theme_handlers = {}

for key, groups in pairs(handler_mappings) do
    theme_handlers[key] = function(attrs, palette)
        set_hl_groups(groups, attrs, palette)
    end
end

-- Cursor handlers use buffering - generate from mapping table
local cursor_mappings = {
    ['ui.cursor'] = {'CursorNormal', 'CursorVisual', 'CursorInsert', 'CursorCommand'},
    ['ui.cursor.normal'] = {'CursorNormal'},
    ['ui.cursor.insert'] = {'CursorInsert'},
    ['ui.cursor.select'] = {'CursorVisual'},
    ['ui.cursor.primary'] = {'CursorNormal'},
    ['ui.cursor.primary.normal'] = {'CursorNormal'},
    ['ui.cursor.primary.insert'] = {'CursorInsert'},
    ['ui.cursor.primary.select'] = {'CursorVisual'},
}

for key, groups in pairs(cursor_mappings) do
    theme_handlers[key] = function(attrs, palette)
        for _, group in ipairs(groups) do
            set_cursor_hl(group, attrs, palette)
        end
    end
end

-- Main apply function
function M.apply(in_theme)
    -- Clear caches
    color_cache = {}

    vim.opt.termguicolors = true
    vim.cmd('silent! highlight clear')
    if vim.fn.exists('syntax_on') then vim.cmd('silent! syntax reset') end
    vim.o.background = 'dark'
    vim.g.colors_name = 'helix_theme'

    local palette = in_theme.palette or {}

    -- Pre-resolve background for alpha blending
    local ui_bg = in_theme['ui.background']
    if ui_bg then
        local bg_color = type(ui_bg) == 'table' and ui_bg.bg or (type(ui_bg) == 'string' and ui_bg or nil)
        if bg_color then
            local resolved_bg = bg_color
            if not bg_color:match('^#') then
                resolved_bg = palette[bg_color]
            end
            if resolved_bg and resolved_bg:match('^#') then
                palette._resolved_bg = resolved_bg
            end
        end
    end

    -- Sort theme keys by specificity (dot count) - less specific first
    -- This implements Helix's "longest matching key" rule: more specific keys override
    local sorted_keys = {}
    for key, _ in pairs(in_theme) do
        if key ~= 'palette' and key ~= 'inherits' then
            table.insert(sorted_keys, key)
        end
    end
    table.sort(sorted_keys, function(a, b)
        local dots_a = select(2, a:gsub("%.", ""))
        local dots_b = select(2, b:gsub("%.", ""))
        return dots_a < dots_b  -- Less specific first
    end)

    -- Process theme keys in order (more specific keys override earlier ones)
    for _, theme_key in ipairs(sorted_keys) do
        local handler = theme_handlers[theme_key]
        if handler then
            local attrs = in_theme[theme_key]
            if type(attrs) == 'string' then
                attrs = { fg = attrs }
            end
            handler(attrs, palette)
        end
    end

    -- Fallbacks
    local ui_text_fg = in_theme['ui.text']
    if ui_text_fg then
        local default_fg = type(ui_text_fg) == 'table' and ui_text_fg.fg or ui_text_fg
        if not in_theme['operator'] then
            theme_handlers['operator']({ fg = default_fg }, palette)
        end
        if not in_theme['punctuation'] then
            theme_handlers['punctuation']({ fg = default_fg }, palette)
        end
    end

    apply_cursor_highlights()

    -- Terminal colors
    if in_theme.palette then
        local term_colors = {
            black = 0, red = 1, green = 2, yellow = 3,
            blue = 4, magenta = 5, cyan = 6, white = 7,
            light_black = 8, light_red = 9, light_green = 10, light_yellow = 11,
            light_blue = 12, light_magenta = 13, light_cyan = 14, light_white = 15
        }
        for name, color in pairs(in_theme.palette) do
            local idx = term_colors[name]
            if idx then
                vim.g['terminal_color_' .. idx] = color
            end
        end
    end

    -- Lualine integration
    local statusline_attrs = in_theme['ui.statusline']
    if statusline_attrs then
        local ok_lualine, lualine = pcall(require, "lualine")
        if ok_lualine then
            local resolved_fg = statusline_attrs.fg and resolve_color(statusline_attrs.fg, palette)
            local resolved_bg = statusline_attrs.bg and resolve_color(statusline_attrs.bg, palette)
            lualine.setup({
                options = {
                    theme = {
                        normal = {
                            a = { fg = resolved_fg, bg = resolved_bg },
                            b = { fg = resolved_fg, bg = resolved_bg },
                            c = { fg = resolved_fg, bg = resolved_bg }
                        }
                    }
                }
            })
        end
    end
end

function M.get_supported_theme_keys()
    local keys = {}
    for key, _ in pairs(theme_handlers) do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

function M.is_theme_key_supported(key)
    return theme_handlers[key] ~= nil
end

function M.add_theme_handler(key, handler)
    theme_handlers[key] = handler
end

return M
