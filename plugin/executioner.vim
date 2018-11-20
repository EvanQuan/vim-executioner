" ============================================================================
" File:       executioner.vim
" Maintainer: https://github.com/EvanQuan/vim-executioner/
" Version:    0.1.0
"
" A Vim plugin to easily execute files in the terminal or a separate buffer.
" ============================================================================

if exists("g:loaded_executioner")
  finish
endif
let g:loaded_executioner = 1

" Executable with file as parameter
" file extension : command
let g:executable_with_file = {
                            \ 'py' : 'python3',
                            \ 'sh' : 'bash',
                            \ 'R' : 'Rscript',
                            \ 'js' : 'node',
                            \}

" Executable by itself
" file name : command
let g:executable_no_file = { 'makefile': 'make',
                          \}

function! s:GetExtenstion(fileName) abort
  " TODO improve regex
  " This finds the first . and returns everything that follows it
  " This is not optimal but is good for now.
  " If no . is found, or if nothing is after the . then return ""
  let s:file_extension = '\..*'
  return matchstr(a:fileName, s:file_extension)[1:]
endfunction

function! s:DetermineExecuteCommand(fileName) abort
  " Returns the execute command of the fileName
  " If not executable, returns empty string
  let s:extension = s:GetExtenstion(a:fileName)
  if has_key(g:executable_with_file, s:extension)
    return g:executable_with_file[s:extension]
  elseif has_key(g:executable_no_file, a:fileName)
    return g:executable_no_file[a:fileName]
  else
    return ""
  endif
endfunction
" nnoremap <leader>d :echo s:DetermineExecuteCommand("")<Left><Left>


function! s:SaveAndExecuteFile(...) abort
  " Parameters:
  "   a:1 char split_type
  "     'n' - No split (default)
  "     'h' - Horizontal split
  "     'v' - Vertical split
  "   a:2 string file_name
  "     default - current file
  "
  " SOURCE [reusable window]: https://github.com/fatih/vim-go/blob/master/autoload/go/ui.vim
  let s:split_type = a:0 > 0 ? a:1 : 'n'
  " Expand is not working? Is it doing the vim file?
  " Or is args count wrong?
  let s:file_name = (a:0 > 1 && a:2 != "" ? a:2 : expand("%"))

  " DEBUG
  " echom "a0: " . a:0
  " echom "a1: " . (a:0 > 0 ? a:1 : "no a1")
  " echom "a2: " . (a:0 > 1 ? a:2 : "no a2")
  " echom "s:split_type: " . s:split_type
  " echom "s:file_name: " . s:file_name

  " If not split, then output is terminal
  " Otherwise, the output replaces the current buffer contents
  let s:output_type = s:split_type == 'n' ? "" : "."
  let s:command = s:DetermineExecuteCommand(s:file_name)
  let s:final_command = s:command == "" ? "echo '" . (&filetype == "" ? "no ft" : &filetype) . " files cannot be ran.'" : s:output_type . "!" . s:command . (s:command == "make" ? "" : " " . shellescape(s:file_name, 1))

  let s:is_splitting = s:command != "" && (s:split_type == 'v' || s:split_type == 'h')

  " Don't save and reload current file not in file
  if s:command != "" && &filetype != ""
    silent execute "update | edit"
  endif

  " Evaluate split_type
  " If vertical or horizontal split, then create output buffer
  if s:is_splitting
    let s:buffer_split = s:split_type == 'v' ? 'vertical' : 'botright'

    let s:output_buffer_name = "Output"
    let s:output_buffer_filetype = "output"
    " reuse existing buffer window if it exists otherwise create a new one
    if !exists("s:buf_nr") || !bufexists(s:buf_nr)
      silent execute s:buffer_split . ' new ' . s:output_buffer_name
      let s:buf_nr = bufnr('%')
    elseif bufwinnr(s:buf_nr) == -1
      silent execute s:buffer_split . ' new'
      silent execute s:buf_nr . 'buffer'
    elseif bufwinnr(s:buf_nr) != bufwinnr('%')
      silent execute bufwinnr(s:buf_nr) . 'wincmd w'
    endif

    silent execute "setlocal filetype=" . s:output_buffer_filetype
    setlocal bufhidden=delete
    setlocal buftype=nofile
    setlocal noswapfile
    setlocal nobuflisted
    setlocal winfixheight
    setlocal cursorline " make it easy to distinguish
    setlocal nonumber
    setlocal norelativenumber
    setlocal showbreak=""

    " clear the buffer
    setlocal noreadonly
    setlocal modifiable
    %delete _

    " echo "Executing " . shellescape(s:current_buffer_file_path, 1) . " ..."
  echon 'Executing ' . s:file_name . ' ... '
  endif

  " Execute file
  execute s:final_command

  " resize window to content length
  " Note: This is annoying because if you print a lot of lines then your
  "       code buffer is forced to a height of one line every time you execute
  "       this function.
  "       However without this line the buffer starts off as a default size
  "       and if you resize the buffer then it keeps that custom size after
  "       repeated executes of this function.
  "       But if you close the output buffer then it returns to using the
  "       default size when its recreated
  " execute 'resize' . line('$')

  " make the buffer non modifiable
  if s:is_splitting
    setlocal readonly
    setlocal nomodifiable
    echon "DONE"
  endif
endfunction

command! -nargs=* Executioner :call s:SaveAndExecuteFile('n', <q-args>)
command! -nargs=* ExecutionerVertical :call s:SaveAndExecuteFile('v', <q-args>)
command! -nargs=* ExecutionerHorizontal :call s:SaveAndExecuteFile('h', <q-args>)
