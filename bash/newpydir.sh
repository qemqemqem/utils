#!/bin/bash

# Function to set up a Python development environment
# with venv and direnv configuration
newpydir() {
    # Determine which venv directory to use (prefer .venv, support venv)
    local venv_dir
    if [ -d "./.venv" ]; then
        venv_dir=".venv"
        echo "Using existing .venv directory."
    elif [ -d "./venv" ]; then
        venv_dir="venv"
        echo "Using existing venv directory."
    else
        venv_dir=".venv"
        echo "Creating new Python virtual environment in .venv..."
        python3 -m venv ./.venv
    fi

    # Create or update .envrc file for direnv
    cat > .envrc << EOF
# Python environment setup
export PYTHONPATH=\$PYTHONPATH:.

# Properly activate the virtual environment
source ${venv_dir}/bin/activate
export VIRTUAL_ENV=\$(pwd)/${venv_dir}
export PATH=\$(pwd)/${venv_dir}/bin:\$PATH
EOF

    # Allow direnv to load the new .envrc file
    if command -v direnv &> /dev/null; then
        direnv allow .
        echo "Direnv configuration updated and allowed."
    else
        echo "Warning: direnv not found. Install direnv for automatic environment loading."
        echo "The .envrc file has been created, but you'll need to manually run: direnv allow ."
    fi

    echo "Python development environment setup complete."
    echo "The virtual environment will be activated automatically when you enter this directory (if direnv is installed)."
}
