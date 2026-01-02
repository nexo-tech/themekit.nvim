-- Cursor highlight buffering and application

local color = require("themekit.color")

local M = {}

-- Buffer for cursor highlight groups
-- Cursor highlights are buffered and merged before application
-- This allows multiple theme keys to contribute to the same cursor mode
local cursor_highlight_buffer = {}

-- Buffer cursor highlight attributes for later merging
-- group: cursor highlight group name (e.g., "CursorNormal")
-- attrs: theme attributes (fg, bg, modifiers)
-- palette: color palette for resolution
function M.buffer(group, attrs, palette)
    if not cursor_highlight_buffer[group] then
        cursor_highlight_buffer[group] = {}
    end

    local hl_attrs = cursor_highlight_buffer[group]
    local resolved_bg = attrs.bg and color.resolve(attrs.bg, palette) or nil
    local resolved_fg = attrs.fg and color.resolve(attrs.fg, palette, resolved_bg) or nil

    if resolved_fg then hl_attrs.fg = resolved_fg end
    if resolved_bg then hl_attrs.bg = resolved_bg end

    -- Merge modifiers (only specific ones supported for cursor)
    if attrs.modifiers then
        for _, mod in ipairs(attrs.modifiers) do
            if mod == 'bold' then
                hl_attrs.bold = true
            elseif mod == 'italic' then
                hl_attrs.italic = true
            elseif mod == 'underlined' then
                hl_attrs.underline = true
            elseif mod == 'crossed_out' then
                hl_attrs.strikethrough = true
            end
        end
    end
end

-- Helper: Parse existing guicursor into mode → shape mapping
local function parse_existing_shapes()
    local current = vim.opt.guicursor:get()

    -- Validate return type
    if not current or type(current) ~= 'table' then
        return {}
    end

    local shapes = {}

    for _, entry in ipairs(current) do
        -- Validate entry is a string
        if type(entry) ~= 'string' then
            goto continue
        end

        -- Parse cursor entry format: "modes:shape-hlgroup/fallback"
        local modes, rest = entry:match("^([^:]+):(.+)$")
        if not modes or not rest then
            goto continue
        end

        -- Extract shape (part before hyphen or full rest if no hyphen)
        local shape = rest:match("^([^%-]+)") or rest

        -- Parse individual modes and assign shape
        if type(modes) == 'string' then
            for mode in modes:gmatch("[^%-]") do
                shapes[mode] = shape
            end
        end

        ::continue::
    end

    return shapes
end

-- Helper: Build single guicursor entry string
local function build_cursor_entry(mode, hl_group, shape)
    local fallback = "l" .. hl_group
    return string.format("%s:%s-%s/%s", mode, shape, hl_group, fallback)
end

-- Helper: Serialize buffered cursor highlights into guicursor entries
local function serialize_cursor_entries(existing_shapes)
    local hl_map = {
        n = "CursorNormal",
        i = "CursorInsert",
        v = "CursorVisual",
        c = "CursorCommand",
    }

    local entries = {}
    for mode, hl_group in pairs(hl_map) do
        if cursor_highlight_buffer[hl_group] then
            local shape = existing_shapes[mode] or "block"
            table.insert(entries, build_cursor_entry(mode, hl_group, shape))
        end
    end

    return entries
end

-- Rebuild guicursor option from existing cursor shapes
-- Preserves cursor shapes (block/beam/underline) while updating highlight groups
local function rebuild_cursor()
    local existing_shapes = parse_existing_shapes()
    local cursor_entries = serialize_cursor_entries(existing_shapes)

    if #cursor_entries > 0 then
        vim.opt.guicursor = table.concat(cursor_entries, ",")
    end
end

-- Flush buffered cursor highlights
-- Applies all buffered cursor highlights using nvim_set_hl and rebuilds guicursor
function M.flush()
    -- Apply highlights for each buffered cursor group
    for group, hl_attrs in pairs(cursor_highlight_buffer) do
        vim.api.nvim_set_hl(0, group, hl_attrs)
        vim.api.nvim_set_hl(0, "l" .. group, hl_attrs)  -- lCursor* variants
    end

    rebuild_cursor()

    -- Clear buffer (create new table)
    cursor_highlight_buffer = {}
end

-- Clear cursor highlight buffer
-- Called at the start of theme application
function M.clear()
    cursor_highlight_buffer = {}
end

return M
