-- Handler mappings: theme_key -> {highlight_groups}
-- Data-driven approach - mappings are separate from handler generation logic

local M = {}

-- Regular highlight group mappings
-- Each theme key maps to one or more Neovim highlight groups
M.regular = {

    -- Syntax: Keywords
    ['attribute'] = {'@attribute'},
    ['keyword'] = {'@keyword', 'Keyword'},
    ['keyword.directive'] = {'@preproc', 'PreProc'},
    ['keyword.function'] = {'@keyword.function'},
    ['keyword.storage'] = {'@keyword.storage', 'StorageClass'},
    ['keyword.storage.type'] = {'@keyword.storage.type', '@type.qualifier'},
    ['keyword.storage.modifier'] = {'@keyword.storage.modifier', '@storageclass'},
    ['keyword.control'] = {'@keyword.control', '@conditional', '@repeat'},
    ['keyword.control.conditional'] = {'@keyword.conditional', '@conditional', 'Conditional'},
    ['keyword.control.repeat'] = {'@keyword.repeat', 'Repeat'},
    ['keyword.control.import'] = {'@keyword.import', '@include', 'Include'},
    ['keyword.control.return'] = {'@keyword.return'},
    ['keyword.control.exception'] = {'@keyword.exception', 'Exception'},
    ['keyword.operator'] = {'@keyword.operator'},

    -- Syntax: Namespace/Punctuation/Operator
    ['namespace'] = {'@namespace', '@module'},
    ['punctuation'] = {'@punctuation'},
    ['punctuation.delimiter'] = {'@punctuation.delimiter'},
    ['punctuation.bracket'] = {'@punctuation.bracket', 'Delimiter'},
    ['punctuation.special'] = {'@punctuation.special'},
    ['operator'] = {'@operator', 'Operator'},
    ['special'] = {'Special', '@character.special'},

    -- Syntax: Variables
    ['variable'] = {'@variable', 'Identifier'},
    ['variable.builtin'] = {'@variable.builtin'},
    ['variable.parameter'] = {'@variable.parameter', '@parameter'},
    ['variable.other'] = {'@variable'},
    ['variable.other.member'] = {'@variable.member', '@property'},
    ['variable.other.member.private'] = {'@variable.member.private'},
    ['property'] = {'@property'},

    -- Syntax: Types
    ['type'] = {'@type', 'Type'},
    ['type.builtin'] = {'@type.builtin'},
    ['type.parameter'] = {'@type.parameter'},
    ['type.enum'] = {'@type.enum', '@lsp.type.enum'},
    ['type.enum.variant'] = {'@type.enum.variant', '@lsp.type.enumMember'},
    ['constructor'] = {'@constructor'},

    -- Syntax: Functions
    ['function'] = {'@function', 'Function'},
    ['function.builtin'] = {'@function.builtin'},
    ['function.method'] = {'@function.method', '@method'},
    ['function.method.private'] = {'@function.method.private'},
    ['function.macro'] = {'@function.macro', 'Macro'},
    ['function.special'] = {'@function.special'},

    -- Syntax: Tags/Labels
    ['tag'] = {'@tag', 'Tag'},
    ['tag.builtin'] = {'@tag.builtin'},
    ['label'] = {'@label', 'Label'},

    -- Syntax: Comments
    ['comment'] = {'@comment', 'Comment'},
    ['comment.line'] = {'@comment.line'},
    ['comment.line.documentation'] = {'@comment.documentation'},
    ['comment.block'] = {'@comment.block'},
    ['comment.block.documentation'] = {'@comment.block.documentation'},
    ['comment.unused'] = {'@comment.unused', 'DiagnosticUnnecessary'},

    -- Syntax: Constants
    ['constant'] = {'@constant', 'Constant'},
    ['constant.builtin'] = {'@constant.builtin'},
    ['constant.builtin.boolean'] = {'@boolean', 'Boolean'},
    ['constant.character'] = {'@character', 'Character'},
    ['constant.character.escape'] = {'@string.escape', 'SpecialChar'},
    ['constant.numeric'] = {'@number', 'Number'},
    ['constant.numeric.integer'] = {'@number.integer', 'Number'},
    ['constant.numeric.float'] = {'@number.float', 'Float'},

    -- Syntax: Strings
    ['string'] = {'@string', 'String'},
    ['string.regexp'] = {'@string.regexp', '@string.regex'},
    ['string.special'] = {'@string.special'},
    ['string.special.url'] = {'@string.special.url', '@text.uri'},
    ['string.special.path'] = {'@string.special.path'},
    ['string.special.symbol'] = {'@string.special.symbol', '@symbol'},

    -- Markup
    ['markup.heading'] = {'@markup.heading', 'Title'},
    ['markup.heading.marker'] = {'@markup.heading.marker'},
    ['markup.heading.1'] = {'@markup.heading.1', 'markdownH1', 'htmlH1'},
    ['markup.heading.2'] = {'@markup.heading.2', 'markdownH2', 'htmlH2'},
    ['markup.heading.3'] = {'@markup.heading.3', 'markdownH3', 'htmlH3'},
    ['markup.heading.4'] = {'@markup.heading.4', 'markdownH4', 'htmlH4'},
    ['markup.heading.5'] = {'@markup.heading.5', 'markdownH5', 'htmlH5'},
    ['markup.heading.6'] = {'@markup.heading.6', 'markdownH6', 'htmlH6'},
    ['markup.bold'] = {'@markup.strong'},
    ['markup.italic'] = {'@markup.italic'},
    ['markup.strikethrough'] = {'@markup.strikethrough'},
    ['markup.link'] = {'@markup.link'},
    ['markup.link.url'] = {'@markup.link.url'},
    ['markup.link.label'] = {'@markup.link.label'},
    ['markup.link.text'] = {'@markup.link.text'},
    ['markup.quote'] = {'@markup.quote', 'markdownBlockquote'},
    ['markup.raw'] = {'@markup.raw'},
    ['markup.raw.block'] = {'@markup.raw.block'},
    ['markup.raw.inline'] = {'@markup.raw.inline'},
    ['markup.list'] = {'@markup.list'},
    ['markup.list.numbered'] = {'@markup.list.numbered'},
    ['markup.list.unnumbered'] = {'@markup.list.unnumbered'},
    ['markup.list.checked'] = {'@markup.list.checked'},
    ['markup.list.unchecked'] = {'@markup.list.unchecked'},

    -- Diff
    ['diff.plus'] = {'GitSignsAdd', 'DiffAdd', '@diff.plus'},
    ['diff.minus'] = {'GitSignsDelete', 'DiffDelete', '@diff.minus'},
    ['diff.delta'] = {'GitSignsChange', 'DiffChange', '@diff.delta'},
    ['diff.delta.moved'] = {'DiffText'},
    ['diff.delta.conflict'] = {'DiffText'},
    ['diff.plus.gutter'] = {'GitSignsAddNr', 'GitSignsAddLn'},
    ['diff.minus.gutter'] = {'GitSignsDeleteNr', 'GitSignsDeleteLn'},
    ['diff.delta.gutter'] = {'GitSignsChangeNr', 'GitSignsChangeLn'},

    -- UI: Background/Gutter/Lines
    ['ui.background'] = {'Normal', 'NormalNC', 'EndOfBuffer', 'SignColumn'},
    ['ui.background.separator'] = {'WinSeparator', 'VertSplit'},
    ['ui.linenr'] = {'LineNr'},
    ['ui.linenr.selected'] = {'CursorLineNr'},
    ['ui.gutter'] = {'SignColumn', 'FoldColumn'},
    ['ui.gutter.selected'] = {'CursorLineSign'},

    -- UI: Statusline
    ['ui.statusline'] = {'StatusLine'},
    ['ui.statusline.inactive'] = {'StatusLineNC'},
    ['ui.statusline.normal'] = {'StatusLineNormal'},
    ['ui.statusline.insert'] = {'StatusLineInsert'},
    ['ui.statusline.select'] = {'StatusLineSelect'},
    ['ui.statusline.separator'] = {'StatusLineSeparator'},

    -- UI: Popup/Menu/Window
    ['ui.popup'] = {'Pmenu', 'NormalFloat'},
    ['ui.popup.info'] = {'FloatBorder', 'FloatTitle'},
    ['ui.window'] = {'WinSeparator'},
    ['ui.help'] = {'HelpCommand'},
    ['ui.text'] = {'Normal'},
    ['ui.text.focus'] = {'PmenuSel'},
    ['ui.text.inactive'] = {'Comment'},
    ['ui.text.info'] = {'MoreMsg'},
    ['ui.text.directory'] = {'Directory'},
    ['ui.menu'] = {'WildMenu', 'Pmenu'},
    ['ui.menu.selected'] = {'PmenuSel'},
    ['ui.menu.scroll'] = {'PmenuSbar'},

    -- UI: Virtual/Inlay
    ['ui.virtual'] = {'NonText'},
    ['ui.virtual.ruler'] = {'ColorColumn'},
    ['ui.virtual.jump-label'] = {'Search'},
    ['ui.virtual.indent-guide'] = {'IndentBlanklineChar', 'IblIndent'},
    ['ui.virtual.inlay-hint'] = {'LspInlayHint'},
    ['ui.virtual.inlay-hint.parameter'] = {'LspInlayHintParameter'},
    ['ui.virtual.inlay-hint.type'] = {'LspInlayHintType'},
    ['ui.virtual.whitespace'] = {'Whitespace'},
    ['ui.virtual.wrap'] = {'NonText'},

    -- UI: Selection/Highlight
    ['ui.selection'] = {'Visual'},
    ['ui.selection.primary'] = {'Visual'},
    ['ui.cursor.match'] = {'MatchParen'},
    ['ui.cursorline'] = {'CursorLine'},
    ['ui.cursorline.primary'] = {'CursorLine'},
    ['ui.cursorline.secondary'] = {'CursorLine'},
    ['ui.cursorcolumn'] = {'CursorColumn'},
    ['ui.cursorcolumn.primary'] = {'CursorColumn'},
    ['ui.cursorcolumn.secondary'] = {'CursorColumn'},
    ['ui.highlight'] = {'Search'},
    ['ui.highlight.frameline'] = {'debugPC'},

    -- UI: Debug
    ['ui.debug'] = {'Debug'},
    ['ui.debug.breakpoint'] = {'debugBreakpoint'},
    ['ui.debug.active'] = {'DapUIPlayPause', 'debugPC'},

    -- UI: Picker
    ['ui.picker.header'] = {'TelescopeTitle'},
    ['ui.picker.header.column'] = {'TelescopePreviewTitle', 'TelescopePromptTitle', 'TelescopeResultsTitle'},
    ['ui.picker.header.column.active'] = {'TelescopeSelection'},

    -- UI: Bufferline
    ['ui.bufferline'] = {'TabLine'},
    ['ui.bufferline.active'] = {'TabLineSel'},
    ['ui.bufferline.background'] = {'TabLineFill'},

    -- Diagnostics
    ['diagnostic'] = {'DiagnosticError', 'DiagnosticWarn', 'DiagnosticInfo', 'DiagnosticHint'},
    ['diagnostic.hint'] = {'DiagnosticHint', 'DiagnosticUnderlineHint'},
    ['diagnostic.info'] = {'DiagnosticInfo', 'DiagnosticUnderlineInfo'},
    ['diagnostic.warning'] = {'DiagnosticWarn', 'DiagnosticUnderlineWarn'},
    ['diagnostic.error'] = {'DiagnosticError', 'DiagnosticUnderlineError'},
    ['diagnostic.unnecessary'] = {'DiagnosticUnnecessary'},
    ['diagnostic.deprecated'] = {'DiagnosticDeprecated'},
    ['warning'] = {'WarningMsg', 'DiagnosticWarn'},
    ['error'] = {'ErrorMsg', 'DiagnosticError'},
    ['info'] = {'DiagnosticInfo'},
    ['hint'] = {'DiagnosticHint'},

    -- Misc
    ['tabstop'] = {'TabLineFill'},

}

-- Cursor highlight group mappings
-- These use buffering and merging before application
M.cursor = {

    ['ui.cursor'] = {'CursorNormal', 'CursorVisual', 'CursorInsert', 'CursorCommand'},
    ['ui.cursor.normal'] = {'CursorNormal'},
    ['ui.cursor.insert'] = {'CursorInsert'},
    ['ui.cursor.select'] = {'CursorVisual'},
    ['ui.cursor.primary'] = {'CursorNormal'},
    ['ui.cursor.primary.normal'] = {'CursorNormal'},
    ['ui.cursor.primary.insert'] = {'CursorInsert'},
    ['ui.cursor.primary.select'] = {'CursorVisual'},

}

return M
