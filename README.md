# vim-executioner

This plugin allows you to easily execute files in the terminal or a separate
buffer.

## Installation

Install using your favorite package manager, or use Vim's built-in package
support:

#### Vim 8 native package manager

```bash
git clone https://github.com/EvanQuan/vim-executioner.git ~/.vim/pack/plugin/start/vim-executioner
```

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
