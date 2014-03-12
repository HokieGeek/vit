if exists("b:current_syntax")
    finish
endif

syntax match VitStatusColumn2    "^.. " contains=VitStatusColumn1,VitStatusUntracked,VitStatusUnmerged
syntax match VitStatusColumn1  "\v^." contained
syntax match VitStatusUntracked    "\v^\?" contained
syntax match VitStatusUnmerged    "\v^U" contained
syntax match VitStatusBranch  "## .*" contains=VitStatusBranchHashes,VitStatusBranchTracking,VitStatusBranchDots
syntax match VitStatusBranchHashes  "## " contained
syntax match VitStatusBranchTracking  "\.\.\..*" contained contains=VitStatusBranchDots
syntax match VitStatusBranchDots  "\.\.\." contained

highlight VitStatusColumn1          ctermbg=none ctermfg=darkgreen   cterm=none
highlight VitStatusColumn2          ctermbg=none ctermfg=darkred   cterm=none
highlight VitStatusUntracked        ctermbg=none ctermfg=darkred   cterm=none
highlight VitStatusUnmerged         ctermbg=none ctermfg=darkred   cterm=none
highlight VitStatusBranch           ctermbg=none ctermfg=darkgreen cterm=none
highlight VitStatusBranchHashes     ctermbg=none ctermfg=white     cterm=none
highlight VitStatusBranchTracking   ctermbg=none ctermfg=darkred   cterm=none
highlight VitStatusBranchDots       ctermbg=none ctermfg=white     cterm=none

let b:current_syntax = "VitStatus"
