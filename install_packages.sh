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
if [ -f "$HOME/.bashrc.backup" ]; then
  echo "⚠️  Removing previous ~/.bashrc.backup"
  rm -f "$HOME/.bashrc.backup"
fi
if [ -f "$HOME/.bashrc" ]; then
  echo "Backing up existing ~/.bashrc to ~/.bashrc.bak"
  mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
fi
cp "$HOME/dotfiles/bash/.bashrc" "$HOME/.bashrc"

# Setup FZF config:
echo "🔧 Setting up FZF config"
if [ -f "$HOME/.fzf.bash.backup" ]; then
  echo "⚠️  Removing previous ~/.fzf.bash.backup"
  rm -f "$HOME/.fzf.bash.backup"
fi
if [ -f "$HOME/.fzf.bash" ]; then
  echo "🛑 Backing up existing ~/.fzf.bash to ~/.fzf.bash.backup"
  mv "$HOME/.fzf.bash" "$HOME/.fzf.bash.backup"
fi

cp "$HOME/dotfiles/fzf/.fzf.bash" "$HOME/.fzf.bash"

# Copy .fzf folder
echo "📁 Copying .fzf folder to home directory"
if [ -d "$HOME/.fzf.backup" ]; then
  echo "⚠️  Removing previous ~/.fzf.backup"
  rm -rf "$HOME/.fzf.backup"
fi
if [ -d "$HOME/.fzf" ]; then
  echo "🛑 Backing up existing ~/.fzf to ~/.fzf.backup"
  mv "$HOME/.fzf" "$HOME/.fzf.backup"
fi
# Extract .fzf.tar to ~/.fzf
echo "📦 Extracting .fzf.tar"
tar -xf "$HOME/dotfiles/fzf/.fzf.tar" -C "$HOME"

cp -r "$HOME/dotfiles/fzf/.fzf" "$HOME/.fzf"

# Setup tmux config
echo "🔧 Setting up tmux config"
if [ -f "$HOME/.tmux.conf.backup" ]; then
  echo "⚠️  Removing previous ~/.tmux.conf.backup"
  rm -f "$HOME/.tmux.conf.backup"
fi
if [ -f "$HOME/.tmux.conf" ]; then
  echo "🛑 Backing up existing ~/.tmux.conf to ~/.tmux.conf.backup"
  mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup"
fi

cp "$HOME/dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"

# Copy tmux session files (if used manually)
echo "📁 Copying tmux session files"
mkdir -p "$HOME/.tmux-sessions"
cp -r "$HOME/dotfiles/tmux/.tmux-sessions/"* "$HOME/.tmux-sessions" 2>/dev/null || true

# Copy tmux selector helper script
echo "📁 Copying tmux_selector.sh to home directory"
if [ -f "$HOME/tmux_selector.sh.backup" ]; then
  echo "⚠️  Removing previous ~/tmux_selector.sh.backup"
  rm -f "$HOME/tmux_selector.sh.backup"
fi
cp "$HOME/dotfiles/tmux/tmux_selector.sh" "$HOME/tmux_selector.sh"
chmod +x "$HOME/tmux_selector.sh"

