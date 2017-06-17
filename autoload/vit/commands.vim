if exists("g:autoloaded_vit_commands") || v:version < 700
    finish
endif
let g:autoloaded_vit_commands = 1

function! vit#commands#Add(files) " {{{
    let l:files = join(split(a:files), ' ')
    call b:vit.execute("add ".l:files)
    if v:shell_error == 0
        echo "Added ".a:files." to the stage"
        call vit#windows#refreshByType("VitStatus")
    else
        echo "Unable to add ".a:files." to the stage"
    endif
endfunction " }}}

function! vit#commands#Commit(args) " {{{
    let l:currFileStatus = b:vit.status()
    if l:currFileStatus == 2 || l:currFileStatus == 3
        if confirm("Current file not staged. Add it?", "Y\nn", 1) == 1
            call vit#commands#Add(b:vit.reffile)
        endif
    endif

    " I really hate having to enter the author every freaking time
    let l:args = a:args
    if strlen(a:args) > 0 && match(a:args, "--author=") > -1
        let l:args_list = split(l:args)
        let l:author = l:args_list[match(l:args_list, "--author=")]
        if l:author == "--author=''"
            let l:args = substitute(l:args, "--author=''", "", "")
            unlet! b:vit_commit_author
        else
            let b:vit_commit_author = l:author
        endif
    elseif exists("b:vit_commit_author")
        let l:args .= " ".b:vit_commit_author
    endif

    " If a message was already entered, just commit
    if match(l:args, " *-m ") > -1 || match(l:args, " *--message=") > -1
        call vit#commands#PerformCommit(l:args)
    else " otherwise, open a window to enter the message
        botright new
        let b:vit_commit_args = a:args
        set filetype=VitCommit
    endif
endfunction
function! vit#commands#PerformCommit(args)
    call b:vit.execute("commit ".a:args)
    echomsg "Successfully committed"
    call vit#windows#refreshByType("VitStatus")
    call vit#windows#refreshByType("VitLog")
    call vit#utils#reloadBuffers()
endfunction " }}}

function! vit#commands#Reset(args) " {{{
    call b:vit.execute("reset ".a:args)
    call vit#windows#refreshByType("VitStatus")
    call vit#windows#refreshByType("VitLog")
endfunction
function! vit#commands#ResetFilesInGitIndex(opts, files)
    let l:files = join(split(a:files), ' ')
    call vit#commands#Reset(a:opts." -- ".l:files)
endfunction
function! vit#commands#Unstage(files)
    call vit#commands#ResetFilesInGitIndex("HEAD", a:files)
    echomsg "Unstaged ".a:files
endfunction " }}}

function! vit#commands#Checkout(args) " {{{
    call b:vit.execute("checkout ".a:args)
    call vit#windows#refreshByType("VitStatus")
    call vit#windows#refreshByType("VitLog")
endfunction
function! vit#commands#CheckoutCurrentFile(rev)
    let l:file = expand("%:p")
    call vit#commands#Checkout(a:rev, l:file)
    edit l:file
endfunction " }}}

function! vit#commands#Stash(args) " {{{
    let l:out = b:vit.execute("stash ".a:args)
    if a:args != "list"
        call vit#windows#refreshByType("VitStatus")
        call vit#windows#refreshByType("VitLog")
        call vit#utils#reloadBuffers()
    endif
    return l:out
endfunction
function! vit#commands#StashViewer()
    tabnew
    set filetype=VitStash
endfunction " }}}

function! vit#commands#Move(newpath) " {{{
    if exists("b:vit")
        let l:bufn = bufnr("%")
        let l:newpath = substitute(getcwd()."/".a:newpath, b:vit.repo.worktree."/", '', '')
        call b:vit.execute("mv ".b:vit.path.relative." ".l:newpath)
        if v:shell_error == 0
          execute "edit ".l:newpath
          execute "bdelete ".l:bufn
          call vit#windows#refreshByType("VitStatus")
        else
            echo "Unable to move file"
        endif
    endif
endfunction " }}}

function! vit#commands#Remove() " {{{
    if exists("b:vit")
        call b:vit.execute("rm ".b:vit.path.relative)
        if v:shell_error == 0
            bdelete
            call vit#windows#refreshByType("VitStatus")
        else
            echo "Unable to remove file(s)"
        endif
    endif
endfunction " }}}

function! vit#commands#RevertFile(rev, file) " {{{
    if confirm("Are you sure you want to git revert this file?", "y\nN", 0) == 1 && exists("b:vit")
        call vit#commands#Checkout(a:rev." -- ".a:file)
        let l:msg = b:vit.execute("cat-file commit ".a:rev)
        call vit#commands#PerformCommit("-m 'Reverted ".a:file." to ".a:rev." \"".split(l:msg, '\n')[5]."\"'")
    endif
endfunction " }}}

" vim: set foldmethod=marker formatoptions-=tc:
