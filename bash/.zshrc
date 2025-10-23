# Private keys
source ~/Dev/private_keys.sh

# ~/.zshrc: executed by zsh for interactive shells

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# History settings - zsh style
HISTSIZE=100000
SAVEHIST=200000
HISTFILE=~/.zsh_history

# Zsh options for history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# Other useful zsh options
setopt AUTO_CD              # cd by typing directory name if it's not a command
# setopt CORRECT             # command auto-correction
setopt COMPLETE_ALIASES    # complete aliases
setopt EXTENDED_GLOB       # extended globbing (equivalent to bash's extglob)
setopt NO_CASE_GLOB        # case insensitive globbing
setopt NUMERIC_GLOB_SORT   # sort filenames numerically when it makes sense

# Editor
export EDITOR=micro

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Enable zsh completions
autoload -Uz compinit
compinit

# Make completion case-insensitive
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# Use colors in completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# PATH
export PATH=$PATH:/home/keenan/Stuff/mallet-2.0.8/bin
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/cuda/include:$LD_LIBRARY_PATH
export PATH=$PATH:/usr/local/go/bin
export PATH="$HOME/.cargo/bin:$PATH"
export PATH=$PATH:$(go env GOROOT)/bin:$(go env GOPATH)/bin


# THE FOLLOWING STUFF ONLY HAPPENS IF IT'S IN A REAL INTERACTIVE TERMINAL
# Zsh equivalent of bash's login_shell check
if [[ -o login ]]; then
    # echo "Interactive Mode"

    # Atuin 
    eval "$(atuin init zsh)"

    # Alias definitions.
    source ~/Dev/utils/bash/.zsh_aliases

    # Where the actual PS1 variable is set
    source ~/Dev/utils/bash/.zsh_ps1

    # Print out a funny message
    # fortune
    # fortune /usr/share/games/fortunes/es # In Spanish, for practice
    fortuna # From .zsh_aliases
    #echo "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~"
    # echo "Hey!"
    # neofetch
    art

    # Starship
    # eval "$(starship init zsh)"

    # Other tools
    # aichat, for ai chatting
    # Can use sgpt by pressing ctrl+l after writing something on the command line, https://github.com/TheR1D/shell_gpt

    # Direnv
    eval "$(direnv hook zsh)"

    # Disable Ctrl+Z in the terminal
    stty susp undef
    if [[ -z "$TMUX" ]]; then
      stty susp undef
    fi

    # This is for npm
    export PATH=~/.npm-global/bin:$PATH

    # Ensure Homebrew bash comes first
    export PATH="/opt/homebrew/bin:$PATH"

    export PATH="/opt/homebrew/opt/gnu-coreutils/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"

    # Prophecy Stuff

    export KUBECONFIG=~/.kube/config:~/Downloads/andrew-dev-k3s.yaml


    . "$HOME/.atuin/bin/env"
    eval "$(atuin init zsh)"

    [[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
    source ~/.bash-preexec.sh
fi
. "$HOME/.local/bin/env"

# Prophecy
source ~/prophecy/.zshrc
export JAVA_HOME=$(/usr/libexec/java_home -v 11)
export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

export PATH="$HOME/.local/bin:$PATH"
