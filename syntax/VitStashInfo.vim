if exists("b:current_syntax")
    finish
endif

syntax match DiffStatLine       "|"
syntax match DiffStatNumLines   "[0-9]\+"
syntax match DiffStatNoSigns    ".* *| *[0-9]\+" contains=DiffStatNumLines,DiffStatLine
syntax match DiffStatPlus       ".* *| *[0-9]\+ +*" contains=DiffStatNoSigns
syntax match DiffStat           ".* *| *[0-9]\+ +*-*" contains=DiffStatPlus
syntax match DiffStatSummary    "[0-9]\+ files\? changed\(, [0-9]\+ \(inser\|dele\)tions\?([-+])\)\{,2}"

highlight DiffStatLine      guifg=#262626 guibg=bg ctermbg=none ctermfg=235      cterm=none
highlight DiffStatNumLines  guifg=#b2b2b2 guibg=bg ctermbg=none ctermfg=249      cterm=none
highlight DiffStatPlus      guifg=#00FF00 guibg=bg ctermbg=none ctermfg=green    cterm=none
highlight DiffStat          guifg=#FF0000 guibg=bg ctermbg=none ctermfg=red      cterm=none
highlight DiffStatSummary   guifg=#5C5C5C guibg=bg ctermbg=none ctermfg=darkgrey cterm=none

runtime! syntax/patch_diff.vim

let b:current_syntax = "VitStashInfo"
