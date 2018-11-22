# :sunrise_over_mountains: vim-executioner

This plugin allows you to easily execute files in the terminal or a separate
buffer.

![](https://raw.githubusercontent.com/wiki/EvanQuan/vim-executioner/executioner.PNG)

## Installation

Install using your favorite package manager, or use Vim's built-in package
support:

#### Vim 8 Native Package Manager

```bash
mkdir ~/.vim/pack/plugin/start/vim-executioner
git clone https://github.com/EvanQuan/vim-executioner.git ~/.vim/pack/plugin/start/vim-executioner
```

#### [Vim-Plug](https://github.com/junegunn/vim-plug)

1. Add `Plug 'EvanQuan/vim-executioner'` to your vimrc file.
2. Reload your vimrc or restart.
3. Run `:PlugInstall`

#### [Vundle](https://github.com/VundleVim/Vundle.vim)

1. Add `Plugin 'EvanQuan/vim-executioner'` to your vimrc file.
2. Reload your vimrc or restart.
3. Run `:BundleInstall`

#### [NeoBundle](https://github.com/Shougo/neobundle.vim)

1. Add `NeoBundle 'EvanQuan/vim-executioner'` to your vimrc file.
2. Reload your vimrc or restart.
3. Run `:NeoUpdate`

#### [Pathogen](https://github.com/tpope/vim-pathogen)

```bash
git clone https://github.com/EvanQuan/vim-executioner.git ~/.vim/bundle/vim-executioner
```

## Usage

This package comes with 3 commands:

- `:Executioner`
- `:ExecutionerHorizontal`
- `:ExecutionerVertical`

Each command takes the name of a file as an 1 optional argument. Without any
arguments, the current buffer that is executing the command will be ran.

For example:
```
:Executioner test.py
```
will attempt to execute `test.py` in the current working directory, while
```
:Executioner
```
will attempt to execute the current buffer.

If you running a version of Vim that has the integrated terminal feature (i.e.
`:echo has("terminal")` returns 1), then the horizontal and vertical commands
open a terminal buffer to output the command, allowing for potential user
input.

Without the terminal feature available, the horizontal and vertical commands
stores the output of the executed program in a readonly buffer. Due to this
reason, it will not work for programs that require user input.

## Configure Executable Files

There are 2 dictionaries that define what types of files can be executed:

With `g:executioner#extensions`, Executioner can execute a command based on the
extension of a file name. With `g:executioner#names`, Executioner can execute
a command based on a file name. If not defined in your `.vimrc`, they are
by default defined as:

```vim
" extension : <command
" Command is executed with file as argument
"     $ command filename.extension
let g:executioner#extensions = {
                               \ 'R'  : 'Rscript',
                               \ 'hs'  : 'ghci',
                               \ 'js' : 'node',
                               \ 'py' : 'python3',
                               \ 'sh' : 'bash',
                               \}

" file name : command
" Command is executed with no arguments
"     $ command
let g:executioner#names = {
                          \ 'makefile': 'make',
                          \}
```

`g:executioner#extensions` determines commands by file extension. For example,
if you want to execute files with the `.foo` extension, such as
`hello_world.foo`, with the `bar` command, (i.e. executing `bar
hello_world.foo` in the terminal), then the value `'foo' : 'bar'` must be
included in this dictionary.

`g:executioner#names` determines commands by file name. For example, if you want
to execute files with the name `delete_me.txt` with the command `rm
delete_me.txt`, then the value `'delete_me.txt' : 'rm delete_me.txt'` must be
included in this dictionary.

Executioner will prioritize names over extensions when determining what command
to use. For example: if `g:executioner#extensions` dictates that `py` files are
to be executed with `python3` and `g:executioner#names` dictates that `foo.py`
is to be executed with `python2`, then `foo.py` will be executed with
`python2`.
