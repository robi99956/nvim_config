#!/bin/bash

set -e

if [ $(id -u) == 0 ]; then
    echo "Run this as normal user!"
    exit -1
fi

# install vimplug
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# link config, delete old
rm -r ~/.config/nvim
ln -s nvim ~/.config/nvim

# Install node (coc potrzebuje)
curl -sL install-node.vercel.app/lts | bash

# lang server dla C/C++
sudo apt install ccls
# zaklecie do indeksowania projektow (bear make ...)
sudo apt install bear
