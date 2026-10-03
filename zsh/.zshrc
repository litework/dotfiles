# ~/.zshrc

HISTFILE=~/.histfile
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space extended_history autocd

bindkey -v
KEYTIMEOUT=1

typeset -U path
path=(~/.local/bin ~/.cargo/bin $path)

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Apply the current wallust palette to new terminals.
[[ -r ~/.cache/wallust/sequences ]] && cat ~/.cache/wallust/sequences

source <(fzf --zsh)
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

alias ls='eza --group-directories-first'
alias ll='eza -l --git --group-directories-first'
alias la='eza -la --git --group-directories-first'
alias tree='eza --tree'
alias vim=nvim

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# Must be sourced last.
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

clear
