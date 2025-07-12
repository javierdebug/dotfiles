# Setup fzf
# ---------
if [[ ! "$PATH" == */home/javierd/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/javierd/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/javierd/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/home/javierd/.fzf/shell/key-bindings.zsh"
