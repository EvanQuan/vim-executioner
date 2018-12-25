# :sunrise_over_mountains: vim-executioner

This plugin allows you to easily execute files in the terminal or a separate
buffer.

**Note: This has not currently been tested for Vim 7 or earlier. Progress is being made for backwards compatibility.**

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

This package comes with 3 commands:

- `:Executioner`
- `:ExecutionerHorizontal`
- `:ExecutionerVertical`

Each command takes the name of a file as an 1 optional argument, optionally
followed by any command-line arguments. Without any arguments, the current
buffer that is executing the command will be ran with no arguments.

For example:
```
:Executioner
```
will attempt to execute the current buffer.
```
:Executioner test.py
```
will attempt to execute `test.py` in the current working directory.
```
:Executioner test.py foo bar 4
```
will attempt to execute `test.py` in the current working directory, with the
arguments `foo`, `bar` and `4`.

If you running a version of Vim that has the integrated terminal feature (i.e.
`:echo has("terminal")` returns 1), then the horizontal and vertical commands
open a terminal buffer to output the command, allowing for potential user
input.

Without the terminal feature available, the horizontal and vertical commands
stores the output of the executed program in a read-only buffer. Due to this
reason, it will not work for programs that require user input.

#### Key mappings

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
