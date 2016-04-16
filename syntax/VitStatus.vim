if exists("b:current_syntax")
    finish
endif

syntax match VitStatusEmpty                 "  Nothing"
syntax match VitStatusColumn2               "^.. "      contains=VitStatusColumn1,VitStatusUntracked,VitStatusUnmerged
syntax match VitStatusColumn1               "\v^."      contained
syntax match VitStatusUntracked             "\v^\?"     contained
syntax match VitStatusUnmerged              "\v^U"      contained
syntax match VitStatusBranch                "## .*"     contains=VitStatusBranchHashes,VitStatusBranchTracking,VitStatusBranchDots,VitStatusBranchRemoteStatus
syntax match VitStatusBranchHashes          "## "       contained
syntax match VitStatusBranchDots            "\.\.\."                    contained
syntax match VitStatusBranchTracking        "\.\.\..*/[a-zA-Z0-9]* "    contained contains=VitStatusBranchDots
syntax match VitStatusBranchAhead           "\vahead [0-9]*\]"  contained contains=VitStatusBranchRemoteStatus
syntax match VitStatusBranchBehind          "\vbehind [0-9]*\]" contained contains=VitStatusBranchRemoteStatus
syntax match VitStatusBranchRemoteStatus    "\[[a-z]* "         contained
syntax match VitStatusBranchRemoteStatus    "\]"                contained

highlight VitStatusEmpty            ctermbg=none ctermfg=darkgrey       cterm=none
highlight VitStatusColumn1          ctermbg=none ctermfg=darkgreen      cterm=none
highlight VitStatusColumn2          ctermbg=none ctermfg=darkred   cterm=none
highlight VitStatusUntracked        ctermbg=none ctermfg=darkred   cterm=none
highlight VitStatusUnmerged         ctermbg=none ctermfg=darkred   cterm=none
highlight VitStatusBranch           ctermbg=none ctermfg=darkgreen cterm=none
highlight VitStatusBranchHashes     ctermbg=none ctermfg=white     cterm=none
highlight VitStatusBranchTracking   ctermbg=none ctermfg=darkred   cterm=none
highlight VitStatusBranchDots       ctermbg=none ctermfg=white     cterm=none
highlight VitStatusBranchAhead          ctermbg=none ctermfg=darkgreen  cterm=none
highlight VitStatusBranchBehind         ctermbg=none ctermfg=darkred    cterm=none
highlight VitStatusBranchRemoteStatus   ctermbg=none ctermfg=white      cterm=none
highlight CursorLine                    ctermbg=235  ctermfg=none       cterm=none

let b:current_syntax = "VitStatus"
