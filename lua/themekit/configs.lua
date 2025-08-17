local toml = require("themekit.toml")

local M = {}

-- Load and parse a TOML config file
-- @param filename string Name of the config file (e.g., "config.toml")
-- @return table Parsed configuration table
-- @return nil, string Error message if parsing fails
function M.load_config(filename)
    -- Get Neovim config directories to search
    local config_paths = {
        vim.fn.stdpath("config"),
        vim.fn.stdpath("config") .. "/lua",
        vim.fn.stdpath("data") .. "/nvim",
    }
    
    local file_path = nil
    local file = nil
    local err = nil
    
    -- Search for the config file in each config directory
    for _, config_dir in ipairs(config_paths) do
        local candidate_path = config_dir .. "/" .. filename
        file, err = io.open(candidate_path, "r")
        if file then
            file_path = candidate_path
            break
        end
    end
    
    -- If file not found in any config directory, return error
    if not file then
        return nil, "Failed to find config file '" .. filename .. "' in config directories: " .. (err or "unknown error")
    end
    
    local content = file:read("*a")
    file:close()

    -- Parse TOML content
    local ok, config = pcall(toml.parse, content)
    if not ok then
        return nil, "Failed to parse TOML: " .. (config or "unknown error")
    end

    return config
end

return M