# Use "type my_alias" to see what an alias refers to

# Handy commands for modifying this file
alias bashupdate='source ~/.bashrc'
# Consider using `tilde` instead!
alias bashedit='micro ~/Dev/utils/bash/.bash_aliases && bashupdate'
alias bashrcedit='micro ~/Dev/utils/bash/.bashrc && bashupdate'

alias gs="git status"
alias gc="git commit -am"

# shortcuts
# lr:  Full Recursive Directory Listing
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | less'
# some more ls aliases
alias ll='ls -alFh'
alias llt='ll -t'
alias la='ls -A'
alias godev='cd ~/Dev'
alias gohome='cd ~'
alias godown='cd ~/Downloads'
alias histf='history | fzf'
alias gohere='tmux send-keys -t :.+ C-c "cd $(pwd)" Enter'

# Apt
alias get="sudo apt install -y"

# Git
alias gitmain="git checkout main"
alias gs="git status && git diff --stat"
alias push="git push -u origin"
alias checkout="git checkout"
alias ga="git add -A"
alias commit="git commit -am"
alias gp="git pull"
alias gd="git diff"
alias recentchanges="git log -n 5 --no-merge --name-only --pretty=format: | sort | uniq"
alias gdiff="git diff --color | ~/Installs/diff-so-fancy/diff-so-fancy"
# alias glog='git log -n 20 --pretty=format:"%h -- %an, %ar -- %s" --reverse'
alias glog='git log --oneline --graph --decorate --all -n 20'
alias gitrecent='git for-each-ref --sort=committerdate refs/heads/ --format="%(committerdate:short) %(refname:short)"'
alias githistory='git log -n 20 --pretty=format:"%C(yellow)%h%C(reset) - %C(green)%s%C(reset)" --name-only --reverse'

# KDE
alias fixkwin="DISPLAY=:0 kwin --replace &"

# Tools
alias catcat='cat'
alias bat='batcat'
alias cat='bat'
# alias grep='rg'
alias gitaddall="git add -A"

# Clipboard
alias clip='xclip -selection clipboard'

# LOL
# alias art='find ~/Pictures/Art -type f -name "*.jpg" -o -name "*.png" | shuf -n 1 | xargs -I {} jp2a --colors {}'
alias art='find ~/Pictures/Art -type f -name "*.jpg" -o -name "*.png" | shuf -n 1 | xargs -I {} catimg -w 120 {}'
alias growtree='cbonsai -l'
alias drawurl='drawurl_func() { curl -s "$1" | catimg -; }; drawurl_func'
alias drawtext='bash ~/Dev/utils/bash/drawtext.sh'
# alias fortuna='fortune /usr/share/games/fortunes/es' # See below

# Tools
alias bat='batcat'
alias pingo='ping 8.8.8.8'

# HISTORY STUFF
# Taken from Matthew's bashrc at https://gitlab.com/generally-intelligent/generally_intelligent/-/snippets/2584437
# It originally comes from https://spin.atomicobject.com/2016/05/28/log-bash-history/ and https://news.ycombinator.com/item?id=11806553, but has been extended over time.
# Explanation https://chat.openai.com/share/e551dfb1-978e-46be-a9db-0aa9c4fb07ec

# Store all my commands in a history file, one per day
export PROMPT_COMMAND='if [ "$(id -u)" -ne 0 ]; then touch "${HOME}/.logs/bash-history-$(date "+%Y-%m-%d").log"; echo "$(date "+%H:%M") | $(pwd | sed "s|^${HOME}|~|") | $(cut -c 8- <<< "$(history 1)")" >> "${HOME}/.logs/bash-history-$(date "+%Y-%m-%d").log"; fi'

# To use this function, you'd call `histview bash-history-YYYY-MM-DD.log` to view the logged commands for the specified date.
histview() {
  DAY=$(echo "$1" | grep -Eo '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')
  while read -r line
  do
    echo "$DAY | $line"
  done < "$HOME/.logs/${1}"
}

# view bash history from ever. This can be called like `ever called echo`
ever() {
  if [ "$1" == "called" ]; then
    if [ "$2" == "here" ]; then
      ever | grep "$(pwd) "
    elif [ "$2" == "below" ]; then
      ever | grep "$(pwd)"
    elif [ "$2" == "in" ]; then
      #if this is a relative directory, append pwd to it
      match=$3
      if [[ "$3" != "/"* ]] && [[ "$3" != "~"* ]]; then
        match="$(pwd)/$"
      fi
      ever | grep "$match "
    else
      ever | grep ${@:2}
    fi
  else
    for log in $(ls ${HOME}/.logs);do
      #per line
      histview "$log"
    done
  fi
  #cat ~/.logs/bash-history-*.log
}
# view bash history from today
today() {
  cat ~/.logs/bash-history-$(date "+%Y-%m-%d").log
}
# Search the recent history
called() {
  if [ "$1" == "here" ]; then
    today | grep "$(pwd) "
  elif [ "$1" == "below" ]; then
    today | grep "$(pwd)"
  elif [ "$1" == "in" ]; then
    #if this is a relative directory, append pwd to it
    match=$2
    if [[ "$2" != "/"* ]] && [[ "$2" != "~"* ]]; then
      match="$(pwd)/$2"
    fi
    today | grep "$match "
  else
    today | grep ${@}
  fi
}

