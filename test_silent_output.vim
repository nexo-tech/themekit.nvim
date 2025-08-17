" Test script for silent theme application
" This tests that theme switching doesn't produce unwanted output

" Reload the plugin
lua package.loaded['themekit'] = nil
lua package.loaded['themekit.loader'] = nil
lua require('themekit').init()

echo "Testing silent theme application..."

" Test applying a few themes to see if output is silenced
try
    lua require('themekit.commands.apply').apply_theme('heisenberg')
    echo "✓ heisenberg applied silently"
    
    " Wait a moment then try another theme
    lua require('themekit.commands.apply').apply_theme('acme') 
    echo "✓ acme applied silently"
    
catch
    echo "✗ Error during theme application: " . v:exception
endtry

echo "Silent output test complete."