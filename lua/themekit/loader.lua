local M = {}

-- Helper to resolve color from palette or return as-is if it's already a hex value
local function resolve_color(color, palette)
    if not color then return nil end

    -- If it's already a hex color (starts with #), return as-is
    if string.match(color, '^#%x+$') then
        return color
    end

    -- Try to resolve from palette
    if palette and palette[color] then
        return palette[color]
    end

    -- Return as-is if not found in palette (fallback)
    return color
end

-- Helper to set highlight groups using traditional vim commands
local function set_hl(group, attrs, palette)
    local bg = attrs.bg and 'guibg=' .. resolve_color(attrs.bg, palette) or ''
    local fg = attrs.fg and 'guifg=' .. resolve_color(attrs.fg, palette) or ''
    local style = ''

    if attrs.modifiers then
        local mod_map = {
            bold = 'bold',
            italic = 'italic',
            underlined = 'underline',
            reversed = 'reverse',
            crossed_out = 'strikethrough',
            dim = 'undercurl',
        }
        for _, mod in ipairs(attrs.modifiers) do
            style = style .. (mod_map[mod] or '') .. ','
        end
    end

    if attrs.underline then
        style = style .. 'underline,'
        if attrs.underline.color then
            vim.cmd(string.format(
                'highlight %s guisp=%s gui=%s %s %s',
                group, resolve_color(attrs.underline.color, palette), style, fg, bg
            ))
            return
        end
    end

    if style ~= '' then style = 'gui=' .. style end
    local command = string.format('highlight %s %s %s %s', group, style, fg, bg)
    vim.cmd(command)
end

-- Buffer for cursor highlight groups to merge attributes
local cursor_highlight_buffer = {}

-- Modern API function specifically for cursor highlights - buffers instead of immediately applying
local function set_cursor_hl(group, attrs, palette)
    -- Initialize group buffer if it doesn't exist
    if not cursor_highlight_buffer[group] then
        cursor_highlight_buffer[group] = {}
    end

    local hl_attrs = cursor_highlight_buffer[group]

    -- Merge foreground and background colors (later values override earlier ones)
    if attrs.fg then
        hl_attrs.fg = resolve_color(attrs.fg, palette)
    end
    if attrs.bg then
        hl_attrs.bg = resolve_color(attrs.bg, palette)
    end

    -- Merge modifiers (accumulate all modifiers)
    -- NOTE: Skip 'reversed' for cursor highlights as it causes confusing behavior
    if attrs.modifiers then
        for _, mod in ipairs(attrs.modifiers) do
            if mod == 'bold' then
                hl_attrs.bold = true
            elseif mod == 'italic' then
                hl_attrs.italic = true
            elseif mod == 'underlined' then
                hl_attrs.underline = true
            elseif mod == 'reversed' then
                -- Skip reversed for cursor highlights - causes confusing color behavior
                -- In Helix, reversed makes cursor visible, but in Neovim guicursor
                -- we want bg color to be the actual cursor color
            elseif mod == 'crossed_out' then
                hl_attrs.strikethrough = true
            elseif mod == 'dim' then
                hl_attrs.undercurl = true
            end
        end
    end
end



