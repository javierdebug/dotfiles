#!/bin/bash

# Define your specific project folders
declare -a PROJECTS=(
  "$HOME/Documents/JV/Code/Dev/202X/jvbot/"
  "$HOME/Documents/JV/Code/Dev/202X/portfolioJV/"
  "$HOME/Documents/JV/dotfiles/dotfiles"
  "$HOME/Documents/JV/Code/WonderCraft/Projects/Axon/green-field/axon-marketing-wondercraft-green-field/"
)

# Show the list in fzf and store selection
project_path=$(printf "%s\n" "${PROJECTS[@]}" | fzf --prompt="Select project: ")

# Exit if no selection
[ -z "$project_path" ] && echo "No folder selected." && return 1

# Change to selected folder
cd "$project_path"

# # Start nvim
# nvim

