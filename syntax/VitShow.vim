if exists("b:current_syntax")
    finish
endif

runtime! syntax/patch_diff.vim

syntax match VitShowSubmodule     "^Submodule.*"
syntax match VitShowSubmoduleLog  "^  > .*"

highlight VitShowSubmodule       guifg=#FFFFFF guibg=bg ctermbg=none ctermfg=white cterm=bold
highlight VitShowSubmoduleLog    guifg=#00FF00 guibg=bg ctermbg=none ctermfg=green cterm=none

let b:current_syntax = "VitShow"
