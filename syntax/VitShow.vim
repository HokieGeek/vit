if exists("b:current_syntax")
    finish
endif

syntax match VitShowCommit "^commit [0-9a-z]*$"
syntax region VitShowDiffLines start="@@" end="@@"
syntax match VitShowSub "^-.*$"
syntax match VitShowAdd "^+.*$"
syntax match VitShowInfo "^diff --git .*"
syntax match VitShowInfo "^index .*"
syntax match VitShowInfo "^--- a.*"
syntax match VitShowInfo "^+++ b.*"

highlight VitShowCommit ctermbg=none ctermfg=yellow cterm=none
highlight VitShowDiffLines ctermbg=none ctermfg=cyan cterm=none
highlight VitShowSub ctermbg=none ctermfg=red cterm=none
highlight VitShowAdd ctermbg=none ctermfg=green cterm=none
highlight VitShowInfo ctermbg=none ctermfg=white cterm=bold

let b:current_syntax = "VitShow"
