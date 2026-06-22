#!/usr/bin/env bash
set -euo pipefail
# Opt-in macOS tweaks. Run manually: ~/dotfiles/macos.sh
# Conservative, reversible defaults only.

defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.dock autohide -bool true

killall Finder Dock 2>/dev/null || true
echo "macOS defaults applied. Some changes need a logout/login."
