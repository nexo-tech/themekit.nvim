local configs = require("themekit.configs")
local state = require("themekit.state")
local config = require("themekit.config")

local M = {}

function M.load_all_themes()
    -- Skip if already scanned
    if state.is_themes_scanned() then
        return
    end

    -- Get themes directory from config
    local themes_dir = config.themes_dir

    -- Check if themes directory exists
    if vim.fn.isdirectory(themes_dir) == 0 then
        return
    end

    -- Find all .toml files in the themes directory
    local toml_files = vim.fn.glob(themes_dir .. '/*.toml', false, true)

    if #toml_files == 0 then
        return
    end

    -- Store the file paths for lazy loading
    local theme_files = {}
    for _, file_path in ipairs(toml_files) do
        local filename = vim.fn.fnamemodify(file_path, ':t:r')
        local relative_path = 'themes/' .. filename .. '.toml'
        theme_files[filename] = relative_path
    end
    state.set_available_themes(theme_files)
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
        if k == "palette" and type(v) == "table" and type(result[k]) == "table" then
            -- Palette: deep merge to combine parent and child colors
            result[k] = deep_merge(result[k], v)
        elseif type(v) == "table" and type(result[k]) == "table" then
            -- Regular theme keys: child completely overrides parent (no merge)
            result[k] = v
        else
            -- Non-table values: direct override
            result[k] = v
        end
    end
    
    return result
end

function M.get_theme(theme_name, inheritance_chain)
    -- Initialize inheritance_chain if not provided (top-level call)
    inheritance_chain = inheritance_chain or {}
    -- Ensure theme files are scanned
    if not state.is_themes_scanned() then
        M.load_all_themes()
    end

    -- Check if theme exists in available files
    local available_themes = state.get_available_themes()
    if not available_themes[theme_name] then
        return nil
    end

    -- If theme is already fully resolved and loaded, return it
    if state.is_theme_cached(theme_name) then
        return state.get_cached_theme(theme_name)
    end

    -- Check for circular inheritance
    if inheritance_chain[theme_name] then
        return nil, "Circular inheritance detected: " .. vim.inspect(vim.tbl_keys(inheritance_chain)) .. " -> " .. theme_name
    end

    -- Add to inheritance chain
    inheritance_chain[theme_name] = true

    -- Load the theme lazily
    local relative_path = available_themes[theme_name]
    local theme_config, err = configs.load_config(relative_path)

    if err then
        return nil, err
    end

    if theme_config then
        -- Check if theme inherits from another theme
        if theme_config.inherits then
            local parent_name = theme_config.inherits

            -- Get the parent theme (recursive call, pass inheritance_chain)
            local parent_theme, parent_err = M.get_theme(parent_name, inheritance_chain)

            if not parent_theme then
                return nil, "Parent theme '" .. parent_name .. "' not found for theme '" .. theme_name .. "': " .. (parent_err or "unknown error")
            end
            
            -- Merge parent theme with current theme (current overrides parent)
            theme_config = deep_merge(parent_theme, theme_config)
            
            -- Remove the inherits key from the final theme
            theme_config.inherits = nil
        end
        
        -- Store the fully resolved theme
        state.cache_theme(theme_name, theme_config)

        return theme_config
    end

    return nil
end

function M.list_available_themes()
    -- Ensure theme files are scanned
    if not state.is_themes_scanned() then
        M.load_all_themes()
    end

    local theme_names = {}
    local available_themes = state.get_available_themes()

    for name, _ in pairs(available_themes) do
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

function M.theme_exists(theme_name)
    if not state.is_themes_scanned() then
        M.load_all_themes()
    end
    local available_themes = state.get_available_themes()
    return available_themes[theme_name] ~= nil
end

return M
