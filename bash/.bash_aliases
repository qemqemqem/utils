# Use "type my_alias" to see what an alias refers to

# Handy commands for modifying this file
alias bashupdate='source ~/.bashrc'
alias bashedit='ne ~/Dev/utils/bash/.bash_aliases && bashupdate'
alias bashrcedit='ne ~/Dev/utils/bash/.bashrc && bashupdate'

alias gs="git status"
alias gc="git commit -am"

# shortcuts
# lr:  Full Recursive Directory Listing
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | less'
# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'

# Apt
alias get="sudo apt install -y"

# Git
alias gitmain="git checkout main"
alias gs="git status"
alias push="git push -u origin"
alias checkout="git checkout"
alias ga="git add -A"
alias commit="git commit -am"
alias gp="git pull"
alias gd="git diff"
alias recentchanges="git log -n 5 --no-merge --name-only --pretty=format: | sort | uniq"

# LOL
# alias art='find ~/Pictures/Art -type f -name "*.jpg" -o -name "*.png" | shuf -n 1 | xargs -I {} jp2a --colors {}'
alias art='find ~/Pictures/Art -type f -name "*.jpg" -o -name "*.png" | shuf -n 1 | xargs -I {} catimg {}'
alias growtree='cbonsai -l'

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
