if exists("b:current_syntax")
    finish
endif

" syntax match VitBlameFile "\v[\^0-9a-f]{7,} [a-zA-Z\._\-]+ "
syntax match VitBlameHash "\v[\^0-9a-f]{7,} "
syntax match VitBlameTime "\v\s[0-9]{4}(-[0-9]{2}){2}\s"

highlight CursorLine    ctermbg=235     ctermfg=none        cterm=none
highlight VitBlameHash  ctermbg=none    ctermfg=darkred     cterm=none
" highlight VitBlameFile  ctermbg=none    ctermfg=darkgrey     cterm=none

if exists("g:vit_log_use_new_colors")
    highlight VitBlameTime  ctermbg=none    ctermfg=148         cterm=none
else
    highlight VitBlameTime  ctermbg=none    ctermfg=cyan        cterm=none
endif

let b:current_syntax = "VitBlame"
