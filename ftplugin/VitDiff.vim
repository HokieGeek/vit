if exists("b:autoloaded_vit_diff") || v:version < 700
    finish
endif
let b:autoloaded_vit_diff = 1
scriptencoding utf-8

setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable

if !exists("b:vit_ref_file") || !exists("b:vit_revision")
    finish
endif

silent! put =vit#ExecuteGit("show ".b:vit_revision.":".b:vit_ref_file)
0d_
setlocal nomodifiable

autocmd BufDelete,BufWipeout <buffer> windo diffoff

windo diffthis
