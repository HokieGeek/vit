if exists("b:current_syntax")
    finish
endif

" First, color both columns red
" syntax match VitStatusRed    "\v^.. "
"" Color the first one green
" syntax match VitStatusGreen  "\v^."
"" If we have an untracked file
" syntax match VitStatusRed    "\v^\?"
"" ... or an unmerged one
" syntax match VitStatusRed    "\v^U"
"" The branch name
" syntax match VitStatusGreen  "## .*"
"" The hashes next to the branch name
" syntax match VitStatusWhite  "## "
" syntax region VitStatusWhite  start=/\v^\#/ end=/\v^.\#/

" highlight VitStatusRed   ctermbg=none ctermfg=darkred   cterm=none
" highlight VitStatusWhite ctermbg=none ctermfg=white     cterm=none
" highlight VitStatusGreen ctermbg=none ctermfg=darkgreen cterm=none

let b:current_syntax = "VitStatus"
