" ============================================================================
" File:       executioner.vim
" Maintainer: https://github.com/EvanQuan/vim-executioner/
" Version:    1.3.0
"
" A Vim plugin to easily execute files in the terminal or a separate buffer.
" You can learn more about it with:
"
"     :help executioner
"
" ============================================================================

if exists("g:executioner#loaded")
  finish
endif

" Name and extension
if !exists("g:executioner#full_name")
  let g:executioner#full_name = '%'
endif
" Just name
if !exists("g:executioner#base_name")
  let g:executioner#base_name = '@'
endif

if !exists("g:executioner#load_defaults")
  let g:executioner#load_defaults = 1
endif

" Parsed input
let s:FILE = 0
let s:NAME = 1
let s:EXTENSION = 2
let s:ARGS = 3
let s:PATHLESS_NAME = 4

" Split types
let s:NONE = 0
let s:VERTICAL = 1
let s:HORIZONTAL = 3

" Command types
let s:INVALID_COMMAND = -1

let s:DIRECTORY_SEPARATOR = '[/\\]'

let s:has_teriminal = has("terminal")

" extension : command
" Command is executed if file has specified extension
if !exists("g:executioner#extensions")
  let g:executioner#extensions = {}
endif

" file name : command
" Command is executed if file has specified name
if !exists("g:executioner#names")
  let g:executioner#names = {}
endif

