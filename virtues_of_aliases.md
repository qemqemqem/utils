# The Virtues of Bash Aliases: A Practical Guide

Bash aliases save time, reduce errors, and make the command line more enjoyable. This guide showcases real-world examples from my own `.bash_aliases` file to demonstrate how they can transform your workflow.

## Categories of Useful Aliases

### File Navigation & Listing
```bash
alias ll='ls -alFh'                # Detailed list with human-readable sizes
alias llt='ll -t'                  # Sort by modification time
alias godev='cd ~/Dev'             # Quick directory jumping
alias gohome='cd ~'
alias godown='cd ~/Downloads'
```

### Git Workflow Accelerators
```bash
alias gs="git status && git diff --stat"  # Status with change statistics
alias ga="git add -A"                     # Stage all changes
alias commit="git commit -am"             # Commit with message
alias undocommit="git reset --soft HEAD~1"  # Undo last commit
alias gitmain="git checkout main"         # Switch to main branch
alias gitgood='git tag -a good -m "Currently in a good state"'  # Tag good state
```

### Command History Navigation
```bash
alias histf='history | fzf'        # Fuzzy-find in history

# View bash history from all time with filtering
ever() {
  if [ "$1" == "called" ]; then
    if [ "$2" == "here" ]; then
      ever | grep "$(pwd) "        # Commands run in current directory
    elif [ "$2" == "below" ]; then
      ever | grep "$(pwd)"         # Commands in current dir or subdirs
    elif [ "$2" == "in" ]; then
      # Commands in specific directory
      match=$3
      if [[ "$3" != "/"* ]] && [[ "$3" != "~"* ]]; then
        match="$(pwd)/$"
      fi
      ever | grep "$match "
    else
      ever | grep ${@:2}           # General search
    fi
  else
    for log in $(ls ${HOME}/.logs);do
      histview "$log"              # Show all history
    done
  fi
}

# View today's commands
today() {
  cat ~/.logs/bash-history-$(date "+%Y-%m-%d").log
}
```

### Python Development
```bash
alias pythonheretoo='export PYTHONPATH=$PYTHONPATH:.'  # Add current dir to path
alias venvo='source venv/bin/activate'                 # Activate virtual env
alias acto='pythonheretoo && venvo'                    # Do both at once
alias py='python'                                      # Shorter python command
```

### Smart Directory Listing
```bash
# Intelligent directory listing that adapts to directory size
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
                return 0
                ;;
            *)
                dir="$1"
                shift
                ;;
        esac
    done

    # Determine optimal depth based on directory size
    # ...

    # Run tree with the determined depth and options
    tree "${tree_opts[@]}" "$dir"
}

alias whh="wh -a"  # Show hidden files
alias whf="wh -f"  # Show full depth
```

### Fun & Utility
```bash
# Display random art from collection
alias art='find ~/Pictures/Art -type f -name "*.jpg" -o -name "*.png" | shuf -n 1 | xargs -I {} catimg -w 120 {}'

# Grow an ASCII bonsai tree
alias growtree='cbonsai -l'

# Spanish fortune with English translation
fortuna() {
    spanish_fortune=$(fortune /usr/share/games/fortunes/es)
    echo "$spanish_fortune"
    spanish_fortune=$(echo "$spanish_fortune" | tr '\n' ' ')
    trans es:en --brief "$spanish_fortune"
}

# Get news summaries
alias thenews='http https://www.bloomberg.com/ | html2markdown | cat | aichat "Summarize the headlines for today. Focus on finance and science. Include links."'
```

### Alias Management
```bash
alias bashupdate='source ~/.bashrc'
alias bashedit='micro ~/Dev/utils/bash/.bash_aliases && bashupdate'
alias bashrcedit='micro ~/Dev/utils/bash/.bashrc && bashupdate'
```

## Tips for Creating Your Own Aliases

1. **Start with your most frequent commands**: Look at your history to identify repetitive commands.
   ```bash
   history | awk '{print $2}' | sort | uniq -c | sort -nr | head -20
   ```

2. **Group related aliases**: Keep similar aliases together in your file for easier maintenance.

3. **Use descriptive names**: Balance brevity with clarity - `gs` for git status makes sense, but `x` for a complex operation doesn't.

4. **Document complex aliases**: Add comments for anything non-obvious.

5. **Create update mechanisms**: Always include ways to quickly edit and reload your aliases.
   ```bash
   alias bashupdate='source ~/.bashrc'
   alias bashedit='micro ~/.bash_aliases && bashupdate'
   ```

6. **Use functions for complex operations**: When an alias needs logic, use a bash function instead.

7. **Test before committing**: Always test new aliases in your current shell before adding them permanently.

Your aliases file will evolve with your workflow. Regularly review and refine it to match your changing needs and to remove aliases you no longer use.
