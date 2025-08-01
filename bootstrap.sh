#!/bin/bash

# Install neovim
cd ~
echo "Installing neovim, you will have to enter your password to sudo"
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

echo "export PATH=\$PATH:/opt/nvim-linux-x86_64/bin" >> ~/.bashrc

git clone https://github.com/theonlyguills/configs

mkdir ~/.config
cp ~/configs/nvim ~/.config -r

sudo apt update
sudo apt install ripgrep

echo "Installing taskfile"
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin
sudo cp ~/.local/bin/task /usr/local/bin/

echo "alias t=task" >> ~/.bashrc
echo "alias tl=\"task --list-all\"" >> ~/.bashrc
echo "alias vi=nvim" >> ~/.bashrc
echo "alias vim=nvim" >> ~/.bashrc

source ~/.bashrc

cd ~/configs
task

