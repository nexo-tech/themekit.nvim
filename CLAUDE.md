# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ThemeKit.nvim is a Neovim plugin that enables loading and applying Helix-style TOML themes. It provides comprehensive theme translation from Helix's theme format to Neovim's highlight groups, including support for syntax highlighting, UI elements, diagnostics, and cursor customization.

## Architecture

### Modular Design (Post-Refactoring)

ThemeKit follows a **clean, modular architecture** with focused single-responsibility modules:

```
lua/themekit/
├── init.lua              - Public API entry point
├── loader.lua            - Theme application orchestrator (~189 lines)
├── state.lua             - Centralized state management
├── config.lua            - Internal configuration constants
│
├── color/                - Color processing module
│   ├── init.lua         - Public color API facade
│   ├── parser.lua       - Hex color parsing
│   ├── blender.lua      - RGB/alpha blending
│   ├── resolver.lua     - Palette resolution (with context-aware caching!)
│   └── fallbacks.lua    - Named color mappings
│
├── highlight/            - Highlight building module
│   ├── init.lua         - Public highlight API facade
│   ├── builder.lua      - Highlight command construction
│   ├── modifiers.lua    - Modifier processing
│   └── cursor.lua       - Cursor highlight buffering
│
├── handlers/             - Theme key handler module
│   ├── init.lua         - Public handlers API facade
│   ├── mappings.lua     - Data-driven handler mappings (166 keys)
│   └── generator.lua    - Handler factory (eliminates duplication)
│
├── commands/             - User-facing commands
│   ├── init.lua         - Command registration
│   ├── utils.lua        - Shared command utilities
│   ├── apply.lua        - ThemeApply command
│   ├── check.lua        - ThemeCheck validation
│   └── picker.lua       - ThemePicker floating UI
│
├── library.lua           - Theme file loading & caching
├── configs.lua           - Config file parsing
└── toml.lua              - TOML parser (protected, do not edit)
```

### Core Components

1. **`init.lua`** - Public API entry point
   - Exposes `init()` and `apply(theme_name)` functions
   - Minimal interface, delegates to specialized modules

2. **`loader.lua`** - Theme application orchestrator
   - **Reduced from 699 → 189 lines** through modular extraction
   - Orchestrates theme application via focused helper functions
   - No complex logic - delegates to color, highlight, and handler modules

3. **`color/` module** - All color operations (265 lines across 5 files)
   - **Context-aware caching** (fixes alpha blending cache bug)
   - Pure functions for parsing, blending, resolution
   - Separated concerns: parser ← blender ← resolver

4. **`highlight/` module** - Highlight construction (269 lines across 4 files)
   - Builder creates highlight commands (uses vim.cmd, not nvim_set_hl - see Gotchas)
   - Modifiers processes theme modifiers
   - Cursor handles buffering and guicursor management

5. **`handlers/` module** - Theme key handlers (322 lines across 3 files)
   - **Data-driven mappings** separate from generation logic
   - Single handler factory (eliminates duplication)
   - Easy to add new theme keys (just update mappings.lua)

6. **`state.lua`** - Centralized state management
   - Theme cache (`loaded_themes`)
   - Current theme tracking
   - Clear invalidation API

7. **`commands/utils.lua`** - Shared command utilities
   - Eliminates duplication across apply/check/picker
   - Unified error handling and notifications

### Key Design Patterns

- **Modular Architecture**: Single-responsibility modules with clear boundaries
- **Facade Pattern**: Each module exposes a clean public API via init.lua
- **Data-Driven Handlers**: Handler mappings (data) separated from generation logic (code)
- **Context-Aware Caching**: Color cache keys include background context to fix alpha blending
- **Orchestrator Pattern**: `loader.apply()` is a thin orchestrator delegating to focused helpers
- **Pure Functions**: Color and highlight modules use pure functions for testability

## Development Commands

This is a pure Lua Neovim plugin with no build process, tests, or linting setup currently. Key development tasks:

### Loading the Plugin
```vim
:lua require('themekit').init()
```

### Testing Theme Application
```vim
:ThemeApply <theme_name>
:ThemePicker
:ThemeCheck <theme_name>
```

### Reloading During Development

To reload after making changes:

```vim
:lua package.loaded['themekit'] = nil
:lua package.loaded['themekit.loader'] = nil
:lua package.loaded['themekit.library'] = nil
:lua package.loaded['themekit.state'] = nil
:lua package.loaded['themekit.color'] = nil
:lua package.loaded['themekit.highlight'] = nil
:lua package.loaded['themekit.handlers'] = nil
:lua require('themekit').init()
```

