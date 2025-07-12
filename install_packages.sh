#!/usr/bin/env bash

set -e
set -o pipefail

echo "📦 Installing packages: fzf, neovim, tmux..."

PACKAGES=(
  fzf
  neovim
  tmux
)

for pkg in "${PACKAGES[@]}"; do
  if ! pacman -Qi "$pkg" &> /dev/null; then
    echo "➡️  Installing $pkg..."
    sudo pacman -S --noconfirm "$pkg"
  else
    echo "✅ $pkg already installed."
  fi
done

# Setup Neovim config from your fork
NVIM_CONFIG_DIR="$HOME/.config/nvim"
KICKSTART_REPO="https://github.com/javierdebug/kickstart.nvim"

if [ -d "$NVIM_CONFIG_DIR" ]; then
  echo "🗑️  Removing existing Neovim config..."
  rm -rf "$NVIM_CONFIG_DIR"
fi

echo "📥 Cloning your LazyVim fork..."
git clone "$KICKSTART_REPO" "$NVIM_CONFIG_DIR"

echo "🎉 Done! Launch Neovim to finish plugin setup: nvim"

#Link .bashrc from dotfiles
echo "🔗 Linking custom .bashrc"
if [ -f "$HOME/.bashrc" ]; then
  echo "Backing up existing ~/.bashrc to ~/.bashrc.bak"
  mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
fi
ln -sf "$HOME/dotfiles/bash/.bashrc" "$HOME/.bashrc"

# Setup FZF config:
echo "🔧 Setting up FZF config"
if [ -f "$HOME/.fzf.bash" ]; then
  echo "🛑 Backing up existing ~/.fzf.bash to ~/.fzf.bash.backup"
  mv "$HOME/.fzf.bash" "$HOME/.fzf.bash.backup"
fi

cp "$HOME/dotfiles/fzf/.fzf.bash" "$HOME/.fzf.bash"

