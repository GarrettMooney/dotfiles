#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo -e "${GREEN}Detected OS: ${MACHINE}${NC}"

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Backup existing dotfiles
backup_dotfiles() {
    info "Backing up existing dotfiles..."
    BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    local files=(".zshrc" ".aliases" ".functions" ".exports" ".extras" ".tmux.conf" ".ripgreprc" ".fzf.zsh")
    for file in "${files[@]}"; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$BACKUP_DIR/"
            info "Backed up $file"
        fi
    done

    if [ -d "$HOME/.local/bin/tmux-sessionizer" ] || [ -f "$HOME/.local/bin/tmux-sessionizer" ]; then
        mkdir -p "$BACKUP_DIR/.local/bin"
        cp "$HOME/.local/bin/tmux-sessionizer" "$BACKUP_DIR/.local/bin/" 2>/dev/null || true
    fi

    info "Backup created at: $BACKUP_DIR"
}

# Install dependencies for macOS
install_macos_deps() {
    info "Installing macOS dependencies..."

    # Install Homebrew if not present
    if ! command_exists brew; then
        warn "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon
        if [[ $(uname -m) == 'arm64' ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        info "Homebrew already installed"
    fi

    # Install packages
    local packages=(
        "zsh"
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
        "fzf"
        "ripgrep"
        "eza"
        "bat"
        "direnv"
        "zoxide"
        "neovim"
        "tmux"
        "git"
        "gh"
        "thefuck"
        "just"
        "jq"
        "yq"
    )

    info "Installing Homebrew packages..."
    for package in "${packages[@]}"; do
        if brew list "$package" &>/dev/null; then
            info "$package already installed"
        else
            info "Installing $package..."
            brew install "$package"
        fi
    done
}

# Install dependencies for Linux
install_linux_deps() {
    info "Installing Linux dependencies..."

    # Detect package manager
    if command_exists apt-get; then
        PKG_MANAGER="apt-get"
        INSTALL_CMD="sudo apt-get install -y"
    elif command_exists dnf; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
    elif command_exists yum; then
        PKG_MANAGER="yum"
        INSTALL_CMD="sudo yum install -y"
    elif command_exists pacman; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
    else
        error "No supported package manager found"
        exit 1
    fi

    info "Using package manager: $PKG_MANAGER"

    # Update package lists
    if [ "$PKG_MANAGER" = "apt-get" ]; then
        sudo apt-get update
    fi

    # Install packages based on package manager
    if [ "$PKG_MANAGER" = "apt-get" ]; then
        local packages=(
            "zsh"
            "fzf"
            "ripgrep"
            "bat"
            "direnv"
            "tmux"
            "git"
            "build-essential"
            "curl"
            "jq"
        )

        for package in "${packages[@]}"; do
            $INSTALL_CMD "$package"
        done

        # bat is sometimes called batcat on Ubuntu/Debian
        if command_exists batcat && ! command_exists bat; then
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
        fi
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        $INSTALL_CMD zsh fzf ripgrep bat direnv tmux git base-devel curl jq
    else
        $INSTALL_CMD zsh fzf ripgrep bat direnv tmux git curl jq
    fi

    # Install zoxide (not in all repos)
    if ! command_exists zoxide; then
        info "Installing zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    fi

    # Install eza (modern ls replacement)
    if ! command_exists eza; then
        info "Installing eza..."
        if [ "$PKG_MANAGER" = "apt-get" ]; then
            sudo mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
            sudo apt-get update
            sudo apt-get install -y eza
        else
            warn "eza installation not automated for this package manager. Please install manually."
        fi
    fi

    # Install neovim (latest version)
    if ! command_exists nvim; then
        info "Installing neovim..."
        if [ "$PKG_MANAGER" = "apt-get" ]; then
            curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
            chmod u+x nvim.appimage
            sudo mv nvim.appimage /usr/local/bin/nvim
        else
            $INSTALL_CMD neovim
        fi
    fi

    # Install thefuck
    if ! command_exists thefuck; then
        info "Installing thefuck via pip..."
        if command_exists pip3; then
            pip3 install --user thefuck
        elif command_exists pip; then
            pip install --user thefuck
        else
            warn "pip not found. Please install thefuck manually."
        fi
    fi

    # Install just (command runner)
    if ! command_exists just; then
        info "Installing just..."
        if command_exists cargo; then
            cargo install just
        else
            # Install precompiled binary
            info "Installing just from GitHub releases..."
            curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
        fi
    fi
}

# Install oh-my-zsh
install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing oh-my-zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        info "oh-my-zsh already installed"
    fi
}

# Install Rust/Cargo
install_rust() {
    if ! command_exists cargo; then
        info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        info "Rust already installed"
    fi
}

# Install NVM (Node Version Manager)
install_nvm() {
    if [ ! -d "$HOME/.nvm" ]; then
        info "Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        # Install Node.js 22
        if command_exists nvm; then
            nvm install 22
            nvm use 22
        fi
    else
        info "nvm already installed"
    fi
}

# Install fzf
install_fzf() {
    if [ ! -d "$HOME/.fzf" ]; then
        info "Installing fzf from git..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-bash --no-fish
    else
        info "fzf git repo already installed"
    fi
}

# Create symlinks
create_symlinks() {
    info "Creating symlinks..."

    local DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Create .local/bin if it doesn't exist
    mkdir -p "$HOME/.local/bin"

    # Symlink zsh files
    ln -sf "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
    ln -sf "$DOTFILES_DIR/zsh/aliases" "$HOME/.aliases"
    ln -sf "$DOTFILES_DIR/zsh/functions" "$HOME/.functions"
    ln -sf "$DOTFILES_DIR/zsh/exports" "$HOME/.exports"
    ln -sf "$DOTFILES_DIR/zsh/extras" "$HOME/.extras"
    ln -sf "$DOTFILES_DIR/zsh/ripgreprc" "$HOME/.ripgreprc"
    ln -sf "$DOTFILES_DIR/zsh/fzf.zsh" "$HOME/.fzf.zsh"

    # Symlink tmux
    ln -sf "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

    # Symlink bin scripts
    ln -sf "$DOTFILES_DIR/bin/tmux-sessionizer" "$HOME/.local/bin/tmux-sessionizer"
    chmod +x "$HOME/.local/bin/tmux-sessionizer"

    # Symlink neovim config
    if [ -d "$DOTFILES_DIR/nvim" ]; then
        mkdir -p "$HOME/.config"
        ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    else
        warn "nvim config not found in dotfiles. Skipping..."
    fi

    info "Symlinks created successfully"
}

# Change default shell to zsh
change_shell() {
    if [ "$SHELL" != "$(which zsh)" ]; then
        info "Changing default shell to zsh..."
        chsh -s "$(which zsh)"
        info "Default shell changed. Please log out and log back in for changes to take effect."
    else
        info "Default shell is already zsh"
    fi
}

# Main installation
main() {
    info "Starting dotfiles installation..."

    # Backup existing dotfiles
    backup_dotfiles

    # Install dependencies based on OS
    if [ "$MACHINE" = "Mac" ]; then
        install_macos_deps
    elif [ "$MACHINE" = "Linux" ]; then
        install_linux_deps
    else
        error "Unsupported OS: $MACHINE"
        exit 1
    fi

    # Install common tools
    install_oh_my_zsh
    install_rust
    install_nvm
    install_fzf

    # Create symlinks
    create_symlinks

    # Change shell
    change_shell

    info "Installation complete!"
    info "Please restart your terminal or run: source ~/.zshrc"
}

# Run main installation
main
