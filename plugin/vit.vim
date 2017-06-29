if exists("g:loaded_vit") || v:version < 700
    finish
endif
let g:loaded_vit = 1

" Determine if we have a git executable
if executable("git")
    autocmd BufWinEnter *
        \ if !exists("b:vit") |
        \        call vit#config#buffer(expand("%")) |
        \ endif
endif

" vim:set formatoptions-=tc foldmethod=expr foldexpr=getline(v\:lnum)=~#'^\s*fu[nction]*'?'a1'\:getline(v\:lnum)=~#'^\s*endf[unction]*'?'s1'\:'=':
