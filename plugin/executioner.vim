" ============================================================================
" File:       executioner.vim
" Maintainer: https://github.com/EvanQuan/vim-executioner/
" Version:    0.3.0
"
" A Vim plugin to easily execute files in the terminal or a separate buffer.
" ============================================================================

if exists("g:executioner#loaded")
  finish
endif
let g:executioner#loaded = 1

" Fake enums

" Split types
let s:NONE = 0
let s:VERTICAL = 1
let s:HORIZONTAL = 2

" Command types
let s:EXTENSION_COMMAND = 3
let s:NAME_COMMAND = 4

" Regex
" TODO improve regex to factor in last . not first incase file has multiple
" dots, or file starts with dot
" This finds the first . and returns everything that follows it
" This is not optimal but is good for now.
let s:DOT_WITH_FILE_EXTENSION = '\..*'

" extension : <command
" Command is executed with file as argument
"     $ command filename.extension
if !exists("g:executioner#extensions")
  let g:executioner#extensions = {
                              \ 'R'  : 'Rscript',
                              \ 'hs'  : 'ghci',
                              \ 'js' : 'node',
                              \ 'py' : 'python3',
                              \ 'sh' : 'bash',
                              \}
endif

" file name : command
" Command is executed with no arguments
"     $ command
if !exists("g:executioner#names")
  let g:executioner#names = {
                            \ 'makefile': 'make',
                            \}
endif

function! s:GetExtenstion(file_name) abort
  " If no extension is found, return ""
  return matchstr(a:file_name, s:DOT_WITH_FILE_EXTENSION)[1:]
endfunction

