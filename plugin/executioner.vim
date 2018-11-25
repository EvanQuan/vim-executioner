" ============================================================================
" File:       executioner.vim
" Maintainer: https://github.com/EvanQuan/vim-executioner/
" Version:    1.0.0
"
" A Vim plugin to easily execute files in the terminal or a separate buffer.
" ============================================================================

if exists("g:executioner#loaded")
  finish
endif
let g:executioner#loaded = 1

" Name and extension
if !exists("g:executioner#full_name")
  let g:executioner#full_name = '%'
endif
" Just name
if !exists("g:executioner#base_name")
  let g:executioner#base_name = '@'
endif

" Fake enums

" Parsed input
let s:FILE = 0
let s:NAME = 1
let s:EXTENSION = 2
let s:ARGS = 3

" Split types
let s:NONE = 0
let s:VERTICAL = 1
let s:HORIZONTAL = 3

" Command types
let s:EXTENSION_COMMAND = 0
let s:NAME_COMMAND = 1

" extension : command
" Command is executed if file has specified extension
if !exists("g:executioner#extensions")
  let g:executioner#extensions = {
                                 \ 'c'  : 'gcc % -o @.out; ./@.out',
                                 \ 'cpp'  : 'g++ % -o @.out; ./@.out',
                                 \ 'R'  : 'Rscript %',
                                 \ 'r'  : 'Rscript %',
                                 \ 'hs'  : 'ghci %',
                                 \ 'js' : 'node %',
                                 \ 'php' : 'php %',
                                 \ 'pl' : 'perl %',
                                 \ 'prolog' : 'swipl %',
                                 \ 'py' : 'python3 %',
                                 \ 'py2' : 'python %',
                                 \ 'sh' : 'bash %',
                                 \}
endif

" file name : command
" Command is executed if file has specified name
if !exists("g:executioner#names")
  let g:executioner#names = {
                            \ 'makefile': 'make',
                            \}
endif

function! s:SplitNameAndExtenstion(file) abort
  " Get the extension of file name denoted characters after the last "."
  " Paramters:
  "   string file
  " Returns:
  "   list [name, extension] if extension is found
  "   list [file, ""] if no extension is found
  "   list ["", ""] if input is empty
  if len(a:file) == 0
    return ["", ""]
  endif

  " Split the file in terms of "."
  let s:file_split = split(a:file, '\.')
  let s:name = s:file_split[0]
  if len(s:file_split) > 1
    for i in range(1, len(s:file_split) - 2)
      let s:name .= '.' . s:file_split[i]
    endfor
    let s:extension = s:file_split[len(s:file_split) - 1]
  else
    let s:extension = ""
  endif
  return [s:name, s:extension]
endfunction

function! s:GetExtension(...) abort
  return 1
endfunction

