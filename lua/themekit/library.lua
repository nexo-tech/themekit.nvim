local configs = require("themekit.configs")

local M = {}

M.loaded_themes = {}
M.available_theme_files = {}

function M.load_all_themes()
    -- Skip if already loaded
    if vim.tbl_count(M.available_theme_files) > 0 then
        return M.loaded_themes
    end

    -- Get the Neovim config directory
    local config_dir = vim.fn.stdpath('config')
    local themes_dir = config_dir .. '/themes'

    -- Check if themes directory exists
    if vim.fn.isdirectory(themes_dir) == 0 then
        return M.loaded_themes
    end

    -- Find all .toml files in the themes directory
    local toml_files = vim.fn.glob(themes_dir .. '/*.toml', false, true)

    if #toml_files == 0 then
        return M.loaded_themes
    end

    -- Store the file paths for lazy loading
    for _, file_path in ipairs(toml_files) do
        -- Get just the filename without extension
        local filename = vim.fn.fnamemodify(file_path, ':t:r')
        
        -- Use relative path from themes directory for the loader
        local relative_path = 'themes/' .. filename .. '.toml'
        
        -- Store the relative path for later loading
        M.available_theme_files[filename] = relative_path
    end

    return M.loaded_themes
end

-- Helper function to deep merge tables (b overrides a)
local function deep_merge(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        return b
    end
    
    local result = {}
    
    -- Copy all from a
    for k, v in pairs(a) do
        result[k] = v
    end
    
    -- Override with b
    for k, v in pairs(b) do
        if type(v) == "table" and type(result[k]) == "table" then
            -- Special handling for palette - always deep merge
            if k == "palette" then
                result[k] = deep_merge(result[k], v)
            else
                -- For theme keys like "ui.background", just override
                result[k] = v
            end
        else
            result[k] = v
        end
    end
    
    return result
end

-- Track inheritance chain to detect cycles
local inheritance_chain = {}

function M.get_theme(theme_name)
    -- Ensure theme files are scanned
    if vim.tbl_count(M.available_theme_files) == 0 then
        M.load_all_themes()
    end

    -- Check if theme exists in available files
    if not M.available_theme_files[theme_name] then
        return nil
    end

    -- If theme is already fully resolved and loaded, return it
    if M.loaded_themes[theme_name] then
        return M.loaded_themes[theme_name]
    end

    -- Check for circular inheritance
    if inheritance_chain[theme_name] then
        error("Circular inheritance detected: " .. vim.inspect(vim.tbl_keys(inheritance_chain)) .. " -> " .. theme_name)
    end
    
    -- Add to inheritance chain
    inheritance_chain[theme_name] = true

    -- Load the theme lazily
    local relative_path = M.available_theme_files[theme_name]
    local theme_config, err = configs.load_config(relative_path)

    if err then
        -- Remove from inheritance chain before erroring
        inheritance_chain[theme_name] = nil
        error(err)
    end

    if theme_config then
        -- Check if theme inherits from another theme
        if theme_config.inherits then
            local parent_name = theme_config.inherits
            
            -- Get the parent theme (recursive call)
            local parent_theme = M.get_theme(parent_name)
            
            if not parent_theme then
                -- Remove from inheritance chain before erroring
                inheritance_chain[theme_name] = nil
                error("Parent theme '" .. parent_name .. "' not found for theme '" .. theme_name .. "'")
            end
            
            -- Merge parent theme with current theme (current overrides parent)
            theme_config = deep_merge(parent_theme, theme_config)
            
            -- Remove the inherits key from the final theme
            theme_config.inherits = nil
        end
        
        -- Store the fully resolved theme
        M.loaded_themes[theme_name] = theme_config
        
        -- Remove from inheritance chain
        inheritance_chain[theme_name] = nil
        
        return theme_config
    end

    -- Remove from inheritance chain
    inheritance_chain[theme_name] = nil
    
    return nil
end

function M.list_available_themes()
    -- Ensure theme files are scanned
    if vim.tbl_count(M.available_theme_files) == 0 then
        M.load_all_themes()
    end

    local theme_names = {}

    for name, _ in pairs(M.available_theme_files) do
        table.insert(theme_names, name)
    end

    table.sort(theme_names)
    return theme_names
end


function M.find_theme_index(theme_name)
    local theme_names = M.list_available_themes()
    for i, name in ipairs(theme_names) do
        if name == theme_name then
            return i
        end
    end
end

return M
