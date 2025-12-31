# ThemeKit.nvim 🎨

A powerful Neovim plugin for loading and applying Helix-style themes with comprehensive syntax highlighting, UI customization, and diagnostic support.

## ✨ Features

- **Helix Theme Compatibility**: Load and apply themes designed for Helix editor
- **Comprehensive Syntax Highlighting**: Full support for TreeSitter and traditional syntax groups
- **Advanced UI Customization**: Customize statuslines, popups, menus, and more
- **Smart Color Resolution**: Automatic palette-based color resolution with fallbacks
- **Cursor Highlighting**: Per-mode cursor customization with shape preservation
- **Diagnostic Integration**: Built-in support for LSP diagnostics and error highlighting
- **Plugin Integration**: Automatic configuration for popular plugins like Lualine
- **Theme Validation**: Built-in theme checking and validation tools
- **TOML Configuration**: Native TOML parsing for theme files

## 🚀 Installation

### Using Packer
```lua
use {
    'nexo-tech/themekit.nvim',
    config = function()
        require('themekit').init()
    end
}
```

### Using Lazy.nvim
```lua
{
    'nexo-tech/themekit.nvim',
    config = function()
        require('themekit').init()
    end
}
```

### Using vim-plug
```vim
Plug 'nexo-tech/themekit.nvim'
```

## 📁 Setup

1. **Create themes directory**:
   ```bash
   mkdir -p ~/.config/nvim/themes
   ```

2. **Add your theme files**:
   Place `.toml` theme files in `~/.config/nvim/themes/`

3. **Initialize the plugin**:
   ```lua
   require('themekit').init()
   ```

## 🎯 Usage

### Commands

#### Theme Picker
```vim
:ThemePicker
```
Opens a beautiful floating window to browse and select themes interactively. Features:
- 🎨 Telescope-like interface with smooth navigation
- ⌨️ Intuitive keyboard shortcuts (j/k, <CR>, <Esc>)
- 🎯 Visual selection indicator with arrow cursor
- 📊 Shows number of available themes
- ⚡ Instant theme application

#### Apply a Theme
```vim
:ThemeApply <theme_name>
```
Applies a theme by name with tab completion for available themes.

#### Check Theme Compatibility
```vim
:ThemeCheck <theme_name>
```
Analyzes a theme and shows which keys are supported/unsupported.

### Programmatic Usage

```lua
local themekit = require('themekit')

-- Apply a theme programmatically
themekit.apply_theme('my-theme')

-- Get available themes
local themes = themekit.list_available_themes()

-- Check if a theme key is supported
local is_supported = themekit.is_theme_key_supported('ui.background')
```

## 📝 Theme Format

ThemeKit uses TOML format for theme files. Here's a comprehensive example:

```toml
# Color palette (optional)
[palette]
black = "#1a1b26"
red = "#f7768e"
green = "#9ece6a"
yellow = "#e0af68"
blue = "#7aa2f7"
magenta = "#bb9af7"
cyan = "#7dcfff"
white = "#c0caf5"
light_black = "#414868"
light_red = "#f7768e"
light_green = "#9ece6a"
light_yellow = "#e0af68"
light_blue = "#7aa2f7"
light_magenta = "#bb9af7"
light_cyan = "#7dcfff"
light_white = "#c0caf5"

# Syntax highlighting
keyword = "#bb9af7"
keyword.directive = "#7dcfff"
function = "#7aa2f7"
function.builtin = "#ff9e64"
type = "#2ac3de"
type.builtin = "#ff9e64"
string = "#9ece6a"
comment = "#565a6e"
variable = "#c0caf5"
variable.parameter = "#bb9af7"
constant = "#ff9e64"
constant.builtin = "#ff9e64"
operator = "#89ddff"
punctuation = "#c0caf5"

# UI elements
ui.background = { fg = "#c0caf5", bg = "#1a1b26" }
ui.statusline = { fg = "#c0caf5", bg = "#16161e" }
ui.statusline.inactive = { fg = "#565a6e", bg = "#16161e" }
ui.popup = { fg = "#c0caf5", bg = "#1a1b26" }
ui.menu = { fg = "#c0caf5", bg = "#1a1b26" }
ui.menu.selected = { fg = "#1a1b26", bg = "#7aa2f7" }
ui.selection = { bg = "#515c7e" }
ui.cursor = { bg = "#c0caf5" }
ui.cursor.insert = { bg = "#bb9af7" }
ui.cursor.select = { bg = "#7aa2f7" }
ui.linenr = { fg = "#565a6e" }
ui.linenr.selected = { fg = "#c0caf5" }

# Diagnostics
diagnostic.error = { fg = "#f7768e" }
diagnostic.warning = { fg = "#e0af68" }
diagnostic.info = { fg = "#7aa2f7" }
diagnostic.hint = { fg = "#565a6e" }

# Markup
markup.heading = { fg = "#bb9af7", modifiers = ["bold"] }
markup.bold = { modifiers = ["bold"] }
markup.italic = { modifiers = ["italic"] }
markup.link.url = { fg = "#7aa2f7", modifiers = ["underlined"] }

# Diff
diff.plus = { fg = "#9ece6a" }
diff.minus = { fg = "#f7768e" }
diff.delta = { fg = "#e0af68" }
```

