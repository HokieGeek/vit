if exists("b:current_syntax")
    finish
endif

syntax region VitShowDiffLines  start="@@" end="@@"
syntax match VitShowCommit  "^commit [0-9a-z]*$"
syntax match VitShowSub     "^-.*$"
syntax match VitShowAdd     "^+.*$"
syntax match VitShowInfo    "^diff --git .*"
syntax match VitShowInfo    "^index .*"
syntax match VitShowInfo    "^--- a.*"
syntax match VitShowInfo    "^+++ b.*"

highlight VitShowDiffLines  guifg=#00FFFF guibg=bg ctermbg=none ctermfg=cyan    cterm=none
highlight VitShowCommit     guifg=#FFFF00 guibg=bg ctermbg=none ctermfg=yellow  cterm=none
highlight VitShowSub        guifg=#FF0000 guibg=bg ctermbg=none ctermfg=red     cterm=none
highlight VitShowAdd        guifg=#00FF00 guibg=bg ctermbg=none ctermfg=green   cterm=none
highlight VitShowInfo       guifg=#FFFFFF guibg=bg ctermbg=none ctermfg=white   cterm=bold

let b:current_syntax = "VitShow"
