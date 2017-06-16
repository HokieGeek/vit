if exists("g:autoloaded_vit_gutter") || v:version < 700
    finish
endif
let g:autoloaded_vit_gutter = 1

function! vit#gutter#define()
    highlight VitSignSub guifg=#FF0000 guibg=bg ctermbg=none ctermfg=red   cterm=none
    highlight VitSignAdd guifg=#00FF00 guibg=bg ctermbg=none ctermfg=green cterm=none
    highlight VitSignMod guifg=#0000FF guibg=bg ctermbg=none ctermfg=blue  cterm=none

    sign define vitadd text=+ texthl=VitSignAdd
    sign define vitsub text=_ texthl=VitSignSub
    sign define vitmod text=∆ texthl=VitSignMod
endfunction

function! s:place(line, type)
    execute "sign place ".b:signCnt." line=".a:line." name=".a:type." file=".b:vit.path.absolute
    let b:signCnt += 1
endfunction

function! s:breakupPos(hunkPos)
    let hunks = split(substitute(a:hunkPos, "[+-]", "", "g"), ",")
    " if len(hunks) == 1
    "     call add(hunks, 0)
    " endif
    return hunks
endfunction

function! s:analyzeHunk(hunk)
    let l:hunkArr = split(a:hunk, " ")
    return [s:breakupPos(l:hunkArr[1]), s:breakupPos(l:hunkArr[2])]
endfunction

function! vit#gutter#processDiff(diff)
    let i = 0
    while i < len(a:diff)
        if a:diff[i][0] == "@"
            let l:hunkInfo = s:analyzeHunk(a:diff[i])
            echo l:hunkInfo

            if len(l:hunkInfo[0]) == 1 && len(l:hunkInfo[1]) == 1
                call s:place(l:hunkInfo[1][0], "vitmod")
            endif

            " @@ -4,0 +5,2 @@ asdf asdfasdf asdfa sdf adfaf asdf asdfasd f asfas
            " +
            " +qeqwerqwer qwreqwe r
            " @@ -7,2 +9 @@ asdf asdfasdf asdfa sdf adfaf asdf asdfasd f asfas
            " -asdf asdfasdf asdfa sdf adfaf asdf asdfasd f asfas
            " -as
            " +asdf asasdf aasdf
            " @@ -13 +14 @@ asdf asdfasdf asdfa sdf adfaf asdf asdfasd f asfas
            " -asdf asdfasdf asdfa sdf adfaf asdf asdfasd f asfas
            " +asdf asdfasdf quer sdf adfaf asdf asdfasd f asfas


            " @@ -7,2 +7,3 @@
            " @@ -28,2 +26,0 @@
            " @@ -22,3 +23,0 @@
            if len(l:hunkInfo[0]) > 1 && l:hunkInfo[0][1] != 0
                call s:place(l:hunkInfo[1][0]-1, "vitsub")
            endif

            " @@ -16,0 +18 @@
            " @@ -7,2 +7,3 @@
            " @@ -30,0 +28,2 @@
            if len(l:hunkInfo[1]) > 1 && l:hunkInfo[1][1] > 0
                let j = 0
                while j < l:hunkInfo[1][1]
                    call s:place(l:hunkInfo[1][0]+j, "vitadd")
                    let j += 1
                endwhile
            endif
        endif
        let i += 1
    endwhile
endfunction

function! vit#gutter#test()
    let b:signCnt = 1 " TODO
    call vit#gutter#define()
    let l:diff = split(b:vit.execute("diff-index --unified=0 --no-color HEAD -- ".b:vit.path.relative), "\n")
    call vit#gutter#processDiff(l:diff)
endfunction
