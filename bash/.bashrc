# Private keys
source ~/Dev/private_keys.sh

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=200000

# Save each command right after it executes
PROMPT_COMMAND='history -a'

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Shopt stuff
shopt -s cmdhist # Saves multi-line commands in history as a single line.
shopt -s dotglob # Includes filenames beginning with a '.' in pathname expansion.
shopt -s no_empty_cmd_completion # Disables tab completion on an empty line.
shopt -s extglob  # Enables extended pattern matching features.
# Practical Examples of extglob:
# rm !(*.txt): Remove all files except .txt files.
# cp *.@(jpg|jpeg|png) /path/to/destination: Copy only .jpg, .jpeg, or .png files.
# ls *(.): List only regular files (not directories).
# mv !(file1|file2) /path/to/destination: Move all files except file1 and file2.

# Editor
export EDITOR=micro

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

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

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# PATH
export PATH=$PATH:/home/keenan/Stuff/mallet-2.0.8/bin
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/cuda/include:$LD_LIBRARY_PATH
export PATH=$PATH:/usr/local/go/bin
export PATH="$HOME/.cargo/bin:$PATH"



# THE FOLLOWING STUFF ONLY HAPPENS IF IT'S IN A REAL INTERACTIVE TERMINAL
[[ $- == *i* ]] && [ -t 0 ] && [ -t 1 ] || return
echo "Interactive Mode"



# Ble.sh
# https://github.com/akinomyoga/ble.sh
source ~/Installs/ble.sh/out/ble.sh
bleopt prompt_eol_mark='⏎'
# Per https://github.com/akinomyoga/ble.sh#28-fzf-integration
ble-import -d integration/fzf-completion
ble-import -d integration/fzf-key-bindings

# Atuin with Ble.sh
eval "$(atuin init bash)"

# Alias definitions.
source ~/Dev/utils/bash/.bash_aliases

# Where the actual PS1 variable is set
source ~/Dev/utils/bash/.bash_ps1

# Print out a funny message
# fortune
# fortune /usr/share/games/fortunes/es # In Spanish, for practice
fortuna # From .bash_aliases
#echo "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~"
# echo "Hey!"
# neofetch
art

# Starship
# eval "$(starship init bash)"

# Other tools
# aichat, for ai chatting
# Can use sgpt by pressing ctrl+l after writing something on the command line, https://github.com/TheR1D/shell_gpt

