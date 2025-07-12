# Setup fzf
# ---------
if [[ ! "$PATH" == */home/javierd/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/javierd/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/javierd/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/home/javierd/.fzf/shell/key-bindings.bash"