alias mse="wine /home/keenan/Installs/M15-Magic-Pack-main/mse.exe"

alias godev="cd ~/Dev"

# Git colors
git config --global color.ui true
git config --global color.diff-highlight.oldNormal    "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal    "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"
git config --global color.diff.meta       "11"
git config --global color.diff.frag       "magenta bold"
git config --global color.diff.func       "146 bold"
git config --global color.diff.commit     "yellow bold"
git config --global color.diff.old        "red bold"
git config --global color.diff.new        "green bold"
git config --global color.diff.whitespace "red reverse"

runlast() {
    $1 $(fc -ln -2 | awk '{print $NF}')
}

#and() {
#    local command="$*"
#     eval "${command// and / && }"
#}
#alias and='eval "$(echo "$*" | sed "s/ and / && /g")"'

wh() {
    # Default settings
    local max_depth=5
    local count_threshold=40
    local show_hidden=false
    local size_sort=false
    local force_depth=""
    local full_depth=false
    local dir=""

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--depth)
                force_depth="$2"
                shift 2
                ;;
            -c|--count)
                count_threshold="$2"
                shift 2
                ;;
            -a|--all)
                show_hidden=true
                shift
                ;;
            -s|--sort)
                size_sort=true
                shift
                ;;
            -f|--full)
                full_depth=true
                count_threshold=1000000
                shift
                ;;
            -h|--help)
                echo "Usage: whatshere [-d|--depth depth] [-c|--count count_threshold] [-a|--all] [-h|--help] [-s|--sort] [directory]"
                echo "  -d, --depth depth: Force a specific depth"
                echo "  -c, --count count: Set the count threshold (default: 1000)"
                echo "  -a, --all: Show hidden files"
                echo "  -h, --help: Show this help message"
                echo "  -s, --sort: Sort by size (largest first)"
                return 0
                ;;
            *)
                dir="$1"
                shift
                ;;
        esac
    done

    # Get the directory to analyze (current directory if not specified)
    dir="${dir:-.}"

    # Function to count items at a specific depth
    count_at_depth() {
        local depth=$1
        local count_cmd

        if $show_hidden; then
            count_cmd="find '$dir' -mindepth $depth -maxdepth $depth | wc -l"
        else
            count_cmd="find '$dir' -mindepth $depth -maxdepth $depth -not -path '*/\.*' | wc -l"
        fi

        eval "$count_cmd"
    }

    # Determine the optimal depth
    local depth=0
    local total_count=0
    while true; do
        ((depth++))
        local level_count=$(count_at_depth $depth)
        total_count=$((total_count + level_count))

        if [ $depth -ge $max_depth ] || [ $level_count -eq 0 ] || [ $total_count -ge $count_threshold ]; then
            [ $depth -ge $max_depth ] #&& echo "  - Max depth reached"
            [ $level_count -eq 0 ] #&& echo "  - No more items at this level"
            [ $total_count -ge $count_threshold ] #&& echo "  - Total count threshold reached"
            ((depth--))  # Decrement depth by 1
            break
        fi
    done

    # Use forced depth if specified
    if [ -n "$force_depth" ]; then
        depth=$force_depth
    fi

    # Ensure depth is at least 1
    depth=$((depth > 0 ? depth : 1))

    # Prepare tree options
    local tree_opts=("-L" "$depth")
    $show_hidden && tree_opts+=("-a")
    $size_sort && tree_opts+=("--sort=size" "--dirsfirst")


    # Run tree with the determined depth and options
    tree "${tree_opts[@]}" "$dir"
}

alias whh="wh -a"
alias whf="wh -f"

# Translating fortunes lol
#!/bin/bash

fortuna() {
    # Get the Spanish fortune
    # spanish_fortune=$(fortune /usr/share/games/fortunes/es)
    # spanish_fortune=$(fortune /usr/share/games/fortunes/es | tr -d '\n' ' ')
    spanish_fortune=$(fortune /usr/share/games/fortunes/es)

    # Print the Spanish fortune
    # echo "Spanish Fortune:"
    echo "$spanish_fortune"
    # echo

    spanish_fortune=$(echo "$spanish_fortune" | tr '\n' ' ')

    # Translate and print the English translation
    # echo "English Translation:"
    trans es:en --brief "$spanish_fortune"
}

# Call the function
# spanish_fortune_with_translation

# Another function
source ~/Dev/utils/bash/.analyze_jsonl.sh

# Content
alias thenews='http https://www.bloomberg.com/ | html2markdown | cat | aichat "Summarize the headlines for today. Focus on finance and science. Include links."'

