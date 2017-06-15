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