Or reload all themekit modules:

```vim
:lua for k in pairs(package.loaded) do if k:match("^themekit") then package.loaded[k] = nil end end
:lua require('themekit').init()
```

## Theme File Location

Themes should be placed in: `~/.config/nvim/themes/*.toml`

## Adding New Theme Keys

To support a new Helix theme key, update the **data-driven mappings**:

### For Regular Highlights

Add to `lua/themekit/handlers/mappings.lua` in the `M.regular` table:

```lua
M.regular = {
    -- ... existing mappings ...
    ['new.theme.key'] = {'NvimHighlightGroup', 'FallbackGroup'},
}
```

The handler is automatically generated! Each theme key maps to one or more Neovim highlight groups.

### For Cursor Highlights

Add to `lua/themekit/handlers/mappings.lua` in the `M.cursor` table:

```lua
M.cursor = {
    -- ... existing mappings ...
    ['ui.cursor.new'] = {'CursorNewMode'},
}
```

Cursor highlights use buffering and are merged before application.

### Custom Handler Logic

If you need custom logic beyond simple mapping, use the public API in `loader.lua`:

```lua
local handlers = require("themekit.handlers")

-- Add a custom handler
handlers.add_handler('custom.theme.key', function(attrs, palette)
    local color = require("themekit.color")
    local highlight = require("themekit.highlight")

    -- Custom logic here
    local resolved_fg = color.resolve(attrs.fg, palette)
    highlight.apply('CustomGroup', { fg = resolved_fg }, palette)
end)
```

**Key Changes from Old Architecture:**
- ❌ OLD: Add handler directly in loader.lua (monolithic)
- ✅ NEW: Update data-driven mappings.lua (modular, no code changes needed!)
- ✅ Handlers are auto-generated from mappings
- ✅ Easy to add new keys without touching generation logic

## Theme Inheritance

ThemeKit supports Helix-style theme inheritance, allowing themes to extend other themes with overrides:

### Basic Inheritance
```toml
# child_theme.toml
inherits = "parent_theme"

# Override specific theme keys
keyword = { fg = "gold" }
"ui.background" = { fg = "#e0e0e0", bg = "#0a0a12" }

# Override and add colors in the palette
[palette]
# Override existing color
red = "#ff0000" 
# Add new color
gold = "#ffd700"
```

### Implementation Details

- **Multi-level inheritance**: Themes can inherit from themes that themselves inherit from other themes
- **Deep palette merging**: Parent and child palette entries are merged, with child entries overriding parent ones
- **Theme key override**: Child theme keys completely replace parent theme keys (no merging of individual attributes)
- **Circular dependency detection**: The system detects and prevents circular inheritance chains
- **Lazy resolution**: Inheritance is resolved recursively when the theme is first loaded

### Key Functions in `library.lua`:
- `deep_merge(a, b)` - Merges two theme tables with special handling for palette
- `inheritance_chain` - Global table tracking current inheritance resolution to detect cycles
- Modified `get_theme()` - Handles recursive inheritance resolution

## Important Implementation Details

### Module Architecture

- **Modular Design**: Code organized into focused modules (color/, highlight/, handlers/)
- **Facade Pattern**: Each module exposes public API via init.lua
- **State Management**: Centralized in state.lua (theme cache, current theme)
- **Configuration**: Centralized in config.lua (constants, paths)

### Theme Processing

- **TOML Parser** (`toml.lua`): Complete TOML v1.0.0 spec implementation (protected, do not edit)
- **Color Resolution**: Context-aware caching fixes alpha blending bugs (cache key includes background)
- **Cursor Buffering**: Cursor highlights buffered and merged before applying via `guicursor`
- **Theme Inheritance**: Fully resolved themes cached to avoid re-resolution
- **Scope Fallback**: Implements Helix's "longest matching key" rule (more specific override less specific)

### Handler System

- **Data-Driven**: 166 theme key handlers auto-generated from mappings.lua
- **No Duplication**: Single handler factory eliminates copy-paste code
- **Easy Extension**: Add new theme keys by updating mappings (no code changes needed)
- **Handler Generator**: Creates handlers for both regular and cursor highlights

### Integrations

- **Lualine**: Auto-configured with theme colors when available
- **TreeSitter**: Both TreeSitter (@keyword) and traditional (Keyword) groups supported
- **Terminal**: Terminal colors mapped from palette

