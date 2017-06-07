if exists("b:current_syntax")
    finish
endif

syntax match VitStashIdNum "{[0-9]\+}"
syntax match VitStashId "^stash@{[0-9]\+}" contains=VitStashIdNum
syntax match VitStashColon ":"
syntax match VitStashOn "(WIP o|O)n"
" syntax match VitStashBranch "(WIP o|O)n [^: \t]*:" contains=VitStashOn
syntax match VitStashBranch " [^: \t]*:" contains=VitStashColon

highlight VitStashId        guifg=#FFFFFF guibg=bg      ctermbg=none ctermfg=white      cterm=none
highlight VitStashIdNum     guifg=#FFFFFF guibg=bg      ctermbg=none ctermfg=white      cterm=bold
highlight VitStashBranch    guifg=#FFFFFF guibg=bg      ctermbg=none ctermfg=yellow     cterm=none

highlight CursorLine    guifg=NONE    guibg=#262626 ctermbg=237  ctermfg=none       cterm=none

let b:current_syntax = "VitStash"
