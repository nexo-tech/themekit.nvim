-- ThemeKit Test Suite
-- Run with: :lua require('themekit.test').run_all()

local M = {}

-- Test utilities
local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", msg or "Assertion failed", vim.inspect(expected), vim.inspect(actual)))
    end
end

local function assert_not_nil(value, msg)
    if value == nil then
        error(msg or "Expected non-nil value")
    end
end

local function assert_nil(value, msg)
    if value ~= nil then
        error(string.format("%s: expected nil, got %s", msg or "Expected nil", vim.inspect(value)))
    end
end

-- Track test results
local results = { passed = 0, failed = 0, errors = {} }

local function run_test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        results.passed = results.passed + 1
        print(string.format("  ✓ %s", name))
    else
        results.failed = results.failed + 1
        table.insert(results.errors, { name = name, error = err })
        print(string.format("  ✗ %s: %s", name, err))
    end
end

-- Get internal functions for testing (we'll need to expose these)
local loader

function M.test_color_resolution()
    print("\n[Color Resolution Tests]")
    loader = require('themekit.loader')

    -- We need access to resolve_color - it's local, so we test via set_hl behavior
    -- For now, test the public API indirectly

    run_test("hex color passthrough", function()
        -- Test by applying a theme with hex colors
        local test_theme = {
            palette = {},
            ['ui.background'] = { fg = '#ffffff', bg = '#000000' }
        }
        -- This should not error
        loader.apply(test_theme)
    end)

    run_test("palette color resolution", function()
        local test_theme = {
            palette = { primary = '#ff0000' },
            ['ui.background'] = { fg = 'primary', bg = '#000000' }
        }
        loader.apply(test_theme)
    end)

    run_test("named color fallback", function()
        local test_theme = {
            palette = {},
            ['ui.background'] = { fg = 'white', bg = 'black' }
        }
        loader.apply(test_theme)
    end)

    run_test("RGBA alpha blending", function()
        local test_theme = {
            palette = {},
            ['ui.background'] = { fg = '#ff000080', bg = '#000000' }
        }
        loader.apply(test_theme)
    end)
end

function M.test_modifiers()
    print("\n[Modifier Tests]")
    loader = require('themekit.loader')

    run_test("bold modifier", function()
        local test_theme = {
            palette = {},
            keyword = { fg = '#ff0000', modifiers = {'bold'} }
        }
        loader.apply(test_theme)
    end)

    run_test("italic modifier", function()
        local test_theme = {
            palette = {},
            keyword = { fg = '#ff0000', modifiers = {'italic'} }
        }
        loader.apply(test_theme)
    end)

    run_test("multiple modifiers", function()
        local test_theme = {
            palette = {},
            keyword = { fg = '#ff0000', modifiers = {'bold', 'italic', 'underlined'} }
        }
        loader.apply(test_theme)
    end)

    run_test("dim modifier (should not error)", function()
        local test_theme = {
            palette = {},
            keyword = { fg = '#ff0000', modifiers = {'dim'} }
        }
        loader.apply(test_theme)
    end)
end

function M.test_underline_styles()
    print("\n[Underline Style Tests]")
    loader = require('themekit.loader')

    run_test("basic underline", function()
        local test_theme = {
            palette = {},
            keyword = { fg = '#ff0000', underline = { style = 'line' } }
        }
        loader.apply(test_theme)
    end)

    run_test("curl underline", function()
        local test_theme = {
            palette = {},
            keyword = { fg = '#ff0000', underline = { style = 'curl' } }
        }
        loader.apply(test_theme)
    end)

    run_test("underline with color", function()
        local test_theme = {
            palette = {},
            keyword = { fg = '#ff0000', underline = { style = 'curl', color = '#00ff00' } }
        }
        loader.apply(test_theme)
    end)
end

function M.test_palette_cycle_detection()
    print("\n[Palette Cycle Detection Tests]")
    loader = require('themekit.loader')

    run_test("simple cycle detection", function()
        local test_theme = {
            palette = { a = 'b', b = 'a' },
            ['ui.background'] = { fg = 'a', bg = '#000000' }
        }
        -- Should not infinite loop - should return the unresolved value or handle gracefully
        loader.apply(test_theme)
    end)

    run_test("deep cycle detection", function()
        local test_theme = {
            palette = { a = 'b', b = 'c', c = 'a' },
            ['ui.background'] = { fg = 'a', bg = '#000000' }
        }
        loader.apply(test_theme)
    end)
end

function M.test_all_handlers()
    print("\n[Handler Tests]")
    loader = require('themekit.loader')

    local keys = loader.get_supported_theme_keys()
    run_test(string.format("all %d handlers callable", #keys), function()
        for _, key in ipairs(keys) do
            local test_theme = {
                palette = {},
                [key] = { fg = '#ffffff', bg = '#000000' }
            }
            local ok, err = pcall(loader.apply, test_theme)
            if not ok then
                error(string.format("Handler '%s' failed: %s", key, err))
            end
        end
    end)
end

function M.test_theme_inheritance()
    print("\n[Theme Inheritance Tests]")
    local library = require('themekit.library')

    run_test("library loads themes", function()
        local themes = library.list_available_themes()
        assert_not_nil(themes, "Theme list should not be nil")
    end)
end

-- Snapshot test helper
function M.capture_highlights()
    local output = vim.fn.execute('silent highlight')
    return output
end

function M.save_snapshot(filename)
    local highlights = M.capture_highlights()
    local f = io.open(filename, 'w')
    if f then
        f:write(highlights)
        f:close()
        print("Snapshot saved to: " .. filename)
    else
        print("Failed to save snapshot to: " .. filename)
    end
end

function M.compare_snapshot(filename)
    local current = M.capture_highlights()
    local f = io.open(filename, 'r')
    if not f then
        print("No snapshot file found: " .. filename)
        return false
    end
    local saved = f:read('*all')
    f:close()

    if current == saved then
        print("Snapshot matches!")
        return true
    else
        print("Snapshot differs!")
        -- Could add diff output here
        return false
    end
end

function M.run_all()
    results = { passed = 0, failed = 0, errors = {} }

    print("=" .. string.rep("=", 50))
    print("ThemeKit Test Suite")
    print("=" .. string.rep("=", 50))

    -- Reload modules to get fresh state
    package.loaded['themekit.loader'] = nil
    package.loaded['themekit.library'] = nil

    M.test_color_resolution()
    M.test_modifiers()
    M.test_underline_styles()
    M.test_palette_cycle_detection()
    M.test_all_handlers()
    M.test_theme_inheritance()

    print("\n" .. string.rep("=", 50))
    print(string.format("Results: %d passed, %d failed", results.passed, results.failed))
    print(string.rep("=", 50))

    if results.failed > 0 then
        print("\nFailed tests:")
        for _, err in ipairs(results.errors) do
            print(string.format("  - %s: %s", err.name, err.error))
        end
    end

    return results.failed == 0
end

return M
