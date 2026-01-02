-- Handlers module public API
-- Provides theme key handler generation and management

local generator = require("themekit.handlers.generator")
local mappings = require("themekit.handlers.mappings")

local M = {}

-- Re-export generator functions
M.generate = generator.generate
M.get_handlers = generator.get_handlers
M.add_handler = generator.add_handler
M.has_handler = generator.has_handler
M.get_supported_keys = generator.get_supported_keys
M.clear_handlers = generator.clear_handlers

-- Re-export mappings for direct access if needed
M.regular_mappings = mappings.regular
M.cursor_mappings = mappings.cursor

return M
