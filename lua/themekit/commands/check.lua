local themes = require("themekit.library")
local loader = require("themekit.loader")

local M = {}

function M.check_theme(theme_name)
    -- Load themes if not already loaded
    themes.load_all_themes()

    -- Get the specific theme
    local theme_data = themes.get_theme(theme_name)
    if not theme_data then
        print(string.format("❌ Theme '%s' not found!", theme_name))
        print("Available themes:")
        local available = themes.list_available_themes()
        for _, name in ipairs(available) do
            print("  • " .. name)
        end
        return false
    end

    print(string.format("🎨 Theme Check Report: %s", theme_name))
    print(string.rep("=", 50))

    -- Get supported theme keys from resolver
    local supported_keys = loader.get_supported_theme_keys()
    local supported_set = {}
    for _, key in ipairs(supported_keys) do
        supported_set[key] = true
    end

    -- Analyze theme keys
    local resolved_keys = {}
    local unresolved_keys = {}
    local total_keys = 0

    for key, value in pairs(theme_data) do
        if key ~= "palette" then -- Skip palette as it's handled separately
            total_keys = total_keys + 1
            if supported_set[key] then
                table.insert(resolved_keys, key)
            else
                table.insert(unresolved_keys, key)
            end
        end
    end

    -- Sort the lists for better readability
    table.sort(resolved_keys)
    table.sort(unresolved_keys)

    -- Print summary
    local resolved_count = #resolved_keys
    local unresolved_count = #unresolved_keys
    local coverage_percent = math.floor((resolved_count / total_keys) * 100)

    print(string.format("📊 Summary:"))
    print(string.format("  Total theme keys: %d", total_keys))
    print(string.format("  ✅ Resolved: %d (%d%%)", resolved_count, coverage_percent))
    print(string.format("  ❌ Unresolved: %d (%d%%)", unresolved_count, 100 - coverage_percent))
    print()

    -- Print resolved keys
    if #resolved_keys > 0 then
        print("✅ Resolved Keys:")
        local categories = M.categorize_keys(resolved_keys)
        for category, keys in pairs(categories) do
            print(string.format("  📁 %s (%d):", category, #keys))
            for _, key in ipairs(keys) do
                local value = theme_data[key]
                local value_str = type(value) == "string" and value or M.format_complex_value(value)
                print(string.format("    • %s → %s", key, value_str))
            end
        end
        print()
    end

    -- Print unresolved keys
    if #unresolved_keys > 0 then
        print("❌ Unresolved Keys:")
        local categories = M.categorize_keys(unresolved_keys)
        for category, keys in pairs(categories) do
            print(string.format("  📁 %s (%d):", category, #keys))
            for _, key in ipairs(keys) do
                local value = theme_data[key]
                local value_str = type(value) == "string" and value or M.format_complex_value(value)
                print(string.format("    • %s → %s", key, value_str))
            end
        end
        print()
    end

    -- Handle palette separately
    if theme_data.palette then
        print("🎨 Palette Colors:")
        local palette_keys = {}
        for key, _ in pairs(theme_data.palette) do
            table.insert(palette_keys, key)
        end
        table.sort(palette_keys)

        for _, key in ipairs(palette_keys) do
            print(string.format("  • %s → %s", key, theme_data.palette[key]))
        end
        print()
    end

    -- Recommendations
    if #unresolved_keys > 0 then
        print("💡 Recommendations:")
        print("  • Consider adding handlers for unresolved keys in theme resolver")
        print("  • Check if some keys might be variants of existing handlers")
        print("  • Some keys might be editor-specific and not applicable to Neovim")
    end

    return true
end

function M.categorize_keys(keys)
    local categories = {
        ["Syntax"] = {},
        ["UI"] = {},
        ["Diagnostics"] = {},
        ["Markup"] = {},
        ["Diff"] = {},
        ["Other"] = {}
    }

    for _, key in ipairs(keys) do
        if key:match("^ui%.") then
            table.insert(categories["UI"], key)
        elseif key:match("^diagnostic%.") or key == "error" or key == "warning" or key == "info" or key == "hint" then
            table.insert(categories["Diagnostics"], key)
        elseif key:match("^markup%.") then
            table.insert(categories["Markup"], key)
        elseif key:match("^diff%.") then
            table.insert(categories["Diff"], key)
        elseif key:match("^(keyword|function|type|string|comment|variable|constant|operator|punctuation|tag|attribute|namespace|special|constructor|label)") then
            table.insert(categories["Syntax"], key)
        else
            table.insert(categories["Other"], key)
        end
    end

    -- Remove empty categories
    for category, keys_list in pairs(categories) do
        if #keys_list == 0 then
            categories[category] = nil
        end
    end

    return categories
end

function M.format_complex_value(value)
    if type(value) == "table" then
        local parts = {}
        if value.fg then table.insert(parts, "fg:" .. value.fg) end
        if value.bg then table.insert(parts, "bg:" .. value.bg) end
        if value.modifiers then
            table.insert(parts, "mods:" .. table.concat(value.modifiers, ","))
        end
        if value.underline then
            if type(value.underline) == "table" and value.underline.color then
                table.insert(parts, "underline:" .. value.underline.color)
            else
                table.insert(parts, "underline")
            end
        end
        return "{" .. table.concat(parts, " ") .. "}"
    end
    return tostring(value)
end

function M.setup_theme_check_command()
    vim.api.nvim_create_user_command('ThemeCheck', function(opts)
        local theme_name = opts.args
        if theme_name == "" then
            print("Usage: :ThemeCheck <theme_name>")
            print("Available themes:")
            local available = themes.list_available_themes()
            for _, name in ipairs(available) do
                print("  • " .. name)
            end
            return
        end

        M.check_theme(theme_name)
    end, {
        nargs = '?',
        complete = function()
            return themes.list_available_themes()
        end,
        desc = 'Check theme key resolution status'
    })
end

return M
