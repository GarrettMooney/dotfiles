#!/usr/bin/env bash

# Bootstrap script for fresh machine setup
# This can be run with: curl -fsSL <raw-url-to-this-script> | bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Detect if git is installed
if ! command -v git &> /dev/null; then
    warn "Git is not installed. Installing git..."

    OS="$(uname -s)"
    case "${OS}" in
        Linux*)
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y git
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y git
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm git
            fi
            ;;
        Darwin*)
            # On macOS, install Xcode Command Line Tools which includes git
            xcode-select --install 2>/dev/null || true
            ;;
    esac
fi

# Clone dotfiles repository
DOTFILES_DIR="$HOME/.dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
    warn "Dotfiles directory already exists at $DOTFILES_DIR"
    read -p "Do you want to remove it and clone fresh? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$DOTFILES_DIR"
    else
        info "Using existing dotfiles directory"
        cd "$DOTFILES_DIR"
        git pull
    fi
fi

if [ ! -d "$DOTFILES_DIR" ]; then
    info "Cloning dotfiles repository..."
    read -p "Enter your dotfiles git repository URL: " REPO_URL
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# Run the installation script
info "Running installation script..."
./install.sh

info "Bootstrap complete!"
info "Please restart your terminal or run: source ~/.zshrc"