local function rebuild_cursor()
    -- 1️⃣  snapshot current guicursor
    local current = vim.opt.guicursor:get() -- e.g. { "n-v-c:block", "i:ver25" }

    -- 2️⃣  map modes → new HL groups
    local hl_map = {
        n = "CursorNormal",  -- Normal mode
        i = "CursorInsert",  -- Insert mode
        v = "CursorVisual",  -- Visual mode
        c = "CursorCommand", -- Command mode
    }

    -- Parse existing shapes from your current guicursor configuration
    local existing_shapes = {} -- Store shapes per mode from your config

    -- 3️⃣  Parse existing guicursor to preserve shapes
    for _, entry in ipairs(current) do
        local modes, rest = entry:match("^([^:]+):(.+)$") -- "n-v-c", "block"
        if modes and rest then
            local shape = rest:match("^([^%-]+)") or rest -- Extract shape: "block", "ver25", etc.

            -- Store shape for each mode in the group (e.g. "n-v-c" becomes "n", "v", "c")
            for mode in modes:gmatch("[^%-]") do
                existing_shapes[mode] = shape
            end
        end
    end

    -- any mode we care about that wasn’t mentioned? default to block


    -- Build cursor entries with proper highlight groups
    local cursor_entries = {}

    -- Only add modes that have highlight groups in buffer, preserve existing shapes
    for mode, hl_group in pairs(hl_map) do
        if cursor_highlight_buffer[hl_group] then
            local shape = existing_shapes[mode] or "block" -- Use existing shape from your config or default to block
            local fallback = "l" .. hl_group               -- lCursorNormal, lCursorInsert, etc.
            table.insert(cursor_entries, string.format("%s:%s-%s/%s", mode, shape, hl_group, fallback))
        end
    end

    if #cursor_entries > 0 then
        local new_guicursor = table.concat(cursor_entries, ",")
        vim.opt.guicursor = new_guicursor
    end
end

-- Function to apply all buffered cursor highlights
local function apply_cursor_highlights()
    -- Ensure termguicolors is enabled for cursor colors in terminal
    vim.opt.termguicolors = true

    for group, hl_attrs in pairs(cursor_highlight_buffer) do
        vim.api.nvim_set_hl(0, group, hl_attrs)

        -- Also create the corresponding lCursor* fallback group
        local fallback_group = "l" .. group -- lCursorNormal, lCursorInsert, etc.
        vim.api.nvim_set_hl(0, fallback_group, hl_attrs)
    end

    -- Set up guicursor BEFORE clearing buffer
    rebuild_cursor()

    -- Clear buffer after applying
    cursor_highlight_buffer = {}
end

-- Theme key handlers - each function handles a specific theme key
local theme_handlers = {}

-- Basic syntax highlighting
theme_handlers['attribute'] = function(attrs, palette)
    set_hl('@attribute', attrs, palette)
end

theme_handlers['keyword'] = function(attrs, palette)
    set_hl('@keyword', attrs, palette)
    set_hl('Keyword', attrs, palette)
end

theme_handlers['keyword.directive'] = function(attrs, palette)
    set_hl('@preproc', attrs, palette)
    set_hl('PreProc', attrs, palette)
end

theme_handlers['namespace'] = function(attrs, palette)
    set_hl('@namespace', attrs, palette)
    set_hl('@module', attrs, palette)
end

theme_handlers['punctuation'] = function(attrs, palette)
    set_hl('@punctuation', attrs, palette)
end

theme_handlers['punctuation.delimiter'] = function(attrs, palette)
    set_hl('@punctuation.delimiter', attrs, palette)
end

theme_handlers['operator'] = function(attrs, palette)
    set_hl('@operator', attrs, palette)
    set_hl('Operator', attrs, palette)
end

theme_handlers['special'] = function(attrs, palette)
    set_hl('Special', attrs, palette)
    set_hl('@character.special', attrs, palette)
end

theme_handlers['variable.other.member'] = function(attrs, palette)
    set_hl('@variable.member', attrs, palette)
    set_hl('@property', attrs, palette)
end

theme_handlers['variable'] = function(attrs, palette)
    set_hl('@variable', attrs, palette)
    set_hl('Identifier', attrs, palette)
end

theme_handlers['variable.parameter'] = function(attrs, palette)
    set_hl('@variable.parameter', attrs, palette)
    set_hl('@parameter', attrs, palette)
end

theme_handlers['variable.builtin'] = function(attrs, palette)
    set_hl('@variable.builtin', attrs, palette)
end

theme_handlers['type'] = function(attrs, palette)
    set_hl('@type', attrs, palette)
    set_hl('Type', attrs, palette)
end

theme_handlers['type.builtin'] = function(attrs, palette)
    set_hl('@type.builtin', attrs, palette)
end

theme_handlers['constructor'] = function(attrs, palette)
    set_hl('@constructor', attrs, palette)
end

