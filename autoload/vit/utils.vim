if exists("g:autoloaded_vit_utils") || v:version < 700
    finish
endif
let g:autoloaded_vit_utils = 1

function! vit#utils#getUserInput(message)
    call inputsave()
    let l:response = input(a:message)
    call inputrestore()
    return l:response
endfunction

function! vit#utils#getVitBuffersByType(type)
    let l:vit_buffers = []
    for i in range(tabpagenr('$'))
        call extend(l:vit_buffers, filter(tabpagebuflist(i + 1), 'getbufvar(v:val, "&filetype") == "'.a:type.'"'))
    endfor
    return l:vit_buffers
endfunction

function! vit#utils#reloadBuffers()
    bufdo! edit!|syntax on
endfunction

" vim: set foldmethod=marker formatoptions-=tc:
