if exists("b:current_syntax")
    finish
endif

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