theme_handlers['function'] = function(attrs, palette)
    set_hl('@function', attrs, palette)
    set_hl('Function', attrs, palette)
end

theme_handlers['function.macro'] = function(attrs, palette)
    set_hl('@function.macro', attrs, palette)
    set_hl('Macro', attrs, palette)
end

theme_handlers['function.builtin'] = function(attrs, palette)
    set_hl('@function.builtin', attrs, palette)
end

theme_handlers['tag'] = function(attrs, palette)
    set_hl('@tag', attrs, palette)
    set_hl('Tag', attrs, palette)
end

theme_handlers['comment'] = function(attrs, palette)
    set_hl('@comment', attrs, palette)
    set_hl('Comment', attrs, palette)
end

theme_handlers['constant'] = function(attrs, palette)
    set_hl('@constant', attrs, palette)
    set_hl('Constant', attrs, palette)
end

theme_handlers['constant.builtin'] = function(attrs, palette)
    set_hl('@constant.builtin', attrs, palette)
end

theme_handlers['string'] = function(attrs, palette)
    set_hl('@string', attrs, palette)
    set_hl('String', attrs, palette)
end

theme_handlers['constant.numeric'] = function(attrs, palette)
    set_hl('@number', attrs, palette)
    set_hl('Number', attrs, palette)
end

theme_handlers['constant.character.escape'] = function(attrs, palette)
    set_hl('@string.escape', attrs, palette)
    set_hl('SpecialChar', attrs, palette)
end

theme_handlers['label'] = function(attrs, palette)
    set_hl('@label', attrs, palette)
    set_hl('Label', attrs, palette)
end

theme_handlers['tabstop'] = function(attrs, palette)
    set_hl('TabLineFill', attrs, palette)
end

-- Markup
theme_handlers['markup.heading'] = function(attrs, palette)
    set_hl('@markup.heading', attrs, palette)
    set_hl('Title', attrs, palette)
end

theme_handlers['markup.bold'] = function(attrs, palette)
    set_hl('@markup.strong', attrs, palette)
end

theme_handlers['markup.italic'] = function(attrs, palette)
    set_hl('@markup.italic', attrs, palette)
end

theme_handlers['markup.strikethrough'] = function(attrs, palette)
    set_hl('@markup.strikethrough', attrs, palette)
end

theme_handlers['markup.link.url'] = function(attrs, palette)
    set_hl('@markup.link.url', attrs, palette)
end

theme_handlers['markup.link.text'] = function(attrs, palette)
    set_hl('@markup.link.text', attrs, palette)
end

theme_handlers['markup.raw'] = function(attrs, palette)
    set_hl('@markup.raw', attrs, palette)
end

-- Diff
theme_handlers['diff.plus'] = function(attrs, palette)
    set_hl('GitSignsAdd', attrs, palette)
    set_hl('DiffAdd', attrs, palette)
end

theme_handlers['diff.minus'] = function(attrs, palette)
    set_hl('GitSignsDelete', attrs, palette)
    set_hl('DiffDelete', attrs, palette)
end

theme_handlers['diff.delta'] = function(attrs, palette)
    set_hl('GitSignsChange', attrs, palette)
    set_hl('DiffChange', attrs, palette)
end

-- UI Elements
theme_handlers['ui.background'] = function(attrs, palette)
    set_hl('Normal', attrs, palette)
    set_hl('NormalNC', attrs, palette)
    set_hl('EndOfBuffer', attrs, palette)
    set_hl('SignColumn', attrs, palette)
end

theme_handlers['ui.background.separator'] = function(attrs, palette)
    set_hl('WinSeparator', attrs, palette)
    set_hl('VertSplit', attrs, palette)
end

theme_handlers['ui.linenr'] = function(attrs, palette)
    set_hl('LineNr', attrs, palette)
end

theme_handlers['ui.linenr.selected'] = function(attrs, palette)
    set_hl('CursorLineNr', attrs, palette)
end

theme_handlers['ui.statusline'] = function(attrs, palette)
    set_hl('StatusLine', attrs, palette)
end

