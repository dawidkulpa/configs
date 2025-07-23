#!/bin/bash

script_dir=$(dirname "$(realpath "$0")")
get_parent_process_name() {
  ps -o comm= $PPID
}

if ! [ -x "$(command -v brew)" ]; then
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
   else
     brew update
     brew upgrade
   fi

if ! [ -x "$(command -v brew)" ]; then
  echo "Brew is not installed"
  exit 0
fi

configs=("fish" "btop" "wezterm" "starship.toml")
base_path="$HOME/.config"

for dir in "${configs[@]}"; do
    target_dir="$base_path/$dir"
    link_dir="$script_dir/.config/$dir"
    
    if [ -d "$target_dir" ]; then
        echo "Directory $target_dir exists."
    else
        ln -s "$link_dir" "$target_dir"
        echo "Symbolic link created from $link_dir to $target_dir."
    fi
done


brew install --cask wezterm
brew install fish

#Check if run from fish shell
if [[ ! "$(get_parent_process_name)" = *"fish"* ]]; then
  echo "Close the terminal, open it again and run fish. Run this script again afterwards."
  exit 0 
fi

# Install My Tools
brew install starship
brew install fd
brew install ripgrep
brew install fzf
brew install eza
brew install jq
brew install unzip
brew install curl
brew install btop
brew install oven-sh/bun/bun
brew install wget
brew install helix
brew install zoxide
brew install tealdeer
brew install bat
brew install thefuck
brew install fnm
brew install --cask marta
brew install go

# Helix LSPs
npm i -g typescript-language-server typescript
npm i -g vscode-langservers-extracted
pip3 install "python-lsp-server[all]" --break-system-packages --user
brew install markdown-oxide
brew install JetBrains/utils/kotlin-lsp
go install golang.org/x/tools/gopls@latest
npm i -g @microsoft/compose-language-service
npm i -g bash-language-server
brew install yaml-language-server

# Clean Up Brew
brew cleanup

# configures a global .gitignore
ln -s "$script_dir/.gitignore" ~/.gitignore
echo "Symbolic link created from $script_dir/.gitignore to ~/.gitignore."
git config --global core.excludesFile ~/.gitignore
