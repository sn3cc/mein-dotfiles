# BASHRC CONFIG WITH USEFUL PRODUCTIVITY TOOLS WHEN USED INSIDE VSCODE

# ~/.bashrc - Minimal config for code editors

# History settings
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Better directory navigation
shopt -s autocd
shopt -s cdspell
shopt -s dirspell

# Case-insensitive tab completion
bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"

# Simple prompt - just current directory and git branch
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
PS1='\[\033[0;34m\]\W\[\033[0;32m\]$(parse_git_branch)\[\033[0m\] $ '

# Useful aliases - use eza if available, fallback to ls
if command -v eza &> /dev/null; then
    alias ls='eza'
    alias ll='eza -la'
    alias la='eza -a'
    alias l='eza'
    alias tree='eza --tree'
else
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Quick navigation
alias projects='cd ~/projects'
alias docs='cd ~/Documents'
alias downloads='cd ~/Downloads'

# File operations
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias mkdir='mkdir -p'

# System info
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'

# Network
alias ping='ping -c 5'
alias ports='netstat -tuln'

# Development helpers
alias serve='python3 -m http.server'
alias jsonpp='python3 -m json.tool'
alias urlencode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'
alias urldecode='python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'

# Quick edit common files
alias bashrc='code ~/.bashrc'
alias reload='source ~/.bashrc'

# Functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find files/directories
ff() {
    find . -type f -name "*$1*"
}

fd() {
    find . -type d -name "*$1*"
}

# Process management
psg() {
    ps aux | grep -v grep | grep "$1"
}

# Export common environment variables
export EDITOR=code
export VISUAL=code
export PAGER=less
export LESS='-R'

# Add local bin to path if it exists
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Node.js version manager (uncomment if using nvm)
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"