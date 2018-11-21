# :sunrise_over_mountains: vim-executioner

This plugin allows you to easily execute files in the terminal or a separate
buffer.

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

The horizontal and vertical commands stores the output of the executed program
in a readonly buffer, either horizontally or vertically split. Due to this
reason, it will not work for programs that read from standard input.

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
                            \ 'py' : 'python3',
                            \ 'sh' : 'bash',
                            \ 'R' : 'Rscript',
                            \ 'js' : 'node',
                            \}

" file name : command
" Command is executed with no arguments
"     $ command
let g:executioner#names = {
                          \ 'makefile': 'make',
                          \}
```