if g:executioner#load_defaults
  if !has_key(g:executioner#extensions, 'c')
    let g:executioner#extensions['c'] = 'gcc % -o @.out;./@.out'
  endif
  if !has_key(g:executioner#extensions, 'cpp')
    let g:executioner#extensions['cpp'] = 'g++ % -o @.out;./@.out'
  endif
  if !has_key(g:executioner#extensions, 'hs')
    let g:executioner#extensions['hs'] = 'ghci %'
  endif
  if !has_key(g:executioner#extensions, 'java')
    let g:executioner#extensions['java'] = 'javac %;java @'
  endif
  if !has_key(g:executioner#extensions, 'js')
    let g:executioner#extensions['js'] = 'node %'
  endif
  if !has_key(g:executioner#extensions, 'm')
    let g:executioner#extensions['m'] = 'matlab'
  endif
  if !has_key(g:executioner#extensions, 'ml')
    let g:executioner#extensions['ml'] = 'ocaml % -o @.out;./@.out'
  endif
  if !has_key(g:executioner#extensions, 'php')
    let g:executioner#extensions['php'] = 'php %'
  endif
  if !has_key(g:executioner#extensions, 'pl')
    let g:executioner#extensions['pl'] = 'perl %'
  endif
  if !has_key(g:executioner#extensions, 'prolog')
    let g:executioner#extensions['prolog'] = 'swipl %'
  endif
  if !has_key(g:executioner#extensions, 'py')
    let g:executioner#extensions['py'] = 'python3 %'
  endif
  if !has_key(g:executioner#extensions, 'py2')
    let g:executioner#extensions['py2'] = 'python2 %'
  endif
  if !has_key(g:executioner#extensions, 'R')
    let g:executioner#extensions['R'] = 'Rscript %'
  endif
  if !has_key(g:executioner#extensions, 'r')
    let g:executioner#extensions['r'] = 'Rscript %'
  endif
  if !has_key(g:executioner#extensions, 'rb')
    let g:executioner#extensions['rb'] = 'ruby %'
  endif
  if !has_key(g:executioner#extensions, 'rc')
    let g:executioner#extensions['rc'] = 'rustc % -o @.out;./@.out'
  endif
  if !has_key(g:executioner#extensions, 'sh')
    let g:executioner#extensions['sh'] = 'bash %'
  endif
  if !has_key(g:executioner#extensions, 'swift')
    let g:executioner#extensions['swift'] = 'swiftc % -o @.out;./@.out'
  endif

  if !has_key(g:executioner#names, 'makefile')
    let g:executioner#names['makefile'] = 'make'
  endif
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
  "   list parsed_input [string file, string name, string extension,
  "                      string args]
  " Returns:
  "   string the execute command of the parsed_input if executable
  "          "" if not executable
  if !filereadable(expand(a:parsed_input[s:FILE]))
    let s:command = s:INVALID_COMMAND
  elseif has_key(g:executioner#names, a:parsed_input[s:PATHLESS_NAME])
    let s:command = g:executioner#names[a:parsed_input[s:PATHLESS_NAME]]
          \ . a:parsed_input[s:ARGS]
  elseif has_key(g:executioner#extensions, a:parsed_input[s:EXTENSION])
    let s:command = g:executioner#extensions[a:parsed_input[s:EXTENSION]]
          \ . a:parsed_input[s:ARGS]
  else
    let s:command = s:INVALID_COMMAND
  endif

  " Substitute symbols
  let s:command = s:Substitute(s:command, g:executioner#base_name,
        \ a:parsed_input[s:NAME])
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
  endfor
  return s:new_string
endfunction

function! s:ParseInput(file_with_args) abort
  " Parses the input into its components
  " Parameters:
  "   string file_with_args - file name, optionally followed by arguments
  " Returns:
  "   list [string file, string name, string extension, string arguments,
  "         string pathless_name]

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

  " Remove path from name
  let s:directories = split(s:file[0], s:DIRECTORY_SEPARATOR)
  let s:pathless_name = s:directories[len(s:directories) - 1]

  " Remaining terms are arguments
  " Join all arguments back together with spaces
  let s:arguments = len(s:input_terms) > 1 ?
        \ " " . join(s:input_terms[1:], " ") : ""

  return [s:file_with_extension, s:file[0], s:file[1], s:arguments,
        \ s:pathless_name]
endfunction

function! s:ExecuteCommandShell(execute_command)
  execute "!" . a:execute_command
endfunction

function! s:GetSplitPrefixTerminal(split_type, execute_command)
  return (a:split_type == s:VERTICAL ? "vertical " : "") . "terminal "
endfunction

function! s:GetSplitPrefixBuffer(split_type)
  return (a:split_type == s:NONE ? "" : ".") . "!"
endfunction

function! s:ExecuteCommandTerminal(split_type, execute_command) abort
  execute  s:GetSplitPrefixTerminal(a:split_type, a:execute_command) . a:execute_command
endfunction

function! s:OpenBufferIfNotExists(split_type)
  let output_buffer_name = "Output"
  let buffer_split = a:split_type == s:VERTICAL ? 'vertical' : 'botright'
  " reuse existing buffer window if it exists otherwise create a new one
  if !exists("s:buffer_number") || !bufexists(s:buffer_number)
    silent execute buffer_split . ' new ' . output_buffer_name
    let s:buffer_number = bufnr('%')
  elseif bufwinnr(s:buffer_number) == -1
    silent execute buffer_split . ' new'
    silent execute s:buffer_number . 'buffer'
  elseif bufwinnr(s:buffer_number) != bufwinnr('%')
    silent execute bufwinnr(s:buffer_number) . 'wincmd w'
  endif
endfunction

function! s:ConfigureBuffer()
  let output_buffer_filetype = "output"
  silent execute "setlocal filetype=" . output_buffer_filetype
  setlocal bufhidden=delete
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal nobuflisted
  setlocal winfixheight
  setlocal cursorline " make it easy to distinguish
  setlocal nonumber
  setlocal norelativenumber
  setlocal showbreak=""
endfunction

function! s:SetBufferModifiable()
  " clear the buffer and make it modifiable for terminal output
  setlocal noreadonly
  setlocal modifiable
  %delete _
endfunction

function s:ExecuteCommandInBuffer(split_type, execute_command, file_name)
  echon 'Executing ' . a:file_name . ' ... '
  " Execute file
  execute s:GetSplitPrefixBuffer(a:split_type) . a:execute_command
endfunction

function s:SetBufferReadOnly()
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
endfunction

function! s:ExecuteCommandBuffer(split_type, execute_command, file_name) abort
  call s:OpenBufferIfNotExists(a:split_type)
  call s:ConfigureBuffer()
  call s:SetBufferModifiable()
  call s:ExecuteCommandInBuffer(a:split_type, a:execute_command, a:file_name)
  call s:SetBufferReadOnly()
endfunction

function! s:ExecuteCommand(split_type, execute_command, file_name) abort
  if a:split_type == s:NONE || (s:has_teriminal && a:execute_command =~ ';')
    call s:ExecuteCommandShell(a:execute_command)
  elseif s:has_teriminal
    call s:ExecuteCommandTerminal(a:split_type, a:execute_command)
  else
    call s:ExecuteCommandBuffer(a:split_type, a:execute_command, a:file_name)
  endif
endfunction

function! s:ParseArgs(has_teriminal, split_type, file_with_args)
  let s:has_teriminal = a:has_teriminal

  " Note: Temporary fix. If the command is multicommand (has semicolon),
  " Then the split type is changed to NONE later on
  let s:split_type = a:split_type

  " If no arguments after split type are specified, assume the current file
  " is being ran with no arguments.
  " Otherwise, assume the first argument is the file to be ran.
  let s:file_with_args = a:file_with_args != "" ? a:file_with_args : expand("%")
endfunction

function! s:SaveAndExecuteFile(...) abort
  " Since the user is not directly calling this, all arguments are guarenteed
  " Parameters:
  "   a:1 int has_teriminal
  "   a:2 char split_type
  "     s:NONE - No split (default)
  "     s:HORIZONTAL - Horizontal split
  "     s:VERTICAL - Vertical split
  "   a:3 string file_with_args
  "     default - current file
  "
  " SOURCE [reusable window]:
  " https://github.com/fatih/vim-go/blob/master/autoload/go/ui.vim

  call s:ParseArgs(a:1, a:2, a:3)

  " If not split, then output is terminal
  " Otherwise, the output replaces the current buffer contents
  let parsed_input = s:ParseInput(s:file_with_args)
  let execute_command = s:GetExecuteCommand(parsed_input)

  " If invalid execute_command then return early with error message
  if execute_command == s:INVALID_COMMAND
    execute "echo \"'" . parsed_input[s:NAME]
          \ . "' is not configured to be executable.\""
    return -1
  endif

  " Evaluate saving current buffer
  " Don't save and reload current file not in file
  if &filetype != ""
    silent execute "update | edit"
  endif

  " Finally execute command
  call s:ExecuteCommand(s:split_type, execute_command, parsed_input[s:FILE])
endfunction


" Create commands
command! -nargs=* Executioner                 :call s:SaveAndExecuteFile(s:has_teriminal, s:NONE, <q-args>)
command! -nargs=* ExecutionerVertical         :call s:SaveAndExecuteFile(s:has_teriminal, s:VERTICAL, <q-args>)
command! -nargs=* ExecutionerHorizontal       :call s:SaveAndExecuteFile(s:has_teriminal, s:HORIZONTAL, <q-args>)
command! -nargs=* ExecutionerVerticalBuffer   :call s:SaveAndExecuteFile(0, s:VERTICAL, <q-args>)
command! -nargs=* ExecutionerHorizontalBuffer :call s:SaveAndExecuteFile(0, s:HORIZONTAL, <q-args>)

let g:executioner#loaded = 1
