if exists("g:autoloaded_vit_windows") || v:version < 700
    finish
endif
let g:autoloaded_vit_windows = 1
scriptencoding utf-8

function! vit#windows#Diff(file, rev) " {{{
    if isdirectory(a:file)
        echohl WarningMsg
        echomsg "Cannot perform a diff against a directory"
        echohl None
    else
        vnew
        let b:vit = getbufvar(bufnr(a:file), "vit")
        let b:git_revision = a:rev
        setlocal filetype=VitDiff
    endif
endfunction
function! vit#windows#OpenFileAsDiff(file, ...)
    if a:0 > 0
        " End revision
        execute "tabnew ".fnamemodify(a:file, ":p:.")
        if a:0 > 1
            let b:vit_revision = a:2
            setlocal filetype=VitDiff
        endif

        " Start revision
        call vit#windows#Diff(a:file, a:1)
    else
        echohl WarningMsg
        echomsg "No revision specified. Cannot diff file"
        echohl None
    endif
endfunction
function! vit#windows#OpenFilesInRevisionAsDiff(rev)
    let l:first_tab = tabpagenr() + 1

    let l:files = split(system("git diff-tree --no-commit-id --name-status --root -r ".a:rev." | awk '$1 !~ /^D/{ print $2 }'"))
    let l:files = filter(l:files, '!isdirectory(v:val)')

    if len(l:files) > 0
        call map(l:files, 'vit#windows#OpenFileAsDiff(v:val, "'.a:rev.'~1", "'.a:rev.'")')
        execute "tabnext ".l:first_tab
    else
        echohl WarningMsg
        echomsg "There are no files related to the selected revision"
        echohl None
    endif
endfunction " }}}

function! vit#windows#Blame(file) " {{{
    if exists("b:vit") && b:vit.windows.blame < 0
        vnew
        let b:vit = getbufvar(bufnr(a:file), "vit")
        set filetype=VitBlame
        wincmd p
        windo setlocal scrollbind
    endif
endfunction " }}}

function! vit#windows#Log(file, ...) " {{{
    if exists("b:vit")
        if b:vit.windows.log < 0
            new
            if a:0 > 0
                let b:vit_log_args = join(a:000, ' ')
            endif
            let l:bufn = bufnr(a:file)
            if l:bufn >= 0
                let b:vit = getbufvar(l:bufn, "vit")
            endif
            setlocal filetype=VitLog
        else
            call setbufvar(b:vit.windows.log, '&filetype', 'VitLog')
        endif
    endif
endfunction " }}}

function! vit#windows#ShowWindow(rev) " {{{
    let l:bufnr = b:vit.bufnr

    if &lines > 20
        botright new
    else
        botright vnew
    endif
    call vit#windows#Show(a:rev, l:bufnr)
endfunction
function! vit#windows#Show(rev, bufnr)
    let b:vit = getbufvar(a:bufnr, "vit")
    let b:git_revision = len(a:rev) > 0 ? a:rev : b:vit.revision()
    setlocal filetype=VitShow
endfunction " }}}

function! vit#windows#Status() " {{{
    if exists("b:vit")
        if b:vit.windows.status < 0
            let l:winnr = winnr()
            let l:bufnr = b:vit.bufnr
            botright vnew
            let b:vit_parent_win = l:winnr
            let b:vit = getbufvar(l:bufnr, "vit")
            setlocal filetype=VitStatus
        else
            call setbufvar(b:vit.windows.status, '&filetype', 'VitStatus')
        endif
    endif
endfunction " }}}

function! vit#windows#refreshByType(type)
    " call map(vit#utils#getVitBuffersByType(a:type), "vit#windows#afp('".a:type."', winbufnr(v:val))")
    call map(vit#utils#getVitBuffersByType(a:type), "setbufvar(v:val, '&filetype', '".a:type."')")
endfunction

" vim: set foldmethod=marker formatoptions-=tc:
