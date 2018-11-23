" ============================================================================
" File:       executioner.vim
" Maintainer: https://github.com/EvanQuan/vim-executioner/
" Version:    0.6.0
"
" A Vim plugin to easily execute files in the terminal or a separate buffer.
" ============================================================================

if exists("g:executioner#loaded")
  finish
endif
let g:executioner#loaded = 1

" Name and extension
let g:executioner#current_file = '%'
" Just name
" Currently unused
let g:executioner#current_name = '@'

" Fake enums

" Parsed input
let s:FILE_NAME = 0
let s:ARGS = 1

" Split types
let s:NONE = 2
let s:VERTICAL = 3
let s:HORIZONTAL = 4

" Command types
let s:EXTENSION_COMMAND = 5
let s:NAME_COMMAND = 6

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
                                 \ 'c'  : 'gcc % -o @.out; ./@.out',
                                 \ 'cpp'  : 'g++ % -o @.out; ./@.out',
                                 \ 'R'  : 'Rscript %',
                                 \ 'hs'  : 'ghci %',
                                 \ 'js' : 'node %',
                                 \ 'php' : 'php %',
                                 \ 'pl' : 'perl %',
                                 \ 'prolog' : 'swipl %',
                                 \ 'py' : 'python3 %',
                                 \ 'sh' : 'bash %',
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

function! s:GetExtension(file_name) abort
  " If no extension is found, return ""
  return matchstr(a:file_name, s:DOT_WITH_FILE_EXTENSION)[1:]
endfunction

function! s:GetExecuteCommand(parsed_input) abort
  " Returns the execute command of the parsed_input
  " If not executable, returns empty string
  " echom "GetExecuteCommand file name: \"" . a:parsed_input[s:FILE_NAME] . "\""
  let s:extension = s:GetExtension(a:parsed_input[s:FILE_NAME])
  " echom "GetExecuteCommand extension: \"" . s:extension . "\""
  if has_key(g:executioner#names, a:parsed_input[s:FILE_NAME])
    return g:executioner#names[a:parsed_input] . a:parsed_input[s:ARGS]
  elseif has_key(g:executioner#extensions, s:extension)
    return g:executioner#extensions[s:extension] . " "
          \ . a:parsed_input[s:FILE_NAME] . a:parsed_input[s:ARGS]
  else
    return ""
  endif
endfunction

function! s:Substitute(string, old, new) abort
  " Substitute characters of s:executioner#curent_name with current name
  let s:new_string = ""
  for i in range(len(a:string))
    if a:string[i] == a:old
      let s:new_string .= a:new
    else
      let s:new_string .= a:string[i]
    endif
  endfor
  return s:new_string
endfunction

function! s:ParseInput(file_with_args) abort
  " Returns the input as a list
  " 0    - file (name with extention)
  " 1..n - arguments (empty if none)
  let s:input_list = split(a:file_with_args)
  if len(s:input_list) == 0
    return ["", ""]
  endif
  let s:file = s:input_list[0] == g:executioner#current_file ?
        \ expand("%") : s:input_list[0]
  let s:file_name = split(s:file, '\.')[0]
  let s:arguments = ""
  if len(s:input_list) > 1
    for arg in s:input_list[1:]
      " s:arguments = s:arguments . " " . arg
      let s:arguments .= " " . s:Substitute(arg, g:executioner#current_name, s:file_name)
    endfor
  endif
  return [s:file, s:arguments]
endfunction

function! s:GetSplitPrefix(split_type) abort
  " Determine split_prefix based on if terminal is support and on split_type.
  " At this point, it is assumed a valid command is being processed.
  " This is important because if there is not terminal support, the readonly
  " buffers for splitting need to be created manually.

  " If terminal is available, use just the built-in terminal. Otherwise,
  " run the command in command-mode terminal and redirect output to buffer.
  let s:split_prefix = has("terminal") && a:split_type != s:NONE ?
              \ (a:split_type == s:VERTICAL ? "vertical " : "") . "terminal "
        \ :
              \ a:split_type != s:NONE ? "." : ""
                    \ . "!"
  return s:split_prefix
endfunction

function! s:ExecuteCommand(split_type, final_command, file_name) abort
  " Split type is only needed for non-terminal to determine how buffer is
  " split

  " echom "in ExecuteCommand"
  " Check for terminal
  if has("terminal")
    " echom "ExecuteCommand: has terminal"
    execute a:final_command
    " execute shellescape(a:final_command, 1)
    " echom "final_command: " . s:final_command
  " echom "ExecuteCommand: no terminal"

  " Manually create a readonly buffer if terminal is not supported
  elseif a:split_type != s:NONE
    let s:buffer_split = s:split_type == s:VERTICAL ? 'vertical' : 'botright'

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

    " clear the buffer and make it modifiable for terminal output
    setlocal noreadonly
    setlocal modifiable
    %delete _

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
  endif
endfunction


function! s:SaveAndExecuteFile(...) abort
  " Parameters:
  "   a:1 char split_type
  "     s:NONE - No split (default)
  "     s:HORIZONTAL - Horizontal split
  "     s:VERTICAL - Vertical split
  "   a:2 string file_with_args
  "     default - current file
  "
  " SOURCE [reusable window]: https://github.com/fatih/vim-go/blob/master/autoload/go/ui.vim
  let s:split_type = a:0 > 0 ? a:1 : s:NONE
  " Expand is not working? Is it doing the vim file?
  " Or is args count wrong?
  let s:file_with_args = a:0 > 1 && a:2 != "" ? a:2 : expand("%")

  " DEBUG
  " echom "a0: " . a:0
  " echom "a1: " . (a:0 > 0 ? a:1 : "no a1")
  " echom "a2: " . (a:0 > 1 ? a:2 : "no a2")
  " echom "s:split_type: " . s:split_type
  " echom "s:file_with_args: " . s:file_with_args

  " If not split, then output is terminal
  " Otherwise, the output replaces the current buffer contents
  let s:parsed_input = s:ParseInput(s:file_with_args)
  let s:execute_command = s:GetExecuteCommand(s:parsed_input)

  " echom "s:execute_command: " . s:execute_command
  " If invalid execute_command then return early with error message
  if s:execute_command == ""
    execute "echo \"'" . s:parsed_input[s:FILE_NAME]
          \ . "' is not configured to be executable.\""
    return -1
  endif

  " Evaluate saving current buffer
  " Don't save and reload current file not in file
  if &filetype != ""
    silent execute "update | edit"
  endif

  " Evaluate split_type
  " If vertical or horizontal split, then create terminal or output buffer
  let s:split_prefix = s:GetSplitPrefix(s:split_type)

  let s:final_command = s:split_prefix . s:execute_command

  " Finally execute command
  call s:ExecuteCommand(s:split_type, s:final_command, s:file_name)
endfunction

function! g:Debug(...) abort
  let s:file_with_args = a:0 > 1 && a:2 != "" ? a:2 : expand("%")

  let s:parsed_input = s:ParseInput(s:file_with_args)
  let s:execute_command = s:GetExecuteCommand(s:parsed_input)

  echom s:execute_command
  " let s:file_name = split("test.py", '.')[0]
  " echom s:file_name[0]
  " let s:parsed_input = s:ParseInput("test.py a1 --a2 -a3")
  " echom "file_name: \"" . s:parsed_input[s:FILE_NAME] . "\""
  " echom "args: \"" . s:parsed_input[s:ARGS] . "\""
  " echom "extension: \"" . s:GetExtension(s:parsed_input[s:FILE_NAME]) . "\""
  " echom "execute_command: \"" . s:GetExecuteCommand(s:parsed_input) . "\""
endfunction

nnoremap <leader>d :call g:Debug(2, "test.cpp")<CR>

" Create commands
command! -nargs=* Executioner           :call s:SaveAndExecuteFile(s:NONE, <q-args>)
command! -nargs=* ExecutionerVertical   :call s:SaveAndExecuteFile(s:VERTICAL, <q-args>)
command! -nargs=* ExecutionerHorizontal :call s:SaveAndExecuteFile(s:HORIZONTAL, <q-args>)
