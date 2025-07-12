#!/bin/bash

SESSION_SCRIPTS_DIR="$HOME/.tmux-sessions/"  # Directory where your session scripts are stored

echo "Available sessions:"
# List available session scripts (only files that match 'session-*')
# sessions=($(ls $SESSION_SCRIPTS_DIR/tmux-session-* 2>/dev/null | xargs -n 1 basename | sed 's/session-//'))
sessions=($(ls "$SESSION_SCRIPTS_DIR"tmux-session-* 2>/dev/null | sed 's|.*tmux-session-||'))


# If no session scripts found, exit
if [ ${#sessions[@]} -eq 0 ]; then
    echo "No session scripts found in $SESSION_SCRIPTS_DIR."
    exit 1
fi

# Display session options
for i in "${!sessions[@]}"; do
    echo "[$i] ${sessions[$i]}"
done

# Prompt user to select a session
read -p "Select a session (enter number): " choice

# Validate input
if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -ge "${#sessions[@]}" ]; then
    echo "Invalid selection."
    exit 1
fi

SESSION_NAME="${sessions[$choice]}"
SESSION_SCRIPT="$SESSION_SCRIPTS_DIR/tmux-session-$SESSION_NAME"

tmux has-session -t "$SESSION_NAME" &> /dev/null

if [ $? != 0 ]; then
    bash "$SESSION_SCRIPT"
fi

tmux attach -t "$SESSION_NAME"

