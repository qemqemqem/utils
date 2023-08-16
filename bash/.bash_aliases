# Use "type my_alias" to see what an alias refers to

# Handy commands for modifying this file
alias bashupdate='source ~/.bashrc'
alias bashedit='ne ~/.bash_aliases && bashupdate'
alias bashrcedit='ne ~/.bashrc && bashupdate'

alias gs="git status"
alias gc="git commit -am"

# shortcuts
# lr:  Full Recursive Directory Listing
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | less'
# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'

# Git
alias gitmain="git checkout main"
alias gs="git status"
alias push="git push -u origin"
alias checkout="git checkout"
alias commit="git commit -am"
alias gp="git pull"
alias gd="git diff"
alias recentchanges="git log -n 5 --no-merge --name-only --pretty=format: | sort | uniq"
