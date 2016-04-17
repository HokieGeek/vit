if exists("b:current_syntax")
    finish
endif

syntax match VitCommitComment "^#.*$"

highlight VitCommitComment  guifg=#555555 guibg=bg      ctermbg=none    ctermfg=darkgray    cterm=none

let b:current_syntax = "VitCommit"
