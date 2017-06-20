if exists("b:patch_diff_syntax")
    finish
endif

syntax region PatchDiffLines  start="@@" end="@@"
syntax match PatchCommit  "^commit [0-9a-z]*$"
syntax match PatchSub     "^-.*$"
syntax match PatchAdd     "^+.*$"
syntax match PatchInfo    "^diff --git .*"
syntax match PatchInfo    "^index .*"
syntax match PatchInfo    "^--- a.*"
syntax match PatchInfo    "^+++ b.*"
syntax match PatchSubmodule     "^Submodule.*"
syntax match PatchSubmoduleLogAdd  "^  > .*"
syntax match PatchSubmoduleLogSub  "^  < .*"

highlight PatchDiffLines        guifg=#00FFFF guibg=bg ctermbg=none ctermfg=cyan    cterm=none
highlight PatchCommit           guifg=#FFFF00 guibg=bg ctermbg=none ctermfg=yellow  cterm=none
highlight PatchSub              guifg=#FF0000 guibg=bg ctermbg=none ctermfg=red     cterm=none
highlight PatchAdd              guifg=#00FF00 guibg=bg ctermbg=none ctermfg=green   cterm=none
highlight PatchInfo             guifg=#FFFFFF guibg=bg ctermbg=none ctermfg=white   cterm=bold
highlight PatchSubmodule        guifg=#FFFFFF guibg=bg ctermbg=none ctermfg=white   cterm=bold
highlight PatchSubmoduleLogAdd  guifg=#00FF00 guibg=bg ctermbg=none ctermfg=green   cterm=none
highlight PatchSubmoduleLogSub  guifg=#FF0000 guibg=bg ctermbg=none ctermfg=red     cterm=none

let b:patch_diff_syntax="loaded"
