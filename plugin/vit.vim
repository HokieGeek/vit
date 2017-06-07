if exists("g:loaded_vit") || v:version < 700
    finish
endif
let g:loaded_vit = 1

let g:vit_commands = ["log", "status", "blame", "diff", "show", "add", "reset", "checkout", "commit", "stash", "mv", "rm", "revert"]

function! vit#GitCompletion(arg_lead, cmd_line, cursor_pos) " {{{
    if a:cmd_line =~# "^Git add "
        let l:files = split(glob(b:vit_root_dir."/".a:arg_lead."*"))
        let l:files = map(l:files, 'v:val.(isdirectory(v:val)?"/":"")')
        let l:files = map(l:files, 'substitute(v:val, b:vit_root_dir."/", "", "")')
        return l:files
    elseif len(split(a:cmd_line)) <= 2
        if a:arg_lead ==? ''
            return g:vit_commands
        else
            return filter(g:vit_commands, 'v:val[0:strlen(a:arg_lead)-1] ==? a:arg_lead')
        endif
    endif
endfunction " }}}

function! vit#Git(...) " {{{
    if exists("b:vit")
        if a:0 > 0
            if a:1 ==# "diff"
                if a:0 < 2
                    let l:rev = vit#GetUserInput('Commit, tag or branch: ')
                else
                    let l:rev = a:2
                endif
                call vit#Diff(b:vit.path.relative, l:rev)
            elseif a:1 ==# "blame"
                call vit#Blame(b:vit.path.relative)
            elseif a:1 ==# "log" || a:1 ==# "lg"
                call vit#Log(b:vit.path.relative)
            elseif a:1 ==# "show"
                call vit#Show(a:2)
            elseif a:1 ==# "status" || a:1 ==# "st"
                call vit#Status()
            elseif a:1 ==# "add"
                call vit#Add(b:vit.path.relative)
            elseif a:1 ==# "commit"
                call vit#Commit(join(a:000[1:], ' '))
            elseif a:1 ==# "reset"
                call vit#Reset(" -- ".b:vit.path.relative)
            elseif a:1 ==# "checkout" || a:1 ==# "co"
                call vit#CheckoutCurrentFile("HEAD")
            elseif a:1 ==# "stash"
                echom "stash: ".a:0
                if a:0 == 2 && a:2 == "view"
                    call vit#StashViewer()
                else
                    call vit#Stash(join(a:000[1:], ' '))
                endif
            elseif a:1 ==# "mv"
                call vit#Move(a:000[1])
            elseif a:1 ==# "rm"
                call vit#Remove()
            elseif a:1 ==# "revert"
                if a:0 < 2
                    let l:rev = vit#GetUserInput('Revision to revert to: ')
                else
                    let l:rev = a:2
                endif
                call vit#RevertFile(l:rev, b:vit.path.relative)
            else
                call vit#UserGitCommand(join(a:000[1:], ' '))
            endif
        else
            call vit#Status()
        endif
    else
        echomsg "Not in a git repository"
    endif
endfunction " }}}

autocmd BufWinEnter * call vit#init() | call vit#RefreshStatuses()

" vim: set foldmethod=marker formatoptions-=tc:
