if exists("b:current_syntax")
    finish
endif

syntax match VitLogJustGraph "" contains=VitLogGraph

syntax region VitLogTime    start="([0-9]"  end="ago)"
syntax region VitLogAuthor  start="<"       end=">"
syntax region VitLogBranch  start="- ("     end=")"     contains=VitLogDash

syntax match VitLogHash     "\v^[\* |/\\]*\s[0-9a-z]{7} "   contains=VitLogGraph
syntax match VitLogGraph    "\v^[\* |/\\]*"                 contained
syntax match VitLogDash     "- "                            contained

highlight CursorLine    guifg=NONE    guibg=#262626 ctermbg=235  ctermfg=none       cterm=none
highlight VitLogGraph   guifg=#5C5C5C guibg=bg      ctermbg=none ctermfg=darkgray   cterm=none
highlight VitLogDash    guifg=#FFFFFF guibg=bg      ctermbg=none ctermfg=white      cterm=none
highlight VitLogHash    guifg=#FF0000 guibg=bg      ctermbg=none ctermfg=darkred     cterm=none

if exists("g:vit_log_use_new_colors")
    highlight VitLogTime    guifg=fg guibg=bg      ctermbg=none     ctermfg=148      cterm=none
    highlight VitLogAuthor  guifg=fg guibg=bg      ctermbg=none     ctermfg=61       cterm=none
    highlight VitLogBranch  guifg=fg guibg=bg      ctermbg=none     ctermfg=130      cterm=none
else
    highlight VitLogTime    guifg=#00FFFF guibg=bg      ctermbg=none     ctermfg=cyan        cterm=none
    highlight VitLogAuthor  guifg=#00FF00 guibg=bg      ctermbg=none     ctermfg=green       cterm=none
    highlight VitLogBranch  guifg=#FFFF00 guibg=bg      ctermbg=none     ctermfg=yellow      cterm=none
endif

let b:current_syntax = "VitLog"
