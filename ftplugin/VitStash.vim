if exists("b:autoloaded_vit_stash") || v:version < 700
    finish
endif
let b:autoloaded_vit_stash = 1
scriptencoding utf-8

let content="STASH VIEWER HERE"
silent! put=content
0d_

" vit#Stash("list")
" git stash show -p stash@\{0\}
"
botright new
wincmd t
