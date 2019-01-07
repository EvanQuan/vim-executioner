# :sunrise_over_mountains: vim-executioner

This plugin allows you to execute files in a terminal window or a separate
buffer.

![](https://raw.githubusercontent.com/wiki/EvanQuan/vim-executioner/executioner.PNG)

Table of Contents
-----------------
1. [Installation](#installation)
2. [Usage](#usage)
    - [Commands](#commands)
    - [Key mappings](#key-mappings)
3. [Configure Executable Files](#configure-executable-files)
    - [Full and base name symbols](#full-and-base-name-symbols)
    - [Commands](#commands-1)
4. [Configuration Ideas](#configuration-ideas)

## Installation

Install using your favorite package manager, or use Vim's built-in package
support:

#### Vim 8 Native Package Manager

```bash
mkdir ~/.vim/pack/plugin/start/vim-executioner
git clone https://github.com/EvanQuan/vim-executioner.git ~/.vim/pack/plugin/start/vim-executioner
```

#### [Vim-Plug](https://github.com/junegunn/vim-plug)

1. Add `Plug 'EvanQuan/vim-executioner'` to your `vimrc` file.
2. Reload your `vimrc` or restart.
3. Run `:PlugInstall`

#### [Vundle](https://github.com/VundleVim/Vundle.vim)

1. Add `Plugin 'EvanQuan/vim-executioner'` to your `vimrc` file.
2. Reload your `vimrc` or restart.
3. Run `:BundleInstall`

#### [NeoBundle](https://github.com/Shougo/neobundle.vim)

1. Add `NeoBundle 'EvanQuan/vim-executioner'` to your `vimrc` file.
2. Reload your `vimrc` or restart.
3. Run `:NeoUpdate`

#### [Pathogen](https://github.com/tpope/vim-pathogen)

```bash
git clone https://github.com/EvanQuan/vim-executioner.git ~/.vim/bundle/vim-executioner
```

## Usage

#### Commands

This plugin comes with 5 commands:

Each command takes the name of a file as an optional argument, optionally
followed by any command-line arguments. Without any arguments, the current
buffer that is executing the command will be ran with no arguments.

##### :Executioner

The file will be executed in a shell, where any output will be printed there.
For example:
```
:Executioner
```
will attempt to execute the current buffer with no command-line arguments.
```
:Executioner test.py
```
will attempt to execute `test.py` in the current working directory with no
command-line arguments.
```
:Executioner test.py foo bar 4
```
will attempt to execute `test.py` in the current working directory, with the
command-line arguments `foo`, `bar` and `4`.

##### :ExecutionerHorizontal

If Vim has `terminal` window support, then the file will be executed in
a horizontally-split terminal window. Once the program execution is completed,
the output will be saved in a 'readonly' buffer.

Otherwise, the file will be executed in a shell and its output will be saved
in a horizontally-split 'readonly' buffer. The difference is that without
|terminal| support, no input from the user can be made during the program's
runtime.

##### :ExecutionerHorizontalBuffer

Same as `:ExecutionerHorizontal` with no |terminal| window support, forcing
a shell to execute the file and save the output in a horizontally-split
'readonly' buffer.

##### :ExecutionerVertical

If Vim has `terminal` window support, then the file will be executed in
a vertically-split terminal window. Once the program execution is completed,
the output will be saved in a 'readonly' buffer.

Otherwise, the file will be executed in a shell and its output will be saved
in a vertically-split 'readonly' buffer. The difference is that without
`terminal` support, no input from the user can be made during the program's
runtime.

##### :ExecutionerVerticalBuffer

Same as `:ExecutionerVertical` with no `terminal` window support, forcing
a shell to execute the file and save the output in a vertically-split
'readonly' buffer.

#### Terminal Window vs. Buffer

There are advantages and disadvantages to using either the terminal or buffer
for split window execution. Perhaps some day in the future this distinction
will no longer exist and there will be a unified solution.

|      | Terminal | Buffer |
|:----:|:--------:|:------:|
| Pros | - Accepts standard input from user <br> - Prints standard output during program execution | - Can execute multiple commands directly <br> - Accepts standard input and output redirection |
| Cons | - Cannot execute multiple commands directly <br> - Does not accept standard input and output redirection | - Does not accept standard input from user <br> - Prints standard output after program execution is complete |

##### Standard Input and Standard Output

If you running a version of Vim that has terminal window support, (i.e. `:echo
has("terminal")` returns `1`), then the horizontal and vertical commands open
an interactive terminal window which updates live as the program is being
executed. This allows for user input from standard input, and displaying of
standard output as it is being printed.

Without the terminal feature available, the horizontal and vertical commands
run the program until completion, and store the standard output of the
executed program in a read-only buffer. Due to this reason, it will not work
for programs that require user input and will not update the standard output
over the course of the program execution.

##### Multiple Commands

Certain file types that involve multiple commands to be executed, such as
compiling before executing, do not work with terminal windows. This is because
terminal windows treat every space-separated term after the first argument as
command-line arguments, including ones that end with `;`.

Any terminal window command that involves multiple commands will fall back to
the buffer equivalent if multiple commands are found.

##### Input and Output Redirection

For the same reason as multiple commands, terminal windows treat every
space-separated term after the first argument as a command-line argument,
including `>`, `<`, and `|` characters.

Any terminal window command that involves input redirection will fall back to
the buffer equivalent if input redirection operators are found.

#### Vim Commands

If any executing command defined in `g:executioner#extensions` or
`g:executioner#names` starts with ':', a Vim command will be executed instead
of a shell, terminal window, or buffer. For example, if the following is
defined in your `vimrc`:
```vim
let g:executioner#extensions['md'] = ':InstantMarkdownPreview'
let g:executioner#extensions['markdown'] = ':InstantMarkdownPreview'
```
then running any markdown files with any of the executioner commands will
execute the Vim command `:InstantMarkdownPreview`.

#### Key Mappings

By default, Executioner does not provide any key mappings as to not override
mappings defined in your `vimrc`. You can map these commands to however you
like to make them easier to use.

For example, I personally use:

```vim
" Run current buffer
"
nnoremap <silent> <leader>rf :Executioner<Return>
nnoremap <silent> <leader>hrf :ExecutionerHorizontal<Return>
nnoremap <silent> <leader>vrf :ExecutionerVertical<Return>

" Run current buffer with input redirected from input.txt
"
nnoremap <silent> <leader>ri :ExecutionerBuffer % < input.txt<Return>
nnoremap <silent> <leader>hri :ExecutionerHorizontalBuffer % < input.txt<Return>
nnoremap <silent> <leader>vri :ExecutionerVerticalBuffer % < input.txt<Return>

" run.sh
"
nnoremap <silent> <leader>rr :Executioner run.sh<Return>
nnoremap <silent> <leader>hrr :ExecutionerHorizontal run.sh<Return>
nnoremap <silent> <leader>vrr :ExecutionerVertical run.sh<Return>

" Makefile
"
nnoremap <silent> <leader>rm :Executioner makefile<Return>
nnoremap <silent> <leader>hrm :ExecutionerHorizontal makefile<Return>
nnoremap <silent> <leader>vrm :ExecutionerVertical makefile<Return>
```

Due to the complexity of many projects that span a large number of files,
I use makefiles and `run.sh` to compile and run code without needing to worry
about what file I'm currently editing.

## Configure Executable Files

#### Full and base name symbols

You may want to refer to the full file name or base name in in your commands.
The full file name, which is the base name with file extension, can be
referred to by `g:executioner#full_name`, while the base name can be referred
to by `g:executioner#base_name`, both which you can set in your `vimrc`. By
default they are defined as:

 ```vim
let g:executioner#full_name = '%'
let g:executioner#base_name = '@'
 ```

For example, if you want to run a C file by compiling it first, you can define
its command as `'c'  : 'gcc % -o @.out; ./@.out'` in `g:executioner#commands`,
which will compile a `.out` file with the same base name as the source file,
and then execute it.

#### Commands

There are 2 dictionaries that define what types of files can be executed:

`g:executioner#extensions` determines commands by file extension. For example,
if you want to execute files with the `py` extension, such as
`hello_world.py`, with the `python` command, (i.e. executing `python
hello_world.py` in the terminal), then include:
```vim
let g:executioner#extensions['py'] = 'python %'
```
in your `vimrc`.

`g:executioner#names` determines commands by file name. For example, if you
want to execute files with the name `makefile` with the command `make`, then
include:
```vim
let g:executioner#names['makefile'] = 'make'
```
in your `vimrc`.

Executioner will prioritize names over extensions when determining what
command to use. For example, if
```vim
let g:executioner#extensions['py'] = 'python3 %'
```
dictates that `py` files are to be executed with `python3` and
```vim
let g:executioner#names['foo.py'] = 'python2 foo.py'
```
dictates that `foo.py` is to be executed with `python2`, then `foo.py` will be
executed with `python2`.

Luckily, many of these commands are already defined so you don't need to do so
yourself. These are the defaults:

##### g:executioner#extensions
| Extension | Command                   |
|:---------:|:-------------------------:|
| c         | gcc % -o @.out;./@out     |
| cpp       | g++ % -o @.out;./@out     |
| hs        | ghci %                    |
| java      | javac %;java @            |
| js        | node %                    |
| m         | matlab                    |
| ml        | ocaml % -o @.out;./@.out  |
| php       | php %                     |
| pl        | perl %                    |
| prolog    | swipl %                   |
| py        | python %                  |
| py2       | python2 %                 |
| R         | Rscript %                 |
| r         | Rscript %                 |
| rb        | ruby %                    |
| rc        | rustc % -o @.out;./@.out  |
| sh        | bash %                    |
| swift     | swiftc % -o @.out;./@.out |

##### g:executioner#names
| Name     | Command  |
|:--------:|:--------:|
| makefile | make     |

As expected, if any of these extensions or file names are defined in your
`vimrc`, they will take precedence over the defaults.

If you wish to disable these defaults entirely, include:
```vim
let g:executioner#load_defaults = 0
```
in your `vimrc` and they will not be defined.

## Configuration Ideas

Depending on the machine I'm on, the `python` command either runs Python 2 or
Python 3. Also, I sometimes have Anaconda installed, which I will want to use
if possible. As a result, I customize what version of Python runs depending on
some other settings I have:
```vim
let g:executioner#extensions = {}
if g:settings#python3_execution == 0
  let g:executioner#extensions['py'] = 'python %'
elseif filereadable(expand('/anaconda3/bin/python'))
  let g:executioner#extensions['py'] = '/anaconda3/bin/python %'
else
  let g:executioner#extensions['py'] = 'python3 %'
endif
```
With the help of
[vim-instant-markdown](https://github.com/suan/vim-instant-markdown), I can
preview github-flavored markdown files. Since the preview command is ran in
Vim itself and not in a |shell|, I can prepend the command with ":" to signify
I want to run a Vim command:
```vim
let g:executioner#extensions['markdown'] = ':InstantMarkdownPreview'
let g:executioner#extensions['md'] = ':InstantMarkdownPreview'
```
