#!/bin/bash

# Install neovim
cd ~
echo "Installing neovim..."
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

echo 'export PATH="$PATH:/opt/nvim-linux-x86_64/bin"' >> ~/.bashrc
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

# Install LazyVim (starter config) instead of the old custom nvim config
echo "Installing LazyVim..."
# build-essential = C compiler for treesitter parsers; ripgrep for telescope
sudo apt-get update
sudo apt-get install -y build-essential ripgrep
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
# Pre-install plugins headlessly (quietly); first launch finishes any async tooling
nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || true

git clone https://github.com/theonlyguills/configs

echo "Installing taskfile"
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin
sudo cp ~/.local/bin/task /usr/local/bin/

echo "alias t=task" >> ~/.bashrc
echo "alias tl=\"task --list-all\"" >> ~/.bashrc
echo "alias vi=nvim" >> ~/.bashrc
echo "alias vim=nvim" >> ~/.bashrc

cd ~/configs
task

