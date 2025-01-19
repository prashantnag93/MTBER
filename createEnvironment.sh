#!/bin/bash

# Project variables (populated by Cookiecutter)
ENV_NAME="MTBER"  # Dynamically set the environment name based on project_slug

# Check if micromamba is already installed
if ! command -v micromamba &> /dev/null
then
    echo "Micromamba not found. Installing..."
    
    # Install micromamba using the recommended installation method
    "${SHELL}" <(curl -L micro.mamba.pm/install.sh)
    
    # Add micromamba to PATH (the default install location is $HOME/.local/bin)
    export PATH=$HOME/.local/bin:$PATH
    echo "Micromamba installed and added to PATH."
else
    echo "Micromamba is already installed."
fi

# Verify micromamba installation
if ! command -v micromamba &> /dev/null
then
    echo "Micromamba installation failed. Please check your system and try again."
    exit 1
fi

# Check if the environment.yml file exists
if [ ! -f "environment.yml" ]; then
    echo "Error: environment.yml file not found. Please make sure it exists in the project root."
    exit 1
fi

# Create or update the environment using the provided environment.yml
echo "Creating or updating the environment using micromamba..."
micromamba create -f environment.yml --yes

# Activate the environment
echo "Activating the environment..."
micromamba activate "$ENV_NAME"

# Notify the user
echo "Environment setup complete! The environment name is: $ENV_NAME"
echo "To activate the environment in the future, run: micromamba activate $ENV_NAME"
