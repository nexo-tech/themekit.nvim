" Test script for improved theme picker
" This will test the arrow indicator and scrolling functionality

" Reload the plugin
lua package.loaded['themekit'] = nil
lua package.loaded['themekit.commands.picker'] = nil
lua package.loaded['themekit.library'] = nil
lua require('themekit').init()

" Open the picker to test improvements
lua require('themekit.commands.picker').open_picker()

echo "Theme picker opened with improvements:"
echo "- > arrow shows current selection"
echo "- Scrolling works with j/k navigation"
echo "- Page indicator shows current position"
echo ""
echo "Test by pressing j/k to navigate and see the improvements!"