function! s:GetExecuteCommand(parsed_input) abort
  " Parameters:
  "   list parsed_input [string file, string name, string extension, string args]
  " Returns:
  "   string the execute command of the parsed_input if executable
  "          "" if not executable
  if has_key(g:executioner#names, a:parsed_input[s:FILE])
    let s:command = g:executioner#names[a:parsed_input[s:FILE]]
          \ . a:parsed_input[s:ARGS]
  elseif has_key(g:executioner#extensions, a:parsed_input[s:EXTENSION])
    let s:command = g:executioner#extensions[a:parsed_input[s:EXTENSION]]
          \ . a:parsed_input[s:ARGS]
  else
    let s:command = ""
  endif

  " Substitute symbols
  let s:command = s:Substitute(s:command, g:executioner#base_name,
        \ s:parsed_input[s:NAME])
  let s:command = s:Substitute(s:command, g:executioner#full_name,
        \ a:parsed_input[s:FILE])
  return s:command
endfunction

function! s:Substitute(string, old, new) abort
  " Substitute characters of old with strings of new
  " Parameters:
  "   string string to substitute characters
  "   char old - to substitute with new
  "   string new - to substitute old
  " Returns:
  "   string with substituted characters
  let s:new_string = ""
  for i in range(len(a:string))
    let s:new_string .= a:string[i] == a:old ? a:new : a:string[i]
    " if a:string[i] == a:old
    "   let s:new_string .= a:new
    " else
    "   let s:new_string .= a:string[i]
    " endif
  endfor
  return s:new_string
endfunction

function! s:ParseInput(file_with_args) abort
  " Parses the input into its components
  " Parameters:
  "   string file_with_args - file name, optionally followed by arguments
  " Returns:
  "   list [string file, string name, string extension, string arguments]

  " If no arguments supplied, then there is nothing to parse
  if len(a:file_with_args) == 0
    return ["", "", ""]
  endif

  " Split the arguments into terms to extract the file name and extension.
  let s:input_terms = split(a:file_with_args)

  " If the first term (file name) is the file symbol, then the file being ran
  " is the current buffer. Otherwise, the first term is the full name of the
  " file to be ran.
  let s:file_with_extension = s:input_terms[0] == g:executioner#full_name ?
        \ expand("%") : s:input_terms[0]

  " Split the file into its name and extension.
  let s:file = s:SplitNameAndExtenstion(s:file_with_extension)

  " Remaining terms are arguments
  " Join all arguments back together with spaces
  let s:arguments = len(s:input_terms) > 1 ?
        \ " " . join(s:input_terms[1:], " ") : ""

  return [s:file_with_extension, s:file[0], s:file[1], s:arguments]
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
  " SOURCE [reusable window]:
  " https://github.com/fatih/vim-go/blob/master/autoload/go/ui.vim

  " If no arguments are supplied then the split type defaults to NONE.
  " Otherwise, use the specified split type.
  let s:split_type = a:0 > 0 ? a:1 : s:NONE

  " If no arguments after split type are specified, assume the current file
  " is being ran with no arguments.
  " Otherwise, assume the first argument is the file to be ran.
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
    execute "echo \"'" . s:parsed_input[s:NAME]
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
  call s:ExecuteCommand(s:split_type, s:final_command, s:parsed_input[s:FILE])
endfunction

" function! g:Debug(...) abort
"   " let s:file_with_args = a:0 > 1 && a:2 != "" ? a:2 : expand("%")

"   " let s:parsed_input = s:ParseInput(s:file_with_args)
"   " let s:execute_command = s:GetExecuteCommand(s:parsed_input)
"   let s:in = "% -debug % @"
"   " echom s:execute_command
"   let s:parsed_input = s:ParseInput(s:in)

"   echom "file: ". s:parsed_input[s:FILE]
"   echom "name: ". s:parsed_input[s:NAME]
"   echom "extension: ". s:parsed_input[s:EXTENSION]
"   echom "args: ". s:parsed_input[s:ARGS]

"   let s:command = s:GetExecuteCommand(s:parsed_input)

"   echom "command: " . s:command

  " let s:file_name = split("test.py", '.')[0]
  " echom s:file_name[0]
  " let s:parsed_input = s:ParseInput("test.py a1 --a2 -a3")
  " echom "file_name: \"" . s:parsed_input[s:NAME] . "\""
  " echom "args: \"" . s:parsed_input[s:ARGS] . "\""
  " echom "extension: \"" . s:GetExtension(s:parsed_input[s:NAME]) . "\""
  " echom "execute_command: \"" . s:GetExecuteCommand(s:parsed_input) . "\""
" endfunction

" nnoremap <leader>d :call g:Debug(2, "test.cpp")<CR>

" Create commands
command! -nargs=* Executioner           :call s:SaveAndExecuteFile(s:NONE, <q-args>)
command! -nargs=* ExecutionerVertical   :call s:SaveAndExecuteFile(s:VERTICAL, <q-args>)
command! -nargs=* ExecutionerHorizontal :call s:SaveAndExecuteFile(s:HORIZONTAL, <q-args>)
