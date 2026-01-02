-- Highlight module public API
-- Provides highlight building, modifier processing, and cursor highlighting

local builder = require("themekit.highlight.builder")
local modifiers = require("themekit.highlight.modifiers")
local cursor = require("themekit.highlight.cursor")

local M = {}

-- Re-export builder functions
M.apply = builder.apply
M.apply_groups = builder.apply_groups

-- Re-export modifier functions
M.process_modifiers = modifiers.process
M.get_underline_style = modifiers.get_underline_style

-- Re-export cursor functions
M.buffer_cursor = cursor.buffer
M.flush_cursor = cursor.flush
M.clear_cursor = cursor.clear

-- Re-export constants
M.underline_styles = modifiers.underline_styles
M.modifier_map = modifiers.modifier_map

return M
