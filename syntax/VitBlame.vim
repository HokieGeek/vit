if exists("b:current_syntax")
    finish
endif

setlocal conceallevel=3 concealcursor=n
setlocal listchars="extends:space"

syntax match VitBlameHash "\v[\^0-9a-f]{7,} "
syntax match VitBlameTime "\v\s[0-9]{4}(-[0-9]{2}){2}\s"
syntax match VitBlameDaRest "\v\s*[0-9]*\).*$" conceal

highlight CursorLine    guifg=NONE    guibg=#262626 ctermbg=235     ctermfg=none       cterm=none
highlight VitBlameHash  guifg=#FF0000 guibg=bg      ctermbg=none    ctermfg=darkred    cterm=none

if exists("g:vit_log_use_new_colors")
    highlight VitBlameTime  guifg=fg  guibg=bg  ctermbg=none  ctermfg=148  cterm=none
else
    highlight VitBlameTime  guifg=#00FFFF  guibg=bg  ctermbg=none  ctermfg=cyan  cterm=none
endif

let b:current_syntax = "VitBlame"
