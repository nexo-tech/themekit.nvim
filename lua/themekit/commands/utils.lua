-- Shared utilities for command layer
-- Eliminates duplication across apply, check, and picker commands

local library = require("themekit.library")

local M = {}

-- Get theme safely with detailed error messages
-- Returns: theme_data, error_message
-- If successful: theme_data is non-nil, error_message is nil
-- If failed: theme_data is nil, error_message contains details
function M.get_theme_safe(theme_name)
    if not theme_name or theme_name == "" then
        return nil, "Theme name is required"
    end

    local theme = library.get_theme(theme_name)

    if not theme then
        if library.theme_exists(theme_name) then
            return nil, "Failed to load theme '" .. theme_name .. "' - check theme file syntax"
        else
            local available = library.list_available_themes()
            if #available == 0 then
                return nil, "No themes found. Create themes in ~/.config/nvim/themes/"
            else
                return nil, "Theme '" .. theme_name .. "' not found. Available: " .. table.concat(available, ", ")
            end
        end
    end

    return theme, nil
end

-- Get available themes with validation
-- Returns: themes_list, has_themes, error_message
function M.get_available_themes_with_validation()
    library.load_all_themes()
    local themes = library.list_available_themes()

    if #themes == 0 then
        return {}, false, "No themes found. Create themes in ~/.config/nvim/themes/"
    end

    return themes, true, nil
end

-- Complete theme names for command-line completion
-- arg_lead: string - the partial theme name typed so far
-- Returns: array of matching theme names
function M.complete_theme_names(arg_lead)
    local themes = library.list_available_themes()
    local matches = {}

    for _, theme in ipairs(themes) do
        if string.match(theme, "^" .. arg_lead) then
            table.insert(matches, theme)
        end
    end

    return matches
end

-- Unified notification functions for consistent messaging

function M.notify_error(message)
    vim.notify(message, vim.log.levels.ERROR)
end

function M.notify_success(message)
    vim.notify(message, vim.log.levels.INFO)
end

function M.notify_warn(message)
    vim.notify(message, vim.log.levels.WARN)
end

return M
