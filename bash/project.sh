#!/bin/bash

# Source newpydir functionality
source "$(dirname "${BASH_SOURCE[0]}")/newpydir.sh"

# Project management function
project() {
    if [ $# -eq 0 ]; then
        echo "Usage: project <project-name>"
        return 1
    fi

    local project_name="$1"
    local project_dir="$HOME/Dev/$project_name"
    local github_user="qemqemqem"
    
    # Check if GitHub repo exists first
    echo "Checking if GitHub repo $github_user/$project_name exists..."
    
    # Try gh first, fall back to curl if gh isn't authenticated
    if gh repo view "$github_user/$project_name" &>/dev/null; then
        repo_exists=true
        use_gh=true
    elif curl -s "https://api.github.com/repos/$github_user/$project_name" | grep -q '"name"'; then
        repo_exists=true
        use_gh=false
    else
        repo_exists=false
        use_gh=false
    fi
    
    if [ "$repo_exists" = true ]; then
        echo "Found existing GitHub repo: $github_user/$project_name"
        
        if [ -d "$project_dir" ]; then
            echo "Local directory already exists. Going to $project_dir"
            cd "$project_dir" || return 1
        else
            echo "Cloning $github_user/$project_name to $project_dir"
            mkdir -p "$HOME/Dev"
            
            if [ "$use_gh" = true ]; then
                gh repo clone "$github_user/$project_name" "$project_dir" || return 1
            else
                git clone "https://github.com/$github_user/$project_name.git" "$project_dir" || return 1
            fi
            cd "$project_dir" || return 1
        fi
        return 0
    fi
    
    # Check if local directory exists
    if [ -d "$project_dir" ]; then
        echo "Going to existing project: $project_dir"
        cd "$project_dir" || return 1
        return 0
    fi
    
    # Neither exists - create new project
    echo "Project '$project_name' doesn't exist locally or on GitHub."
    read -p "Create new project '$project_name'? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        return 0
    fi
    
    # Create directory and initialize
    echo "Creating $project_dir..."
    mkdir -p "$project_dir" || return 1
    cd "$project_dir" || return 1
    
    # Initialize git
    echo "Initializing git repository..."
    git init -b main || return 1
    
    # Ask if it's a Python project
    read -p "Is this a Python project? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Setting up Python environment..."
        newpydir
        
        # Create basic Python files
        echo "# $project_name" > README.md
        echo "__version__ = '0.1.0'" > __init__.py
        touch requirements.txt
        
        # Create .gitignore for Python
        cat > .gitignore << 'EOF'
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/
.envrc
EOF
    else
        echo "# $project_name" > README.md
        touch .gitignore
    fi
    
    # Create Claude Code settings
    echo "Creating .claude/settings.json..."
    mkdir -p .claude
    cat > .claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(find .)",
      "Bash(find . *)",
      "Bash(cd *)",
      "Bash(ls *)",
      "Bash(pwd)",
      "Bash(tree *)",
      "Bash(grep *)",
      "Bash(cat *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(wc *)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git branch *)",
      "Bash(npm *)",
      "Bash(pip *)",
      "Bash(python *)",
      "Bash(pytest *)",
      "Bash(make *)",
      "Read",
      "Edit",
      "Glob"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(sudo *)",
      "Bash(curl *)",
      "Bash(wget *)"
    ]
  }
}
EOF
    
    # Initial commit
    echo "Making initial commit..."
    git add . || return 1
    git commit -m "Initial commit" || return 1
    
    # Create GitHub repo and push
    echo "Creating GitHub repository..."
    gh repo create "$project_name" --private --source=. --remote=origin --push || {
        echo "Failed to create GitHub repo. You can create it manually later."
        return 1
    }
    
    echo "Project '$project_name' created successfully!"
    echo "Location: $project_dir"
    echo "GitHub: https://github.com/$github_user/$project_name"
}