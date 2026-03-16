#!/bin/bash
set -e

cp .vimrc .vim ~/

yes | python3 ~/.vim/plugged/YouCompleteMe/install.py --all

echo "Installation completed"
