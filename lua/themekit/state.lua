-- Centralized state management for ThemeKit
-- Provides single source of truth for theme state and caching

local M = {}

-- Theme state
M.loaded_themes = {}         -- Cache of parsed theme data
M.current_theme = nil        -- Name of currently applied theme
M.available_theme_files = {} -- Cache of discovered theme files (name -> relative path)

-- Clear theme cache
-- If theme_name is provided, clears only that theme; otherwise clears all
function M.clear_theme_cache(theme_name)
    if theme_name then
        M.loaded_themes[theme_name] = nil
    else
        M.loaded_themes = {}

        -- Clear handlers when clearing all themes
        local ok, handlers = pcall(require, "themekit.handlers")
        if ok and handlers.clear_handlers then
            handlers.clear_handlers()
        end
    end
end

-- Get cached theme
-- Returns: theme data or nil if not cached
function M.get_cached_theme(theme_name)
    return M.loaded_themes[theme_name]
end

-- Cache a theme
-- theme_name: string - name of the theme
-- theme_data: table - parsed theme data
function M.cache_theme(theme_name, theme_data)
    M.loaded_themes[theme_name] = theme_data
end

-- Check if a theme is cached
-- Returns: boolean
function M.is_theme_cached(theme_name)
    return M.loaded_themes[theme_name] ~= nil
end

-- Set the current theme
-- theme_name: string - name of the theme being applied
function M.set_current_theme(theme_name)
    M.current_theme = theme_name
end

-- Get the current theme name
-- Returns: string or nil
function M.get_current_theme()
    return M.current_theme
end

-- Get available theme files
-- Returns: table mapping theme names to relative paths
function M.get_available_themes()
    return M.available_theme_files
end

-- Set available theme files
-- themes: table mapping theme names to relative paths
function M.set_available_themes(themes)
    M.available_theme_files = themes
end

-- Check if themes have been scanned
-- Returns: boolean
function M.is_themes_scanned()
    return vim.tbl_count(M.available_theme_files) > 0
end

-- Reset all state (useful for testing or cleanup)
function M.reset_all()
    M.loaded_themes = {}
    M.current_theme = nil
    M.available_theme_files = {}

    -- Clear handlers on full reset
    local ok, handlers = pcall(require, "themekit.handlers")
    if ok and handlers.clear_handlers then
        handlers.clear_handlers()
    end
end

return M
