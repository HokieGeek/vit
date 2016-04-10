if exists("b:current_syntax")
    finish
endif

syntax region VitLogTime    start="([0-9]"  end="ago)"
syntax region VitLogAuthor  start="<"       end=">"
syntax region VitLogBranch  start="- ("     end=")"

syntax match VitLogHash     "\v^[\* |/\\]*\s[0-9a-z]{7} "   contains=VitLogGraph
syntax match VitLogGraph    "\v^[\* |/\\]*"                 contained

highlight VitLogHash    ctermbg=none        ctermfg=darkred     cterm=none
highlight VitLogTime    ctermbg=none        ctermfg=cyan        cterm=none
highlight VitLogAuthor  ctermbg=none        ctermfg=green       cterm=none
highlight VitLogBranch  ctermbg=none        ctermfg=yellow      cterm=none
highlight VitLogGraph   ctermbg=none        ctermfg=darkgray    cterm=none
highlight CursorLine    ctermbg=darkblue    ctermfg=white       cterm=none

let b:current_syntax = "VitLog"
