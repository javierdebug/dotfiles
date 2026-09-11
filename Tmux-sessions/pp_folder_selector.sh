#!/bin/bash

# Define your specific project folders
declare -a PROJECTS=(
  "$HOME/Documents/JV/Code/Dev/202X/Backend/"
  "$HOME/Documents/JV/Code/Yu-course/"
  "$HOME/Documents/JV/Code/PostgreSQL/"
  "$HOME/Documents/JV/Code/Dev/202X/"
  "/media/javierd/c32101e6-a564-4222-9efe-66694cc31e13/home/jv/Documents/Code"
)

# Show the list in fzf and store selection
project_path=$(find "${PROJECTS[@]}" -mindepth 1 -maxdepth 1 -type d | fzf --prompt="Select project: ")

# Exit if no selection
[ -z "$project_path" ] && echo "No folder selected." && return 1

# Change to selected folder
cd "$project_path"

# # Start nvim
# nvim

