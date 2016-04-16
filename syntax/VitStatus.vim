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

highlight VitStatusEmpty                guifg=#5C5C5C guibg=bg      ctermbg=none ctermfg=darkgrey   cterm=none
highlight VitStatusColumn1              guifg=#00FF00 guibg=bg      ctermbg=none ctermfg=darkgreen  cterm=none
highlight VitStatusColumn2              guifg=#FF0000 guibg=bg      ctermbg=none ctermfg=darkred    cterm=none
highlight VitStatusUntracked            guifg=#FF0000 guibg=bg      ctermbg=none ctermfg=darkred    cterm=none
highlight VitStatusUnmerged             guifg=#FF0000 guibg=bg      ctermbg=none ctermfg=darkred    cterm=none
highlight VitStatusBranch               guifg=#00FF00 guibg=bg      ctermbg=none ctermfg=darkgreen  cterm=none
highlight VitStatusBranchHashes         guifg=#FFFFFF guibg=bg      ctermbg=none ctermfg=white      cterm=none
highlight VitStatusBranchTracking       guifg=#FF0000 guibg=bg      ctermbg=none ctermfg=darkred    cterm=none
highlight VitStatusBranchDots           guifg=#FFFFFF guibg=bg      ctermbg=none ctermfg=white      cterm=none
highlight VitStatusBranchAhead          guifg=#00FF00 guibg=bg      ctermbg=none ctermfg=darkgreen  cterm=none
highlight VitStatusBranchBehind         guifg=#FF0000 guibg=bg      ctermbg=none ctermfg=darkred    cterm=none
highlight VitStatusBranchRemoteStatus   guifg=#FFFFFF guibg=bg      ctermbg=none ctermfg=white      cterm=none
highlight CursorLine                    guifg=NONE    guibg=#262626 ctermbg=235  ctermfg=none       cterm=none

let b:current_syntax = "VitStatus"
