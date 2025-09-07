#!/usr/bin/env bash

set -e
set -o pipefail

if ! grep -rq "neovim-ppa/unstable" /etc/apt/sources.list; then
  echo "📦 Adding Neovim PPA to get the latest version..."
  sudo add-apt-repository -y ppa:neovim-ppa/unstable
  sudo apt-get update -y
fi 

echo "📦 Installing packages: fzf, neovim, tmux, nodejs, npm, bash-completion, copyq, flameshot, git..."

PACKAGES=(
  fzf
  neovim
  tmux
  nodejs
  npm
  bash-completion
  copyq
  flameshot
  git
  rofi
  bspwm
  sxhkd
  polybar
  feh
  xautolock
  i3lock
)

install_with_apt() {
  local to_install=()
  for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
      echo "➡️  Will install $pkg"
      to_install+=("$pkg")
    else
      echo "✅ $pkg already installed."
    fi
  done

  if [ "${#to_install[@]}" -gt 0 ]; then
    echo "🔄 Running apt update..."
    sudo apt-get update -y
    echo "⬇️  Installing: ${to_install[*]}"
    sudo apt-get install -y "${to_install[@]}"
  else
    echo "👍 All required packages already present."
  fi
}

# Istall Brave browser
echo "📥 Installing Brave browser..."
# check if brave is already installed
if ! command -v brave >/dev/null 2>&1; then
  curl -fsS https://dl.brave.com/install.sh | sh
fi

# Detect package manager (Linux Mint uses apt)
if command -v apt-get >/dev/null 2>&1; then
  install_with_apt
else
  echo "❌ This script is set up for Debian/Ubuntu/Mint (apt)."
  echo "   Your system doesn't seem to have apt-get."
  exit 1
fi

# Create custom folder structure for Projects:
mkdir -p "$HOME/Documents/JV/Code/WonderCraft/Projects/Axon/green-field"
mkdir -p "$HOME/Documents/JV/Code/Dev/202X/"

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

# Link .bashrc from dotfiles
echo "🔗 Linking custom .bashrc"
if [ -f "$HOME/.bashrc.backup" ]; then
  echo "⚠️  Removing previous ~/.bashrc.backup"
  rm -f "$HOME/.bashrc.backup"
fi
if [ -f "$HOME/.bashrc" ]; then
  echo "🗃️  Backing up existing ~/.bashrc to ~/.bashrc.bak"
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
if [ -f "$HOME/dotfiles/fzf/.fzf.tar" ]; then
  echo "📦 Extracting .fzf.tar"
  tar -xf "$HOME/dotfiles/fzf/.fzf.tar" -C "$HOME"
else
  echo "⚠️  Skipping .fzf extraction (archive not found at ~/dotfiles/fzf/.fzf.tar)"
fi

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

# Remove previous backup if it exists
if [ -d "$HOME/.tmux.backup" ]; then
  echo "⚠️  Removing previous ~/.tmux.backup"
  rm -rf "$HOME/.tmux.backup"
fi

# Backup current .tmux if it exists
if [ -d "$HOME/.tmux" ]; then
  echo "🛑 Backing up ~/.tmux to ~/.tmux.backup"
  mv "$HOME/.tmux" "$HOME/.tmux.backup"
fi

# Extract tmux.tar into $HOME (creates ~/.tmux)
if [ -f "$HOME/dotfiles/tmux/.tmux.tar" ]; then
  echo "📦 Extracting tmux.tar"
  tar -xf "$HOME/dotfiles/tmux/.tmux.tar" -C "$HOME"
else
  echo "⚠️  Skipping tmux extraction (archive not found at ~/dotfiles/tmux/.tmux.tar)"
fi

# Copy tmux session files (if used manually)
echo "📁 Copying tmux session files"
mkdir -p "$HOME/.tmux-sessions"
cp -r "$HOME/dotfiles/tmux/.tmux-sessions/"* "$HOME/.tmux-sessions" 2>/dev/null || true

# ── NEW: bspwm & sxhkd config ────────────────────────────────────────────────
echo "🧩 Setting up bspwm and sxhkd configs"

# Create config dirs
mkdir -p "$HOME/.config/bspwm"
mkdir -p "$HOME/.config/sxhkd"
mkdir -p "$HOME/rofi"

# Remove old backup of bspwm config if it exists
if [ -d "$HOME/.config/bspwm.backup" ]; then
  echo "⚠️  Removing old backup at ~/.config/bspwm.backup"
  rm -rf "$HOME/.config/bspwm.backup"
fi