theme_handlers['ui.statusline.inactive'] = function(attrs, palette)
    set_hl('StatusLineNC', attrs, palette)
end

theme_handlers['ui.popup'] = function(attrs, palette)
    set_hl('Pmenu', attrs, palette)
    set_hl('NormalFloat', attrs, palette)
end

theme_handlers['ui.window'] = function(attrs, palette)
    set_hl('WinSeparator', attrs, palette)
end

theme_handlers['ui.help'] = function(attrs, palette)
    set_hl('HelpCommand', attrs, palette)
end

theme_handlers['ui.text'] = function(attrs, palette)
    set_hl('Normal', attrs, palette)
end

theme_handlers['ui.text.focus'] = function(attrs, palette)
    set_hl('PmenuSel', attrs, palette)
end

theme_handlers['ui.text.inactive'] = function(attrs, palette)
    set_hl('Comment', attrs, palette)
end

theme_handlers['ui.text.directory'] = function(attrs, palette)
    set_hl('Directory', attrs, palette)
end

theme_handlers['ui.virtual'] = function(attrs, palette)
    set_hl('NonText', attrs, palette)
end

theme_handlers['ui.virtual.ruler'] = function(attrs, palette)
    set_hl('ColorColumn', attrs, palette)
end

theme_handlers['ui.virtual.jump-label'] = function(attrs, palette)
    set_hl('Search', attrs, palette)
end

theme_handlers['ui.virtual.indent-guide'] = function(attrs, palette)
    set_hl('IndentBlanklineChar', attrs, palette)
    set_hl('IblIndent', attrs, palette)
end

theme_handlers['ui.selection'] = function(attrs, palette)
    set_hl('Visual', attrs, palette)
end

theme_handlers['ui.selection.primary'] = function(attrs, palette)
    set_hl('Visual', attrs, palette)
end

theme_handlers['ui.cursor'] = function(attrs, palette)
    set_cursor_hl('CursorNormal', attrs, palette)
    set_cursor_hl('CursorVisual', attrs, palette)
    set_cursor_hl('CursorInsert', attrs, palette)
    set_cursor_hl('CursorCommand', attrs, palette)
end

theme_handlers['ui.cursor.select'] = function(attrs, palette)
    set_cursor_hl('CursorVisual', attrs, palette)
end

theme_handlers['ui.cursor.insert'] = function(attrs, palette)
    -- Set custom highlight group for insert mode cursor using modern API
    set_cursor_hl('CursorInsert', attrs, palette)
end

theme_handlers['ui.cursor.normal'] = function(attrs, palette)
    set_cursor_hl('CursorNormal', attrs, palette)
end

theme_handlers['ui.cursor.primary.select'] = function(attrs, palette)
    set_cursor_hl('CursorNormal', attrs, palette)
end
theme_handlers['ui.cursor.primary.insert'] = function(attrs, palette) end

theme_handlers['ui.cursor.match'] = function(attrs, palette)
    set_hl('MatchParen', attrs, palette)
end


theme_handlers['ui.cursorline.primary'] = function(attrs, palette)
    set_hl('CursorLine', attrs, palette)
end

theme_handlers['ui.highlight'] = function(attrs, palette)
    set_hl('Search', attrs, palette)
end

theme_handlers['ui.highlight.frameline'] = function(attrs, palette)
    set_hl('debugPc', attrs, palette)
end

theme_handlers['ui.debug'] = function(attrs, palette)
    set_hl('Debug', attrs, palette)
end

theme_handlers['ui.debug.breakpoint'] = function(attrs, palette)
    set_hl('debugBreakpoint', attrs, palette)
end

theme_handlers['ui.menu'] = function(attrs, palette)
    set_hl('WildMenu', attrs, palette)
    set_hl('Pmenu', attrs, palette)
end

theme_handlers['ui.menu.selected'] = function(attrs, palette)
    set_hl('PmenuSel', attrs, palette)
end

theme_handlers['ui.menu.scroll'] = function(attrs, palette)
    set_hl('PmenuSbar', attrs, palette)
end