## 🎨 Supported Theme Keys

### Syntax Highlighting
- `keyword`, `keyword.directive`
- `function`, `function.builtin`, `function.macro`
- `type`, `type.builtin`
- `string`, `constant`, `constant.builtin`, `constant.numeric`
- `variable`, `variable.parameter`, `variable.builtin`, `variable.other.member`
- `comment`, `operator`, `punctuation`, `punctuation.delimiter`
- `tag`, `attribute`, `namespace`, `constructor`, `label`
- `special`, `constant.character.escape`

### UI Elements
- `ui.background`, `ui.background.separator`
- `ui.statusline`, `ui.statusline.inactive`
- `ui.popup`, `ui.window`, `ui.help`
- `ui.text`, `ui.text.focus`, `ui.text.inactive`, `ui.text.directory`
- `ui.virtual`, `ui.virtual.ruler`, `ui.virtual.jump-label`, `ui.virtual.indent-guide`
- `ui.selection`, `ui.selection.primary`
- `ui.cursor`, `ui.cursor.normal`, `ui.cursor.insert`, `ui.cursor.select`
- `ui.cursorline.primary`, `ui.cursor.match`
- `ui.highlight`, `ui.highlight.frameline`
- `ui.menu`, `ui.menu.selected`, `ui.menu.scroll`
- `ui.linenr`, `ui.linenr.selected`
- `ui.debug`, `ui.debug.breakpoint`

### Diagnostics
- `diagnostic.error`, `diagnostic.warning`, `diagnostic.info`, `diagnostic.hint`
- `diagnostic.unnecessary`, `diagnostic.deprecated`
- `error`, `warning`, `info`, `hint`

### Markup
- `markup.heading`, `markup.bold`, `markup.italic`, `markup.strikethrough`
- `markup.link.url`, `markup.link.text`, `markup.raw`

### Diff
- `diff.plus`, `diff.minus`, `diff.delta`

## 🔧 Configuration

### Advanced Setup

```lua
require('themekit').init({
    -- Custom configuration options can be added here
    themes_dir = "~/.config/nvim/themes", -- Custom themes directory
    auto_apply = false, -- Don't auto-apply themes on startup
})
```

### Custom Theme Handlers

```lua
local themekit = require('themekit')

-- Add custom theme key handler
themekit.add_theme_handler('custom.key', function(attrs, palette)
    -- Your custom highlighting logic here
    vim.api.nvim_set_hl(0, 'CustomHighlight', {
        fg = attrs.fg,
        bg = attrs.bg,
        bold = attrs.modifiers and vim.tbl_contains(attrs.modifiers, 'bold')
    })
end)
```

## 🛠️ Plugin Integration

### Lualine
ThemeKit automatically configures Lualine when available:

```lua
-- Lualine will be automatically configured with theme colors
require('lualine').setup({
    -- Your lualine config here
})
```

### Other Plugins
The plugin provides comprehensive highlight group mapping for:
- GitSigns
- IndentBlankline
- TreeSitter
- LSP diagnostics
- And many more

## 🔍 Theme Validation

Use the built-in theme checker to validate your themes:

```vim
:ThemeCheck my-theme
```

This will show:
- ✅ Supported theme keys
- ❌ Unsupported theme keys
- 📊 Coverage percentage
- 💡 Recommendations for improvement

## 🎯 Examples

### Minimal Theme
```toml
# Minimal dark theme
ui.background = { bg = "#1a1b26" }
ui.text = { fg = "#c0caf5" }
keyword = "#bb9af7"
string = "#9ece6a"
comment = "#565a6e"
```

### Colorful Theme
```toml
[palette]
primary = "#7aa2f7"
secondary = "#bb9af7"
accent = "#f7768e"
success = "#9ece6a"
warning = "#e0af68"

ui.background = { bg = "#1a1b26" }
ui.statusline = { fg = "primary", bg = "#16161e" }
keyword = "secondary"
function = "primary"
string = "success"
comment = "#565a6e"
diagnostic.error = "accent"
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by Helix editor's theme system
- Built on top of the excellent TOML parser
- Thanks to the Neovim community for inspiration and feedback

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/nexo-tech/themekit.nvim/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/nexo-tech/themekit.nvim/discussions)
- 📖 **Documentation**: This README and inline code comments

---

**Made with ❤️ for the Neovim community**
