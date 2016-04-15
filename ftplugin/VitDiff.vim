if exists("b:autoloaded_vit_diff") || v:version < 700
    finish
endif
let b:autoloaded_vit_diff = 1
scriptencoding utf-8

if !exists("b:vit_ref_file") || !exists("b:vit_revision")
    finish
endif

let b:file = vit#GetFilenameRelativeToGit(b:vit_ref_file)
call vit#LoadContent(vit#ExecuteGit("show ".b:vit_revision.":".b:file))
setlocal nomodifiable

windo diffthis
autocmd BufDelete,BufWipeout <buffer> windo diffoff