-- Diagnostics
theme_handlers['diagnostic.hint'] = function(attrs, palette)
    set_hl('DiagnosticHint', attrs, palette)
    set_hl('DiagnosticUnderlineHint', attrs, palette)
end

theme_handlers['diagnostic.info'] = function(attrs, palette)
    set_hl('DiagnosticInfo', attrs, palette)
    set_hl('DiagnosticUnderlineInfo', attrs, palette)
end

theme_handlers['diagnostic.warning'] = function(attrs, palette)
    set_hl('DiagnosticWarn', attrs, palette)
    set_hl('DiagnosticUnderlineWarn', attrs, palette)
end

theme_handlers['diagnostic.error'] = function(attrs, palette)
    set_hl('DiagnosticError', attrs, palette)
    set_hl('DiagnosticUnderlineError', attrs, palette)
end

theme_handlers['diagnostic.unnecessary'] = function(attrs, palette)
    set_hl('DiagnosticUnnecessary', attrs, palette)
end

theme_handlers['diagnostic.deprecated'] = function(attrs, palette)
    set_hl('DiagnosticDeprecated', attrs, palette)
end

-- Severity levels
theme_handlers['warning'] = function(attrs, palette)
    set_hl('WarningMsg', attrs, palette)
    set_hl('DiagnosticWarn', attrs, palette)
end

theme_handlers['error'] = function(attrs, palette)
    set_hl('ErrorMsg', attrs, palette)
    set_hl('DiagnosticError', attrs, palette)
end

theme_handlers['info'] = function(attrs, palette)
    set_hl('DiagnosticInfo', attrs, palette)
end

theme_handlers['hint'] = function(attrs, palette)
    set_hl('DiagnosticHint', attrs, palette)
end


-- Main function that applies the helix theme
function M.apply(in_theme)
    -- Clear existing highlights
    vim.cmd('highlight clear')
    if vim.fn.exists('syntax_on') then vim.cmd('syntax reset') end
    vim.o.background = 'dark'
    vim.g.colors_name = 'helix_theme'


    -- Extract palette for color resolution
    local palette = in_theme.palette or {}

    -- Process each theme key
    for theme_key, attrs in pairs(in_theme) do
        if theme_key ~= 'palette' then -- Skip palette for now
            local handler = theme_handlers[theme_key]
            if handler then
                -- Normalize attrs to table format
                if type(attrs) == 'string' then
                    attrs = { fg = attrs }
                end
                handler(attrs, palette)
            end
        end
    end

    -- Apply all buffered cursor highlights with merged attributes
    apply_cursor_highlights()

    -- Handle terminal colors from palette
    if in_theme.palette then
        local term_colors = {
            black = 0,
            red = 1,
            green = 2,
            yellow = 3,
            blue = 4,
            magenta = 5,
            cyan = 6,
            white = 7,
            light_black = 8,
            light_red = 9,
            light_green = 10,
            light_yellow = 11,
            light_blue = 12,
            light_magenta = 13,
            light_cyan = 14,
            light_white = 15
        }

        for name, color in pairs(in_theme.palette) do
            local idx = term_colors[name]
            if idx then
                vim.g['terminal_color_' .. idx] = color
            end
        end
    end

    -- Plugin-specific configuration
    local statusline_attrs = in_theme['ui.statusline']
    if statusline_attrs and pcall(require, 'lualine') then
        local resolved_fg = statusline_attrs.fg and resolve_color(statusline_attrs.fg, palette)
        local resolved_bg = statusline_attrs.bg and resolve_color(statusline_attrs.bg, palette)
        local ok_lualine, lualine = pcall(require, "lualine")
        if ok_lualine then
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

-- Function to get list of supported theme keys
function M.get_supported_theme_keys()
    local keys = {}
    for key, _ in pairs(theme_handlers) do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

-- Function to check if a theme key is supported
function M.is_theme_key_supported(key)
    return theme_handlers[key] ~= nil
end

-- Function to add a custom theme handler
-- Handler should accept (attrs, palette) parameters
function M.add_theme_handler(key, handler)
    theme_handlers[key] = handler
end

return M
