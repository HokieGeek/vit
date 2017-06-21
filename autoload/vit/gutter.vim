if exists("g:autoloaded_vit_gutter") || v:version < 700
    finish
endif
let g:autoloaded_vit_gutter = 1

function! vit#gutter#config() " {{{
    if !exists("g:vit_gutter_signs_defined")
        call <SID>defineSigns()
    endif

    command! -bar -buffer GitGutterToggle :call <SID>toggle()

    augroup VitGutter
        autocmd!
        autocmd BufWritePost,BufReadPost <buffer> call <SID>update()
        autocmd FileType Vit* call <SID>remove()
    augroup END

    nnoremap <buffer> <silent> ]g :<C-U>call <SID>jumpHunks(bufnr("%"), v:count, "+")<cr>
    nnoremap <buffer> <silent> [g :<C-U>call <SID>jumpHunks(bufnr("%"), v:count, "-")<cr>
    nnoremap <buffer> <silent> ]G :call <SID>jumpHunks(bufnr("%"), -1, "+")<cr>
    nnoremap <buffer> <silent> [G :call <SID>jumpHunks(bufnr("%"), -1, "-")<cr>

    call s:update()

    let b:vit_gutter_enabled = 1
endfunction " }}}

function! s:defineHighlights() " {{{
    highlight VitSignSub guifg=#FF0000 guibg=bg ctermbg=none ctermfg=red   cterm=none
    highlight VitSignAdd guifg=#00FF00 guibg=bg ctermbg=none ctermfg=green cterm=none
    highlight VitSignMod guifg=#FFFF00 guibg=bg ctermbg=none ctermfg=yellow  cterm=none
endfunction " }}}

function! s:defineSigns() " {{{
    sign define vitadd text=+ texthl=VitSignAdd
    sign define vitsub text=_ texthl=VitSignSub
    sign define vitmod text=» texthl=VitSignMod
    let g:vit_gutter_signs_defined = 0
endfunction " }}}

function! s:getSignId(line, type) " {{{
    let l:id = a:line
    if a:type == "vitadd"
        let l:id .= "001"
    elseif a:type == "vitsub"
        let l:id .= "002"
    elseif a:type == "vitmod"
        let l:id .= "003"
    endif
    return l:id
endfunction " }}}

function! s:place(bufnr, startline, range, type) " {{{
    let i = 0
    while i < a:range
        let l:line = a:startline+i
        let l:id = s:getSignId(l:line, a:type)
        let b:vit.signs[l:line] = l:id
        execute "sign place ".l:id." line=".l:line." name=".a:type." buffer=".a:bufnr
        let i += 1
    endwhile
endfunction " }}}

function! s:breakupPos(hunkPos) " {{{
    return split(substitute(a:hunkPos, "[+-]", "", "g"), ",")
endfunction " }}}

function! s:analyzeHunk(hunk) " {{{
    let l:hunkArr = split(a:hunk, " ")
    return [s:breakupPos(l:hunkArr[1]), s:breakupPos(l:hunkArr[2])]
endfunction " }}}

function! s:getHunksFromDiff(diff) " {{{
    let l:hunks = []
    let i = 0
    while i < len(a:diff)
        if a:diff[i][0] == "@"
            call add(l:hunks, s:analyzeHunk(a:diff[i]))
        endif
        let i += 1
    endwhile
    return l:hunks
endfunction " }}}

function! s:processDiff(diff, bufnr) " {{{
    execute "sign unplace * buffer=".a:bufnr
    if exists("b:vit.signs")
        unlet! b:vit["signs"]
    endif
    let b:vit["signs"] = {}

    for hunkInfo in s:getHunksFromDiff(a:diff)
        if len(hunkInfo[0]) == 1 && len(hunkInfo[1]) == 1
            call s:place(a:bufnr, hunkInfo[1][0], 1, "vitmod")
        endif

        if len(hunkInfo[0]) > 1 && hunkInfo[0][1] != 0
            call s:place(a:bufnr, hunkInfo[1][0]-1, 1, "vitsub")
        endif

        if len(hunkInfo[1]) > 1 && hunkInfo[1][1] > 0
            call s:place(a:bufnr, hunkInfo[1][0], hunkInfo[1][1], "vitadd")
        elseif len(hunkInfo[0]) > 1 && len(hunkInfo[1]) == 1 && hunkInfo[0][1] == 0
            call s:place(a:bufnr, hunkInfo[1][0], 1, "vitadd")
        endif
    endfor
endfunction " }}}

function! s:update() " {{{
    call <SID>defineHighlights()
    let l:diff = split(b:vit.repo.execute("diff-index --unified=0 --no-color --diff-algorithm=minimal HEAD -- ".b:vit.path.absolute), "\n")
    call s:processDiff(l:diff, b:vit.bufnr)
endfunction " }}}

function! s:remove() " {{{
    if exists("b:vit_gutter_enabled")
        unlet! b:vit_gutter_enabled
        execute "sign unplace * buffer=".bufnr("%")
        autocmd! VitGutter
        nunmap <buffer> <silent> ]g
        nunmap <buffer> <silent> [g
        nunmap <buffer> <silent> ]G
        nunmap <buffer> <silent> [G
    endif
endfunction " }}}

function! s:toggle() " {{{
    if exists("b:vit_gutter_enabled")
        call s:remove()
    else
        call vit#gutter#config()
    endif
endfunction " }}}

function! s:jumpHunks(bufnr, count, dir) " {{{
    if !exists("b:vit.signs")
        return
    endif

    if a:dir == "+"
        let l:list = sort(filter(keys(b:vit.signs), 'v:val > '.line(".")), "s:signListComparatorAsc")
    elseif a:dir == "-"
        let l:list = sort(filter(keys(b:vit.signs), 'v:val < '.line(".")), "s:signListComparatorDesc")
    else
        return
    endif

    if a:count < 0
        let l:next = l:list[len(l:list)-1]
    else
        let l:next = l:list[a:count >= len(l:list) ? len(l:list)-1 : a:count]
    endif

    execute "sign jump ".b:vit.signs[l:next]." buffer=".a:bufnr
endfunction

function! s:signListComparatorAsc(first, second)
    return a:first - a:second
endfunction

function! s:signListComparatorDesc(first, second)
    return a:first == a:second ? 0 : a:first - a:second < 0 ? 1 : -1
endfunction " }}}

" vim: set foldmethod=marker formatoptions-=tc:
