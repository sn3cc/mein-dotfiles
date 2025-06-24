# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh-my-zsh installation path (FIXED)
ZSH="$HOME/.oh-my-zsh"

#show color with hexcolors
hexcolor() {
    for hex in "$@"; do
        printf "\033[48;2;%d;%d;%dm  \033[0m %s\n" \
            "0x${hex:1:2}" "0x${hex:3:2}" "0x${hex:5:2}" "$hex"
    done
}

# Powerlevel10k theme path
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# --- Completion & Suggestion Colors ---
autoload -U colors && colors

# Set custom colors for autocomplete (completion menu)
zstyle ':completion:*' list-colors "di=1;34:fi=0:ln=1;36:pi=1;33:so=1;35:bd=1;33:cd=1;33:or=1;31:mi=1;31:*.sh=1;32:*.txt=1;33"

# Set color for autosuggestions (blue)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#8A8A8A'

# --- Plugins ---
plugins=(
git
sudo
zsh-256color
zsh-autosuggestions
zsh-syntax-highlighting
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# --- Command Not Found Helper ---
function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf 'zsh: command not found: %s\n' "$1"
    local entries=( ${(f)"$(/usr/bin/pacman -F --machinereadable -- "/usr/bin/$1")"} )
    if (( ${#entries[@]} )) ; then
        printf "${bright}$1${reset} may be found in the following packages:\n"
        local pkg
        for entry in "${entries[@]}" ; do
            local fields=( ${(0)entry} )
            if [[ "$pkg" != "${fields[2]}" ]]; then
                printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
            fi
            printf '    /%s\n' "${fields[4]}"
            pkg="${fields[2]}"
        done
    fi
    return 127
}

# --- Detect AUR Helper ---
if pacman -Qi yay &>/dev/null; then
   aurhelper="yay"
elif pacman -Qi paru &>/dev/null; then
   aurhelper="paru"
fi

# --- Install Function ---
function in {
    local -a inPkg=("$@")
    local -a arch=()
    local -a aur=()

    for pkg in "${inPkg[@]}"; do
        if pacman -Si "${pkg}" &>/dev/null; then
            arch+=("${pkg}")
        else
            aur+=("${pkg}")
        fi
    done

    if [[ ${#arch[@]} -gt 0 ]]; then
        sudo pacman -S "${arch[@]}"
    fi

    if [[ ${#aur[@]} -gt 0 ]]; then
        ${aurhelper} -S "${aur[@]}"
    fi
}

# --- Aliases ---
alias c='clear'
alias l='eza -lh --icons=auto'
alias ls='eza -1 --icons=auto'
alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
alias ld='eza -lhD --icons=auto'
alias lt='eza --icons=auto --tree'
alias un='$aurhelper -Rns'
alias up='$aurhelper -Syu'
alias pl='$aurhelper -Qs'
alias pa='$aurhelper -Ss'
alias pc='$aurhelper -Sc'
alias po='$aurhelper -Qtdq | $aurhelper -Rns -'
alias vc='code'

# --- Directory Shortcuts ---
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

alias mkdir='mkdir -p'

# --- Powerlevel10k Config ---
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- Custom PATH ---
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# --- Fun: Display Pokemon (MOVED TO END to avoid instant prompt issues) ---
pokemon-colorscripts --no-title -r 1,3,6

# --- Broot launcher (FIXED USERNAME) ---
[[ -f /home/sn3cc/.config/broot/launcher/bash/br ]] && source /home/sn3cc/.config/broot/launcher/bash/br
source /home/sn3cc/.config/broot/launcher/bash/br
