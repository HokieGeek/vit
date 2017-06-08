if exists("b:current_syntax")
    finish
endif

runtime! syntax/patch_diff.vim

let b:current_syntax = "VitShow"