# Backup existing configs if present
if [ -d "$HOME/.config/bspwm" ]; then
  echo "🗃️  Backing up existing ~/.config/bspwm to ~/.config/bspwm.backup"
  mv "$HOME/.config/bspwm" "$HOME/.config/bspwm.backup"
fi
if [ -d "$HOME/dotfiles/bspwm" ]; then
  echo "📁 Copying bspwm config from ~/dotfiles/bspwm → ~/.config/bspwm"
  cp -a "$HOME/dotfiles/bspwm/." "$HOME/.config/bspwm"
  if [ -f "$HOME/.config/bspwm/bspwmrc" ]; then
    chmod +x "$HOME/.config/bspwm/bspwmrc"
  fi
else
  echo "⚠️  Skipped: ~/dotfiles/bspwm not found."
fi

# Remove old backup of sxhkd config if it exists
if [ -d "$HOME/.config/sxhkd.backup" ]; then
  echo "⚠️  Removing old backup at ~/.config/sxhkd.backup"
  rm -rf "$HOME/.config/sxhkd.backup"
fi

# Backup existing configs if present
if [ -d "$HOME/.config/sxhkd" ]; then
  echo "🗃️  Backing up existing ~/.config/sxhkd to ~/.config/sxhkd.backup"
  mv "$HOME/.config/sxhkd" "$HOME/.config/sxhkd.backup"
fi
if [ -d "$HOME/dotfiles/sxhkd" ]; then
  echo "📁 Copying sxhkd config from ~/dotfiles/sxhkd → ~/.config/sxhkd"
  cp -a "$HOME/dotfiles/sxhkd/." "$HOME/.config/sxhkd"
else
  echo "⚠️  Skipped: ~/dotfiles/sxhkd not found."
fi

# Remove old backup of polybar config if it exists
if [ -d "$HOME/.config/polybar.backup" ]; then
  echo "⚠️  Removing old backup at ~/.config/polybar.backup"
  rm -rf "$HOME/.config/polybar.backup"
fi

if [ -d "$HOME/.config/polybar" ]; then
  echo "🗃️  Backing up existing ~/.config/polybar to ~/.config/polybar.backup"
  mv "$HOME/.config/polybar" "$HOME/.config/polybar.backup"
fi
cp -a "$HOME/dotfiles/polybar/." "$HOME/.config/polybar"

# Copy rofi selector helper script
echo "📁 Copying rofi web search script to rofi folder"
if [ -f "$HOME/rofi/rofi-web-search.py.backup" ]; then
  echo "⚠️  Removing previous ~/rofi/rofi-web-search.py.backup"
  rm -f "$HOME/rofi/rofi-web-search.py.backup"
fi
  echo "📁 Copying rofi web search script to rofi folder"
cp "$HOME/dotfiles/rofi/rofi-web-search.py" "$HOME/rofi/rofi-web-search.py"
chmod +x "$HOME/rofi/rofi-web-search.py"

# Copy tmux selector helper script
echo "📁 Copying tmux_selector.sh to home directory"
if [ -f "$HOME/tmux_selector.sh.backup" ]; then
  echo "⚠️  Removing previous ~/tmux_selector.sh.backup"
  rm -f "$HOME/tmux_selector.sh.backup"
fi
cp "$HOME/dotfiles/tmux/tmux_selector.sh" "$HOME/tmux_selector.sh"
chmod +x "$HOME/tmux_selector.sh"

# Update theme to Mint-Y-Dark-Aqua

# Remove old backup of polybar config if it exists
if [ -d "$HOME/.config/gtk-3.0/settings.ini.backup" ]; then
  echo "⚠️  Removing old backup at ~/.config/gtk-3.0/settings.ini.backup"
  rm -rf "$HOME/.config/gtk-3.0/settings.ini.backup"
fi
echo "🎨 Updating theme to Mint-Y-Dark-Aqua"
if [ -d "$HOME/.config/gtk-3.0" ]; then
  echo "🗃️  Backing up existing ~/.config/gtk-3.0/settings.ini to ~/.config/gtk-3.0/settings.ini.backup"
  mv "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini.backup"
else
  echo "⚠️  Skipped: ~/.config/gtk-3.0/settings.ini not found."
  echo "🎨 Creating ~/.config/gtk-3.0/settings.ini file" 
  cp -a "$HOME/dotfiles/gtk-3.0/." "$HOME/.config/gtk-3.0"
fi

# Clone wallpapers repo
mkdir -p "$HOME/Documents/JV/Wallpapers/"
echo "📥 Cloning wallpapers repo"
git clone https://gitlab.com/dwt1/wallpapers.git "$HOME/Documents/JV/Wallpapers/"

echo "✅ Setup complete."

