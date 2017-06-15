if v:version < 700
    finish
endif
scriptencoding utf-8

function! vit#utils#getUserInput(message)
    call inputsave()
    let l:response = input(a:message)
    call inputrestore()
    return l:response
endfunction
