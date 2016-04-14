if exists("b:autoloaded_vit_status") || v:version < 700
    finish
endif
let b:autoloaded_vit_status = 1
scriptencoding utf-8

call vit#GetGitConfig(b:vit_ref_file)
if exists("b:vit_git_version") && (b:vit_git_version[0] > 1 || b:vit_git_version[1] > 7 || (b:vit_git_version[1] == 7 && b:vit_git_version[2] > 2))
    call vit#LoadContent(vit#ExecuteGit("status -sb"))
else
    call vit#LoadContent(vit#ExecuteGit("status -s"))
endif

" Set width of the window based on the widest text
set winminwidth=1
let b:max_cols = max(map(getline(1, "$"), "len(v:val)")) + 5
execute "vertical resize ".b:max_cols

setlocal nolist nomodifiable nonumber "cursorline
if exists("&relativenumber")
    setlocal norelativenumber
endif

function! VitStatus#LoadFileFromStatus(line)
    if a:line !~ "^##" && exists("b:vit_root_dir")
        " echomsg a:line
        let l:file = b:vit_root_dir."/".split(a:line)[1]
        " echomsg l:file
        " execute bufwinnr(l:file)."wincmd w"
        wincmd h
        if bufloaded(l:file)
            echom "Already exists"
        "     call vit#Diff('', '')
        else
            execute "edit ".l:file
        endif
    else
        echo "root = ".b:vit_root_dir
    endif
endfunction

nnoremap <buffer> <silent> + :if getline(".") !~ "^##"<bar>call vit#Add(split(getline("."))[1])<bar>wincmd p<bar>endif<cr>
nnoremap <buffer> <silent> - :if getline(".") !~ "^##"<bar>call vit#Unstage(split(getline("."))[1])<bar>wincmd p<bar>endif<cr>

nnoremap <buffer> <silent> o :if getline(".") !~ "^##"<bar>call vit#OpenFileAsDiff(split(getline("."))[1])<bar>endif<cr>
