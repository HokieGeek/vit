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
    silent! bufdo! edit!|syntax on
endfunction

function! vit#utils#getHunksFromDiff(diff) " {{{
    let l:hunks = []
    let i = len(a:diff)-1
    while i >= 0
        if a:diff[i] =~ "^@@"
            let l:hunkArr = split(substitute(a:diff[i], "[+-]", "", "g"), " ")
            let l:hunk = {}
            let l:hunk["str"] = a:diff[i]
            let l:hunk["before"] = split(l:hunkArr[1], ",")
            let l:hunk["after"] = split(l:hunkArr[2], ",")
            call insert(l:hunks, l:hunk)
        endif
        let i -= 1
    endwhile
    return l:hunks
endfunction " }}}

" vim: set foldmethod=marker formatoptions-=tc:
