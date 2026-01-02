-- Handler generation from mappings
-- Unified factory for creating theme key handlers

local highlight = require("themekit.highlight")
local mappings = require("themekit.handlers.mappings")

local M = {}

-- Generated handlers cache
local theme_handlers = nil

-- Helper: Ensure theme attributes are in table format
-- Converts: string → {fg = string}
-- Preserves: table → table (unchanged)
local function ensure_attrs_table(attrs)
    if type(attrs) == 'string' then
        return { fg = attrs }
    end
    return attrs
end

-- Generate all theme key handlers from mappings
-- Returns: table of handlers (theme_key -> function(attrs, palette))
function M.generate()
    if theme_handlers then
        return theme_handlers
    end

    theme_handlers = {}

    -- Generate regular highlight handlers
    for key, groups in pairs(mappings.regular) do
        theme_handlers[key] = function(attrs, palette)
            local attrs_table = ensure_attrs_table(attrs)
            highlight.apply_groups(groups, attrs_table, palette)
        end
    end

    -- Generate cursor highlight handlers (use buffering)
    for key, groups in pairs(mappings.cursor) do
        theme_handlers[key] = function(attrs, palette)
            local attrs_table = ensure_attrs_table(attrs)
            for _, group in ipairs(groups) do
                highlight.buffer_cursor(group, attrs_table, palette)
            end
        end
    end

    return theme_handlers
end

-- Get generated handlers (lazy generation)
function M.get_handlers()
    return M.generate()
end

-- Add a custom handler for a theme key
-- key: theme key string (e.g., "custom.highlight")
-- handler: function(attrs, palette) that applies the highlight
function M.add_handler(key, handler)
    local handlers = M.get_handlers()
    handlers[key] = handler
end

-- Check if a theme key has a handler
-- key: theme key string
-- Returns: boolean
function M.has_handler(key)
    local handlers = M.get_handlers()
    return handlers[key] ~= nil
end

-- Get list of all supported theme keys
-- Returns: sorted array of theme key strings
function M.get_supported_keys()
    local handlers = M.get_handlers()
    local keys = {}
    for key, _ in pairs(handlers) do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

-- Clear the handler cache
-- Forces regeneration of handlers on next get_handlers() call
function M.clear_handlers()
    theme_handlers = nil
end

return M
