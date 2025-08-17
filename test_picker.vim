" Test script for theme picker
" Run with: nvim -u test_picker.vim

" Set up the runtime path
set runtimepath+=.

" Initialize the plugin
lua require('themekit').init()

" Open the picker
ThemePicker