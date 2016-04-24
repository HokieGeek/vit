if exists("g:loaded_vit") || v:version < 700
    finish
endif
let g:loaded_vit = 1

let g:vit_commands = ["log", "status", "blame", "diff", "show", "add", "reset", "checkout", "commit", "stash"]

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
            " echomsg "Git(".string(a:000).")"
            let l:command = a:1
            let l:cmd_args = join(a:000[1:], ' ')

            if l:command ==# "diff"
                let l:file = expand("%")
                if len(l:cmd_args) <= 0
                    let l:rev = vit#GetUserInput('Commit, tag or branch: ')
                else
                    let l:rev = a:000[1]
                    if a:0 > 2
                        let l:file = a:000[2]
                    endif
                endif

                " TODO: this is not pretty
                call vit#Diff(l:rev, vit#GetFilenameRelativeToGit(fnamemodify(l:file, ":p")))
            elseif l:command ==# "blame"
                call vit#Blame(expand("%:p"))
            elseif l:command ==# "log" || l:command ==# "lg"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%")
                endif
                call vit#Log(l:cmd_args)
            elseif l:command ==# "show"
                call vit#Show(l:cmd_args)
            elseif l:command ==# "status" || l:command ==# "st"
                if strlen(expand("%")) == 0
                    call vit#Status(getcwd())
                else
                    call vit#Status(expand("%:p:h"))
                endif

            elseif l:command ==# "add"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%:p")
                endif
                call vit#Add(l:cmd_args)
            elseif l:command ==# "commit"
                call vit#Commit(l:cmd_args)
            elseif l:command ==# "reset"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%:p")
                    call vit#ResetFilesInGitIndex("", l:cmd_args)
                else
                    call vit#Reset(l:cmd_args)
                endif
            elseif l:command ==# "checkout" || l:command ==# "co"
                if len(l:cmd_args) <= 0
                    call vit#CheckoutCurrentFile("HEAD")
                else
                    call vit#Checkout(l:cmd_args)
                endif
            elseif l:command ==# "stash"
                call vit#Stash(l:cmd_args)
            else
                call vit#UserGitCommand(l:cmd_args)
            endif
        else
            call vit#Status("")
        endif
    else
        echomsg "Not in a git repository"
    endif
endfunction " }}}

autocmd BufWinEnter * call vit#init() | call vit#RefreshStatus()

" vim: set foldmethod=marker formatoptions-=tc:
