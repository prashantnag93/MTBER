#!/bin/bash

# Exit on error
set -e

# Project variables
ENV_NAME="MTBER"  # Change as needed

# Ensure Micromamba's default install path is added to PATH before checking
export PATH="$HOME/.local/bin:$PATH"

# Function to check internet connectivity
check_internet() {
    echo "🌍 Checking internet connectivity..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "✅ Internet connection is active."
    else
        echo "❌ Error: No internet connection. Please check your network and try again."
        return 1  # Prevent script from exiting immediately
    fi
}

# Function to cleanup only if the environment creation fails
cleanup() {
    echo "🧹 Cleaning up..."
    if micromamba env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
        echo "🔄 Removing broken environment: $ENV_NAME"
        micromamba env remove -n "$ENV_NAME" --yes
    fi
}

# Function to check if Micromamba is installed
check_micromamba() {
    if ! command -v micromamba &> /dev/null; then
        echo "⚠️  Micromamba not found. Installing..."
        
        # Correct way: Use -b (batch mode) to install without interaction
        curl -L micro.mamba.pm/install.sh | bash -s - -b
        
        # Ensure PATH is updated immediately
        export PATH="$HOME/.local/bin:$PATH"
        echo "✅ Micromamba installed."
    else
        echo "✅ Micromamba is already installed."
    fi
}


# Function to check Micromamba version
check_micromamba_version() {
    echo "🔍 Checking Micromamba version..."

    # Get Micromamba version
    MAMBA_VERSION=$(micromamba --version | grep -oP '\d+\.\d+\.\d+' | head -n1)
    MIN_VERSION="1.0.0"

    if [ -z "$MAMBA_VERSION" ]; then
        echo "⚠️  Warning: Micromamba version could not be detected. Skipping version check."
        return 0
    fi

    # Compare versions using sort -V (no need for packaging module)
    if printf '%s\n%s\n' "$MIN_VERSION" "$MAMBA_VERSION" | sort -V | head -n1 | grep -q "$MIN_VERSION"; then
        echo "✅ Micromamba version $MAMBA_VERSION is compatible."
    else
        echo "⚠️  Warning: Micromamba version $MAMBA_VERSION might be outdated. Minimum recommended version is $MIN_VERSION."
    fi
}




# Function to initialize Micromamba shell
initialize_micromamba() {
    if ! grep -q 'micromamba shell init' ~/.bashrc; then
        echo "🔄 Initializing Micromamba shell..."
        micromamba shell init --shell bash || echo "⚠️ Warning: Micromamba shell init failed. Skipping..."
        echo "✅ Micromamba shell initialized."
        echo "⚠️  Please restart your shell or run: source ~/.bashrc"
        return 0  # Prevent exit
    else
        echo "✅ Micromamba shell already initialized. Skipping..."
    fi

    # Ensure the shell is aware of Micromamba
    eval "$(micromamba shell hook --shell bash)" || echo "⚠️ Warning: Micromamba shell hook failed."
}

# Function to create the environment (only if it doesn't exist)
create_environment() {
    echo "🔍 Checking if environment '$ENV_NAME' exists..."
    
    if ! micromamba env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
        echo "⚠️  Environment '$ENV_NAME' does not exist. Creating it..."
        
        if [ ! -f "environment.yml" ]; then
            echo "❌ Error: environment.yml file not found. Cannot create environment."
            exit 1
        fi

        if ! micromamba create -n "$ENV_NAME" -f environment.yml --yes; then
            echo "❌ Error: Micromamba failed to create environment '$ENV_NAME'."
            cleanup
            exit 1
        fi
    else
        echo "✅ Micromamba environment '$ENV_NAME' already exists. Skipping creation."
    fi
}


# Function to verify the environment
verify_environment() {
    echo "🛠️  Verifying environment..."
    if ! micromamba list -n "$ENV_NAME" &> /dev/null; then
        echo "❌ Error: Environment verification failed."
        cleanup  # Only remove if verification fails
        return 1
    fi
}


# Trap errors
trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

# **Main Execution Flow**
check_internet || exit 1
check_micromamba
check_micromamba_version
initialize_micromamba || exit 1
create_environment || exit 1
verify_environment || exit 1

# **Final message**
echo "✅ Environment setup is complete! The environment name is: '$ENV_NAME'"
echo -e "✅ To activate the '$ENV_NAME' environment, run:\n   micromamba activate $ENV_NAME"