if exists("g:loaded_vit") || v:version < 700
    finish
endif
let g:loaded_vit = 1

" Determine if we have a git executable
if !executable("git")
    finish
endif

function! s:VitInit()
    if exists("b:vit_initialized")
        return
    endif
    let b:vit_initialized = 1

    call vit#config#buffer(expand("%"))
endfunction

autocmd BufWinEnter * call <SID>VitInit()

" vim: set foldmethod=marker formatoptions-=tc:
