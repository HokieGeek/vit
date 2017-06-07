if exists("b:current_syntax")
    finish
endif

syntax match DiffStatLine       "|"
syntax match DiffStatNumLines   "[0-9]\+"
syntax match DiffStatNoSigns    ".* *| *[0-9]\+" contains=DiffStatNumLines,DiffStatLine
syntax match DiffStatPlus       ".* *| *[0-9]\+ +*" contains=DiffStatNoSigns
syntax match DiffStat           ".* *| *[0-9]\+ +*-*" contains=DiffStatPlus
syntax match DiffStatSummary    "[0-9]\+ files\? changed, [0-9]\+ insertions\?(+), [0-9]\+ deletions\?(-)"

highlight DiffStatLine      guifg=#262626 guibg=bg ctermbg=none ctermfg=235      cterm=none
highlight DiffStatNumLines  guifg=#b2b2b2 guibg=bg ctermbg=none ctermfg=249      cterm=none
highlight DiffStatPlus      guifg=#00FF00 guibg=bg ctermbg=none ctermfg=green    cterm=none
highlight DiffStat          guifg=#FF0000 guibg=bg ctermbg=none ctermfg=red      cterm=none
highlight DiffStatSummary   guifg=#5C5C5C guibg=bg ctermbg=none ctermfg=darkgrey cterm=none

" source patch_diff.vim

syntax region VitStashDiffLines  start="@@" end="@@"
syntax match VitStashCommit  "^commit [0-9a-z]*$"
syntax match VitStashSub     "^-.*$"
syntax match VitStashAdd     "^+.*$"
syntax match VitStashInfo    "^diff --git .*"
syntax match VitStashInfo    "^index .*"
syntax match VitStashInfo    "^--- a.*"
syntax match VitStashInfo    "^+++ b.*"

highlight VitStashDiffLines  guifg=#00FFFF guibg=bg ctermbg=none ctermfg=cyan    cterm=none
highlight VitStashCommit     guifg=#FFFF00 guibg=bg ctermbg=none ctermfg=yellow  cterm=none
highlight VitStashSub        guifg=#FF0000 guibg=bg ctermbg=none ctermfg=red     cterm=none
highlight VitStashAdd        guifg=#00FF00 guibg=bg ctermbg=none ctermfg=green   cterm=none
highlight VitStashInfo       guifg=#FFFFFF guibg=bg ctermbg=none ctermfg=white   cterm=bold

let b:current_syntax = "VitStashInfo"
