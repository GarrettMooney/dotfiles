#!/usr/bin/env bash

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test function
test_command() {
    local cmd=$1
    if command -v "$cmd" >/dev/null 2>&1; then
        info "✓ $cmd is installed"
        return 0
    else
        error "✗ $cmd is not installed"
        return 1
    fi
}

# Main test
main() {
    info "Starting dotfiles installation test..."

    # Clone the repository (or use local copy if mounted)
    if [ -d "/dotfiles" ]; then
        info "Using mounted dotfiles directory"
        cp -r /dotfiles ~/.dotfiles
    else
        info "Cloning dotfiles repository"
        git clone https://github.com/GarrettMooney/dotfiles.git ~/.dotfiles
    fi

    cd ~/.dotfiles

    # Run installation
    info "Running installation script..."
    ./install.sh

    # Test that essential commands are installed
    info "Testing installed commands..."

    FAILED=0

    test_command "zsh" || FAILED=$((FAILED + 1))
    test_command "tmux" || FAILED=$((FAILED + 1))
    test_command "nvim" || FAILED=$((FAILED + 1))
    test_command "fzf" || FAILED=$((FAILED + 1))
    test_command "rg" || FAILED=$((FAILED + 1))
    test_command "git" || FAILED=$((FAILED + 1))
    test_command "just" || FAILED=$((FAILED + 1))

    # Test that dotfiles are symlinked
    info "Testing symlinks..."

    if [ -L "$HOME/.zshrc" ]; then
        info "✓ .zshrc is symlinked"
    else
        error "✗ .zshrc is not symlinked"
        FAILED=$((FAILED + 1))
    fi

    if [ -L "$HOME/.tmux.conf" ]; then
        info "✓ .tmux.conf is symlinked"
    else
        error "✗ .tmux.conf is not symlinked"
        FAILED=$((FAILED + 1))
    fi

    if [ -L "$HOME/.aliases" ]; then
        info "✓ .aliases is symlinked"
    else
        error "✗ .aliases is not symlinked"
        FAILED=$((FAILED + 1))
    fi

    # Test zsh syntax
    info "Testing zsh configuration syntax..."
    if zsh -n ~/.zshrc 2>/dev/null; then
        info "✓ .zshrc syntax is valid"
    else
        error "✗ .zshrc has syntax errors"
        FAILED=$((FAILED + 1))
    fi

    # Test just commands
    info "Testing just commands..."
    cd ~/.dotfiles
    if just --list >/dev/null 2>&1; then
        info "✓ justfile is valid"
    else
        error "✗ justfile has errors"
        FAILED=$((FAILED + 1))
    fi

    # Summary
    echo ""
    if [ $FAILED -eq 0 ]; then
        info "=========================================="
        info "All tests passed! ✓"
        info "=========================================="
        exit 0
    else
        error "=========================================="
        error "$FAILED test(s) failed! ✗"
        error "=========================================="
        exit 1
    fi
}

main
