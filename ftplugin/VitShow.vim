if v:version < 700
    finish
endif
scriptencoding utf-8

if b:vit.windows.show != bufnr("%")
    let b:vit.windows.show = bufnr("%")

    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nolist nocursorline nonumber
    if exists("&relativenumber")
        setlocal norelativenumber
    endif

    function! GetFileFromDiffLine(line)
        if a:line =~ "--cc"
            let l:file = substitute(a:line, '^diff\s*--cc\s*', '', '')
        else
            let l:file = substitute(a:line, '.* b/\(.*\)$', '\1', '')
        endif
        return l:file
    endfunction

    function! s:GetFileUnderCursor()
        return GetFileFromDiffLine(getline(search("^diff", "bcnW")))
    endfunction

    function! s:OpenFilesFromShow()
        let l:rev = b:git_revision
        let l:showfiles = map(filter(getline(1, "$"), 'v:val =~ "^diff"'), 'fnamemodify(GetFileFromDiffLine(v:val), ":p:.")')

        tabnew
        let l:diffs = []
        for f in l:showfiles
            let l:hunks = vit#utils#getHunksFromDiff(vit#commands#fileDiffAsList(f, l:rev."~1..".l:rev))
            call extend(l:diffs, map(l:hunks, '"'.f.':".v:val.after[0].":".v:val.str'))
        endfor
        lexpr l:diffs
        lwindow
    endfunction

    function! s:Git(...)
        " echomsg "VitShow#Git(".string(a:000).")"
        if a:0 > 0
            if a:1 ==# "reset"
                call vit#commands#Reset(join(a:000[1:], ' '). " ".GetRevFromBlame())
            else
                call vit#config#git(join(a:000, ' '))
            endif
        else
            call vit#config#git()
        endif
    endfunction
    command! -bar -buffer -complete=customlist,vit#config#gitCompletion -nargs=* Git :call <SID>Git(<f-args>)
    " }}}

    if !exists("*VitShowToggleView") " {{{
        function! s:VitShowToggleView(full)
            setlocal filetype=VitShow
            let l:rev = b:git_revision
            let l:vit = b:vit
            enew
            if a:full
                let b:vit_show_full=1
            endif
            let b:vit = l:vit
            call vit#windows#Show(l:rev, b:vit.bufnr)
        endfunction
    endif " }}}

    function! GetVitShowStatusLine()
        let l:summary=""
        if exists("b:git_revision")
            let l:summary=split(b:vit.repo.execute("show --oneline --shortstat --no-color ".b:git_revision), "\n")[-1]
        endif
        return l:summary."%=%l/%L"
    endfunction
    setlocal statusline=%!GetVitShowStatusLine()
    " }}}

    function! s:navigate(target, dir, count)
        let l:pat = a:target == "hunk" ? "^@@ " : "^diff "
        if a:count == -1
            call cursor(a:dir == "-" ? 1 : line("$"), 1)
            call search(l:pat, (a:dir == "-" ? "" : "b"))
        else
            let l:c = a:count == 0 ? 1 : a:count
            while l:c > 0
                call search(l:pat, (a:dir == "-" ? "b" : ""))
                let l:c -= 1
            endwhile
        endif
        call feedkeys('z.')
    endfunction

    " Maps and autocmds " {{{
    autocmd WinEnter,WinLeave,BufEnter <buffer> setlocal statusline=%!GetVitShowStatusLine()

    nnoremap <buffer> <silent> d :call vit#windows#OpenFileAsDiff(<SID>GetFileUnderCursor(), b:git_revision."~1", b:git_revision)<cr>
    nnoremap <buffer> <silent> D :call vit#windows#OpenFilesInRevisionAsDiff(b:git_revision)<cr>

    nnoremap <buffer> <silent> o :execute "tabedit ".fnamemodify(<SID>GetFileUnderCursor(), ":p:.")<cr>
    nnoremap <buffer> <silent> O :call <SID>OpenFilesFromShow()<cr>

    nnoremap <buffer> <silent> t :call <SID>VitShowToggleView(!exists("b:vit_show_full"))<cr>

    nnoremap <buffer> <silent> ]h :<C-U>call <SID>navigate("hunk", "+", v:count)<cr>
    nnoremap <buffer> <silent> [h :<C-U>call <SID>navigate("hunk", "-", v:count)<cr>
    nnoremap <buffer> <silent> ]H :<C-U>call <SID>navigate("hunk", "+", -1)<cr>
    nnoremap <buffer> <silent> [H :<C-U>call <SID>navigate("hunk", "-", -1)<cr>

    nnoremap <buffer> <silent> ]f :<C-U>call <SID>navigate("file", "+", v:count)<cr>
    nnoremap <buffer> <silent> [f :<C-U>call <SID>navigate("file", "-", v:count)<cr>
    nnoremap <buffer> <silent> ]F :<C-U>call <SID>navigate("file", "+", -1)<cr>
    nnoremap <buffer> <silent> [F :<C-U>call <SID>navigate("file", "-", -1)<cr>
    " }}}
endif

if exists("b:git_revision")
    let b:vit_show_cmd = "show --submodule=log ".b:git_revision
    if !exists("b:vit_show_full")
        let b:vit_show_cmd .= " ".fnamemodify(b:vit.path.absolute, ":.")
    endif
    let b:vit_content = b:vit.repo.execute(b:vit_show_cmd)
else
    let b:vit_content = "No revision given"
endif

setlocal modifiable
silent! 1,$d
silent! put=b:vit_content
0d_
setlocal nomodifiable

if exists("b:git_revision")
    execute "silent! file Show\ ".b:git_revision
endif

" vim:set formatoptions-=tc foldmethod=expr foldexpr=getline(v\:lnum)=~#'^\s*fu[nction]*'?'a1'\:getline(v\:lnum)=~#'^\s*endf[unction]*'?'s1'\:'=':
