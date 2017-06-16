if exists("g:autoloaded_vit_gutter") || v:version < 700
    finish
endif
let g:autoloaded_vit_gutter = 1

function! vit#gutter#define()
    highlight VitSignSub guifg=#FF0000 guibg=bg ctermbg=none ctermfg=red   cterm=none
    highlight VitSignAdd guifg=#00FF00 guibg=bg ctermbg=none ctermfg=green cterm=none
    highlight VitSignMod guifg=#FFFF00 guibg=bg ctermbg=none ctermfg=yellow  cterm=none

    sign define vitadd text=+ texthl=VitSignAdd
    sign define vitsub text=_ texthl=VitSignSub
    sign define vitmod text=△ texthl=VitSignMod

    let g:vit_gutter_signs_defined = 0
endfunction

function! s:place(bufnr, startline, range, type)
    let i = 0
    while i < a:range
        let l:line = a:startline+i
        execute "sign place ".s:vit_sign_cnt." line=".l:line." name=".a:type." buffer=".a:bufnr
        let s:vit_sign_cnt += 1
        let i += 1
    endwhile
endfunction

function! s:breakupPos(hunkPos)
    return split(substitute(a:hunkPos, "[+-]", "", "g"), ",")
endfunction

function! s:analyzeHunk(hunk)
    let l:hunkArr = split(a:hunk, " ")
    return [s:breakupPos(l:hunkArr[1]), s:breakupPos(l:hunkArr[2])]
endfunction

function! vit#gutter#processDiff(diff, bufnr)
    execute "sign unplace * buffer=".a:bufnr
    let s:vit_sign_cnt = 1

    let i = 0
    while i < len(a:diff)
        if a:diff[i][0] == "@"
            let l:hunkInfo = s:analyzeHunk(a:diff[i])
            " echo l:hunkInfo

            if len(l:hunkInfo[0]) == 1 && len(l:hunkInfo[1]) == 1
                call s:place(a:bufnr, l:hunkInfo[1][0], 1, "vitmod")
            endif

            if len(l:hunkInfo[0]) > 1 && l:hunkInfo[0][1] != 0
                call s:place(a:bufnr, l:hunkInfo[1][0]-1, 1, "vitsub")
            endif

            if len(l:hunkInfo[1]) > 1 && l:hunkInfo[1][1] > 0
                call s:place(a:bufnr, l:hunkInfo[1][0], l:hunkInfo[1][1], "vitadd")
            elseif len(l:hunkInfo[0]) > 1 && len(l:hunkInfo[1]) == 1 && l:hunkInfo[0][1] == 0
                call s:place(a:bufnr, l:hunkInfo[1][0], 1, "vitadd")
            endif
        endif
        let i += 1
    endwhile
    unlet s:vit_sign_cnt
endfunction

function! vit#gutter#test()
    if !exists("g:vit_gutter_signs_defined")
        call vit#gutter#define()
    endif
    let l:diff = split(b:vit.execute("diff-index --unified=0 --no-color HEAD -- ".b:vit.path.relative), "\n")
    call vit#gutter#processDiff(l:diff, b:vit.bufnr)
endfunction
