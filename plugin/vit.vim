if exists("g:loaded_vit") || v:version < 700
    finish
endif
let g:loaded_vit = 1

function! VitInit()
    if exists("b:vit_initialized")
        return
    endif
    let b:vit_initialized = 1

    " Determine if we have a git executable
    if !executable("git")
        return
    endif

    call vit#ConfigureBuffer(expand("%"))
    " call vit#RefreshStatuses()
endfunction

function! vit#Statusline()
    return vit#StatuslineGet()
endfunction

autocmd BufWinEnter * call VitInit()

" vim: set foldmethod=marker formatoptions-=tc:
