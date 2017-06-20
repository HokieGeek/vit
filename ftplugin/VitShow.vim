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

    function! GetFileFromDiffLine(line) " {{{
        if a:line =~ "--cc"
            let l:file = substitute(a:line, '^diff\s*--cc\s*', '', '')
        else
            let l:file = substitute(a:line, '.* b/\(.*\)$', '\1', '')
        endif
        return l:file
    endfunction " }}}

    function! s:GetFileUnderCursor() " {{{
        let l:currline = line(".")
        if getline(".") !~ "^diff"
            let l:last_wrapscan = &wrapscan
            setlocal nowrapscan
            execute "silent! normal! ?diff\<cr>"
            if l:last_wrapscan == 1
                setlocal wrapscan
            endif
        endif
        let l:file = GetFileFromDiffLine(getline("."))
        execute l:currline
        return l:file
    endfunction " }}}

    function! s:OpenFilesFromShow() " {{{
        let l:showfiles = map(filter(getline(1, "$"), 'v:val =~ "^diff"'), 'fnamemodify(GetFileFromDiffLine(v:val), ":p:.")')
        let l:showfiles = map(l:showfiles, 'v:val.":1:".substitute(split(b:vit.repo.execute("show --stat '.b:git_revision.' -- ".v:val), "\n")[6], " *".v:val."[^|]*| *", "", "")')

        tabnew
        lexpr l:showfiles
        lwindow
    endfunction " }}}

    function! s:Git(...) " {{{
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

    function! GetVitShowStatusLine() " {{{
        let l:summary=""
        if exists("b:git_revision")
            let l:summary=split(b:vit.repo.execute("show --oneline --shortstat --no-color ".b:git_revision), "\n")[-1]
        endif
        return l:summary."%=%l/%L"
    endfunction
    setlocal statusline=%!GetVitShowStatusLine()
    " }}}

    " Maps and autocmds " {{{
    autocmd WinEnter,WinLeave,BufEnter <buffer> setlocal statusline=%!GetVitShowStatusLine()

    nnoremap <buffer> <silent> d :call vit#windows#OpenFileAsDiff(<SID>GetFileUnderCursor(), b:git_revision."~1", b:git_revision)<cr>
    nnoremap <buffer> <silent> D :call vit#windows#OpenFilesInRevisionAsDiff(b:git_revision)<cr>

    nnoremap <buffer> <silent> o :execute "tabedit ".fnamemodify(<SID>GetFileUnderCursor(), ":p:.")<cr>
    nnoremap <buffer> <silent> O :call <SID>OpenFilesFromShow()<cr>

    nnoremap <buffer> <silent> t :call <SID>VitShowToggleView(!exists("b:vit_show_full"))<cr>
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

" vim: set foldmethod=marker formatoptions-=tc:
