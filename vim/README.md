# VIMrc with plugins

# Installation

Just copy the files to your $HOME.
```
cp .vimrc .vim ~/
```

install YCM server:
```
cd ~/.vim/plugged/YouCompleteMe
python3 install.py --all
```

and run ``:PlugInstall`` inside VIM.

or just run the ``./install.sh``

# Installed plugins

## UI
- 'scrooloose/nerdtree'
- 'jistr/vim-nerdtree-tabs'
- 'majutsushi/tagbar'

## themes
- 'vim-airline/vim-airline'
- 'vim-airline/vim-airline-themes'

## git
- 'tpope/vim-fugitive'
- 'tpope/vim-rhubarb' " required by fugitive to :Gbrowse
- 'airblade/vim-gitgutter'

- 'editor-bootstrap/vim-bootstrap-updater'
- 'tomasiser/vim-code-dark'

- 'Shougo/vimproc.vim', {'do': g:make}

## session
- 'xolox/vim-misc'
- 'xolox/vim-session'

## snippets
- 'SirVer/ultisnips'
- 'honza/vim-snippets'

## workflow
- 'tpope/vim-commentary'
- 'vim-scripts/grep.vim'
- 'vim-scripts/CSApprox'
- 'Raimondi/delimitMate'
- 'dense-analysis/ale'
- 'Yggdroot/indentLine'

## c
- 'vim-scripts/c.vim', {'for': ['c', 'cpp']}
- 'ludwig/split-manpage.vim'

## go
- 'fatih/vim-go', {'do': ':GoInstallBinaries'}

## hs
- 'eagletmt/neco-ghc'
- 'dag/vim2hs'
- 'pbrisbin/vim-syntax-shakespeare'

## lua
- 'xolox/vim-lua-ftplugin'
- 'xolox/vim-lua-inspect'

## rs
- 'racer-rust/vim-racer'
- 'rust-lang/rust.vim'

## lsp
- 'prabirshrestha/async.vim'
- 'prabirshrestha/vim-lsp'
- 'ycm-core/YouCompleteMe'
