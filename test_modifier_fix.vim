" Test script for modifier parsing fix
" This tests that themes with modifiers no longer cause E418 errors

" Reload the plugin
lua package.loaded['themekit'] = nil
lua package.loaded['themekit.loader'] = nil
lua require('themekit').init()

echo "Testing modifier parsing fix..."

" Test heisenberg theme (known to have modifier issues)
try
    lua require('themekit.commands.apply').apply_theme('heisenberg')
    echo "✓ heisenberg theme applied successfully"
catch
    echo "✗ Error applying heisenberg theme: " . v:exception
endtry

echo "Modifier parsing fix test complete."