function! s:DetermineExecuteCommand(file_name) abort
  " Returns the execute command of the file_name
  " If not executable, returns empty string
  let s:extension = s:GetExtenstion(a:file_name)
  if has_key(g:executioner#names, a:file_name)
    return g:executioner#names[a:file_name]
  elseif has_key(g:executioner#extensions, s:extension)
    return g:executioner#extensions[s:extension] . " " . shellescape(a:file_name, 1)
  else
    return ""
  endif
endfunction

function! s:DetermineSplitPrefix(split_type) abort
  " Determine split_prefix based on if terminal is support and on split_type.
  " At this point, it is assumed a valid command is being processed.
  " This is important because if there is not terminal support, the readonly
  " buffers for splitting need to be created manually.

  " If terminal is available, use just the built-in terminal. Otherwise,
  " run the command in command-mode terminal and redirect output to buffer.
  let s:split_prefix = has("terminal") && a:split_type != s:NONE ? (
              \ a:split_type == s:VERTICAL ? "vertical " . "terminal " :
              \ a:split_type == s:HORIZONTAL ?  "horizontal " . "terminal " : ""
                    \ )
        \ :
              \ a:split_type != s:NONE ? "." : ""
                    \ . "!"
  return s:split_prefix
endfunction

function! s:ExecuteCommand(split_type, final_command) abort
  " Split type is only needed for non-terminal to determine how buffer is
  " split

  " Check for terminal
  if has("terminal")
    execute a:final_command
    return
  endif

  " Manually create a readonly buffer if terminal is not supported
  if a:split_type != s:NONE
    let a:buffer_split = a:split_type == s:VERTICAL ? 'vertical' : 'botright'

    let a:output_buffer_name = "Output"
    let a:output_buffer_filetype = "output"
    " reuse existing buffer window if it exists otherwise create a new one
    if !exists("a:buf_nr") || !bufexists(a:buf_nr)
      silent execute a:buffer_split . ' new ' . a:output_buffer_name
      let a:buf_nr = bufnr('%')
    elseif bufwinnr(a:buf_nr) == -1
      silent execute a:buffer_split . ' new'
      silent execute a:buf_nr . 'buffer'
    elseif bufwinnr(a:buf_nr) != bufwinnr('%')
      silent execute bufwinnr(a:buf_nr) . 'wincmd w'
    endif

    silent execute "setlocal filetype=" . a:output_buffer_filetype
    setlocal bufhidden=delete
    setlocal buftype=nofile
    setlocal noswapfile
    setlocal nobuflisted
    setlocal winfixheight
    setlocal cursorline " make it easy to distinguish
    setlocal nonumber
    setlocal norelativenumber
    setlocal showbreak=""

    " clear the buffer and make it modifiable for terminal output
    setlocal noreadonly
    setlocal modifiable
    %delete _

    " echo "Executing " . shellescape(a:current_buffer_file_path, 1) . " ..."
    echon 'Executing ' . a:file_name . ' ... '
    " Execute file
    execute a:final_command

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
    setlocal readonly
    setlocal nomodifiable
    echon "DONE"
  endif
endfunction

" function! s:MergeExecuteCommandWith(execute_command) abort
"   " Returns the execute_command with the file based on validity of execute
"   " command, and command type. Invalid execute_commands (empty), result in
"   " a message being echoed to the user.
"   a:execute_command == "" ? "echo '" .
"         \ (&filetype == "" ? "no ft" : &filetype) . " files cannot be ran.'" :
"         \ a:output_type . "!" . a:execute_command .
"         \ (a:execute_command == "make" ? "" : " " . shellescape(a:file_name, 1))
"   " return
" endfunction

function! s:SaveAndExecuteFile(...) abort
  " Parameters:
  "   a:1 char split_type
  "     s:NONE - No split (default)
  "     s:HORIZONTAL - Horizontal split
  "     s:VERTICAL - Vertical split
  "   a:2 string file_name
  "     default - current file
  "
  " SOURCE [reusable window]: https://github.com/fatih/vim-go/blob/master/autoload/go/ui.vim
  let s:split_type = a:0 > 0 ? a:1 : s:NONE
  " Expand is not working? Is it doing the vim file?
  " Or is args count wrong?
  let s:file_name = (a:0 > 1 && a:2 != "" ? a:2 : expand("%"))

  " DEBUG
  echom "a0: " . a:0
  echom "a1: " . (a:0 > 0 ? a:1 : "no a1")
  echom "a2: " . (a:0 > 1 ? a:2 : "no a2")
  echom "s:split_type: " . s:split_type
  echom "s:file_name: " . s:file_name

  " If not split, then output is terminal
  " Otherwise, the output replaces the current buffer contents
  let s:execute_command = s:DetermineExecuteCommand(s:file_name)

  " If invalid execute_command then return early with error message
  if s:execute_command == ""
    execute "echo '\'" . s:file_name . "\' is not configured to be executable.'"
    return
  endif

  " Evaluate saving current buffer
  " Don't save and reload current file not in file
  if &filetype != ""
    silent execute "update | edit"
  endif

  " Evaluate split_type
  " If vertical or horizontal split, then create terminal or output buffer
  let s:split_prefix = s:DetermineSplitPrefix(s:split_type)

  let s:final_command = s:split_prefix . s:execute_command

  echom "s:final_command: " . s:final_command
  " return

  " Finally execute command
  s:ExecuteCommand(s:split_type, s:final_command)
endfunction

function! g:Debug()
  " echom s:DetermineExecuteCommand("test.py")
  " echom s:DetermineExecuteCommand("makefile")
  " echom s:DetermineExecuteCommand("run.sh")
  " s:SaveAndExecuteFile(s:NONE, "test.py")
  " echom s:SaveAndExecuteFile(s:VERTICAL, "makefile")
  " echom s:SaveAndExecuteFile(s:HORIZONTAL, "run.sh")
endfunction

nnoremap <leader>d :call g:Debug()<CR>
nnoremap <leader>d :call g:Debug()<CR>

" Create commands
command! -nargs=* Executioner           :call s:SaveAndExecuteFile(s:NONE, <q-args>)
command! -nargs=* ExecutionerVertical   :call s:SaveAndExecuteFile(s:VERTICAL, <q-args>)
command! -nargs=* ExecutionerHorizontal :call s:SaveAndExecuteFile(s:HORIZONTAL, <q-args>)
