if exists("b:autoloaded_vit_diff") || v:version < 700
    finish
endif
let b:autoloaded_vit_diff = 1
scriptencoding utf-8

setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable

if !exists("b:vit_revision")
    finish
endif

let b:vit.windows.diff = bufnr("%")

let b:content = b:vit.execute("show ".b:vit_revision.":".b:vit.name())
silent! put =b:content
0d_
setlocal nomodifiable

autocmd BufDelete,BufWipeout <buffer> windo diffoff | filetype detect

windo diffthis
