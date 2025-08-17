# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ThemeKit.nvim is a Neovim plugin that enables loading and applying Helix-style TOML themes. It provides comprehensive theme translation from Helix's theme format to Neovim's highlight groups, including support for syntax highlighting, UI elements, diagnostics, and cursor customization.

## Architecture

### Core Components

1. **`lua/themekit/init.lua`** - Entry point that provides `init()` and `apply()` functions
2. **`lua/themekit/loader.lua`** (644 lines) - Core theme application engine
   - Maps Helix theme keys to Neovim highlight groups
   - Handles palette color resolution
   - Manages cursor highlight buffering and application
   - Contains ~90 theme key handlers for different syntax/UI elements

3. **`lua/themekit/toml.lua`** (1767 lines) - TOML parser implementation
   - Full TOML v1.0.0 spec compliance
   - Handles all TOML data types including dates, arrays, inline tables
   - Includes both parsing and encoding capabilities

4. **`lua/themekit/library.lua`** - Theme management
   - Loads themes from `~/.config/nvim/themes/*.toml`
   - Caches parsed themes
   - Provides theme listing and retrieval functions

5. **`lua/themekit/commands/`** - User-facing commands
   - `apply.lua` - ThemeApply command with tab completion
   - `check.lua` - ThemeCheck command for theme validation
   - `picker.lua` - ThemePicker floating window UI
   - `init.lua` - Command registration

### Key Design Patterns

- **Theme Key Handlers**: Each Helix theme key (e.g., `ui.background`, `keyword.directive`) has a dedicated handler function that applies it to appropriate Neovim highlight groups
- **Color Resolution**: Colors can be hex values or references to palette entries, resolved at application time
- **Cursor Buffering**: Cursor highlights are buffered and merged before application to handle multiple theme keys affecting the same cursor mode
- **Fallback Mapping**: Many handlers set both TreeSitter (`@keyword`) and traditional Vim (`Keyword`) highlight groups for compatibility

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
```vim
:lua package.loaded['themekit'] = nil
:lua package.loaded['themekit.loader'] = nil
:lua package.loaded['themekit.library'] = nil
:lua require('themekit').init()
```

## Theme File Location

Themes should be placed in: `~/.config/nvim/themes/*.toml`

## Adding New Theme Keys

To support a new Helix theme key:

1. Add a handler function in `loader.lua`:
```lua
theme_handlers['new.theme.key'] = function(attrs, palette)
    set_hl('NvimHighlightGroup', attrs, palette)
end
```

2. The handler receives:
   - `attrs`: Table with `fg`, `bg`, `modifiers`, etc.
   - `palette`: Color palette for resolution

3. Use `set_hl()` for regular highlights or `set_cursor_hl()` for cursor-specific highlights

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

- The TOML parser (`toml.lua`) is a complete implementation supporting the full TOML v1.0.0 specification
- Cursor highlights use a special buffering system to merge attributes from multiple theme keys before applying via `guicursor`
- The plugin integrates with Lualine when available, automatically configuring it with theme colors
- Theme validation (`check.lua`) compares theme keys against the supported handler list in `loader.lua`
- **Theme inheritance**: Fully resolved themes have the `inherits` key removed and are cached to avoid re-resolution