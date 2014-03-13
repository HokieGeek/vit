if exists("b:current_syntax")
    finish
endif

syntax match VitBlameHash "\v^[\^0-9a-z]{8} "
syntax match VitBlameTime "\v\s[0-9]{4}(-[0-9]{2}){2}\s"
" syntax match VitBlameAuthor "\s([0-9a-zA-Z]?\s"

highlight VitBlameHash ctermbg=none ctermfg=darkred cterm=none
highlight VitBlameTime ctermbg=none ctermfg=cyan cterm=none
" highlight VitBlameAuthor ctermbg=none ctermfg=green cterm=none
highlight CursorLine ctermbg=darkblue ctermfg=white cterm=none

let b:current_syntax = "VitBlame"
