if exists("b:current_syntax")
    finish
endif

highlight CursorLine    guifg=NONE    guibg=#262626 ctermbg=235  ctermfg=none       cterm=none

let b:current_syntax = "VitStash"