## Refactoring History & Best Practices

### Major Refactoring (Jan 2025)

ThemeKit underwent a comprehensive refactoring to eliminate technical debt:

**Results:**
- loader.lua: 699 → 189 lines (73% reduction!)
- Created 16 new focused modules
- Fixed critical cache bug (context-aware keys for alpha blending)
- Eliminated handler generation duplication
- Centralized state management

**Key Improvements:**
1. **Color Module** - Fixed cache bug, separated parsing/blending/resolution
2. **Highlight Module** - Isolated modifier processing and cursor management
3. **Handler Module** - Data-driven mappings, single factory
4. **State Module** - Centralized theme cache and current theme tracking
5. **Commands Utils** - Eliminated duplication across commands

### Best Practices for Future Changes

✅ **DO:**
- Add new theme keys by updating handlers/mappings.lua (data-driven)
- Use module facades (require "themekit.color" not "themekit.color.parser")
- Keep functions focused (single responsibility)
- Use state.lua for theme-level state
- Use config.lua for constants
- Write pure functions when possible (easier to test)

❌ **DON'T:**
- Add handler logic directly to loader.lua (use mappings or handlers.add_handler)
- Scatter state across modules (use state.lua)
- Hardcode constants (use config.lua)
- Create monolithic functions (extract helpers)
- Bypass module facades (breaks encapsulation)
- Edit toml.lua (protected file)

## Line Number Highlighting (Helix-style)

ThemeKit maps Helix line number scopes to Neovim highlight groups:
- `ui.linenr` → `LineNr` (inactive line numbers)
- `ui.linenr.selected` → `CursorLineNr` (active line number)

**To enable Helix-style line number highlighting** (bright active line number), add to your Neovim config:

```lua
-- Enable cursorline to highlight current line number
vim.opt.cursorline = true

-- Highlight ONLY the line number, not the entire line (Helix default)
vim.opt.cursorlineopt = 'number'

-- Or highlight both line number and line:
-- vim.opt.cursorlineopt = 'both'
```

**Theme file example:**
```toml
[palette]
gray = "#808080"
white = "#ffffff"

"ui.linenr" = { fg = "gray" }              # Inactive line numbers
"ui.linenr.selected" = { fg = "white", modifiers = ["bold"] }  # Active line number (bright + bold)
```

**Smart Fallback**: If a theme defines `ui.linenr` but NOT `ui.linenr.selected`, ThemeKit auto-generates a brighter version (30% blend with white + bold). This ensures Helix-style line number highlighting works even with incomplete themes.

**ThemeKit does NOT force cursorline settings** - the theme only defines colors, you control whether cursorline is enabled in your Neovim config.

## Gotchas

### Do NOT use `nvim_set_hl()` for Regular Highlights

The highlight builder (`highlight/builder.lua`) uses `vim.cmd('highlight ...')` instead of `vim.api.nvim_set_hl()`.

**Why**: `nvim_set_hl()` **completely replaces** highlight definitions, clearing any attributes not explicitly specified. This means:
- `nvim_set_hl(0, "Normal", {fg = "#ffffff"})` clears the background color
- `nvim_set_hl(0, "Comment", {italic = true})` clears fg/bg colors

In contrast, `vim.cmd('highlight Comment gui=italic')` only sets the specified attributes, preserving existing colors.

**Impact**: Using `nvim_set_hl()` causes themes to display incorrectly with washed-out or missing colors, since highlight groups end up with incomplete definitions.

**Cursor highlights are different**: The cursor module (`highlight/cursor.lua`) uses `nvim_set_hl()` correctly because cursor highlights are buffered, merged, and applied all at once with complete attribute sets.

### Context-Aware Color Caching

The color resolver (`color/resolver.lua`) uses **context-aware cache keys** that include the background color:

```lua
-- Cache key includes background context to handle alpha blending correctly
cache_key = color .. "|" .. (bg_color or "")
```

**Why**: Alpha-blended colors depend on the background. Without context-aware keys, the same transparent color could return incorrect cached values when used with different backgrounds.

**Impact**: This fix prevents alpha blending bugs where cached colors don't match the current background context.

## Protected Files

### Do NOT edit `toml.lua`

The file `lua/themekit/toml.lua` is a complete, standalone TOML parser implementation. Do not modify this file under any circumstances. It is stable, well-tested, and changes could break TOML parsing across all themes.