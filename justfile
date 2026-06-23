# Dotfiles management tasks

# List available recipes
default:
    @just --list

# Install dotfiles and dependencies
install:
    ./install.sh

# Backup existing dotfiles
backup:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Creating backup..."
    BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    for file in .zshrc .aliases .functions .exports .extras .tmux.conf .ripgreprc .fzf.zsh .gitconfig .gitconfig-personal .gitmessage.txt; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$BACKUP_DIR/"
            echo "Backed up $file"
        fi
    done

    echo "Backup created at: $BACKUP_DIR"

# Apply optional macOS defaults (opt-in; macOS only)
macos:
    ./macos.sh

# Install uv-managed CLI tools listed in uv-tools.txt
uv-tools:
    #!/usr/bin/env bash
    set -euo pipefail
    grep -vE '^\s*(#|$)' uv-tools.txt | while read -r tool; do
        echo "uv tool install $tool"
        uv tool install "$tool" || echo "  (failed: $tool, continuing)"
    done

# Refresh uv-tools.txt from the currently installed uv tools
uv-tools-freeze:
    #!/usr/bin/env bash
    set -euo pipefail
    {
        echo "# uv tools to install on a new machine (one package per line)."
        echo "# Reinstalled by install.sh via \`uv tool install\`. Lines starting with # are ignored."
        echo "# Note: mlx / mlx-lm are Apple Silicon only and are skipped on other platforms."
        uv tool list | grep -vE '^-' | awk '{print $1}' | sort -u
    } > uv-tools.txt
    echo "Wrote uv-tools.txt"

# Update dotfiles from repository
update:
    git pull --rebase
    git submodule update --init --recursive

# Remove symlinks (does not remove installed packages)
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Removing symlinks..."

    for file in .zshrc .aliases .functions .exports .extras .tmux.conf .ripgreprc .fzf.zsh .gitconfig .gitconfig-personal .gitmessage.txt; do
        if [ -L "$HOME/$file" ]; then
            rm "$HOME/$file"
            echo "Removed $file"
        fi
    done

    for script in bin/*; do
        name=$(basename "$script")
        if [ -L "$HOME/.local/bin/$name" ]; then
            rm "$HOME/.local/bin/$name"
            echo "Removed $name"
        fi
    done

    if [ -L "$HOME/.config/nvim" ]; then
        rm "$HOME/.config/nvim"
        echo "Removed nvim config"
    fi

    if [ -L "$HOME/.config/git/ignore" ]; then
        rm "$HOME/.config/git/ignore"
        echo "Removed global gitignore"
    fi

    echo "Symlinks removed"

# Test dotfiles configuration
test:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Testing zsh configuration..."
    if zsh -n zsh/zshrc; then
        echo "✓ zshrc syntax OK"
    else
        echo "✗ zshrc syntax error"
    fi

    echo ""
    echo "Testing tmux configuration..."
    if tmux -f tmux/tmux.conf source-file tmux/tmux.conf 2>/dev/null; then
        echo "✓ tmux.conf OK"
    else
        echo "✗ tmux.conf error"
    fi

    echo ""
    echo "Checking for required commands..."
    for cmd in zsh tmux nvim git fzf rg bat eza just; do
        if command -v $cmd >/dev/null 2>&1; then
            echo "✓ $cmd installed"
        else
            echo "✗ $cmd not found"
        fi
    done

# Link dotfiles (create symlinks)
link:
    #!/usr/bin/env bash
    set -euo pipefail
    DOTFILES_DIR="$(pwd)"

    echo "Creating symlinks..."
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

    # Symlink git config
    ln -sf "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
    ln -sf "$DOTFILES_DIR/git/gitconfig-personal" "$HOME/.gitconfig-personal"
    ln -sf "$DOTFILES_DIR/git/gitmessage.txt" "$HOME/.gitmessage.txt"
    if [ ! -f "$HOME/.gitconfig.local" ]; then
        cp "$DOTFILES_DIR/git/gitconfig.local.template" "$HOME/.gitconfig.local"
        echo "Created ~/.gitconfig.local from template. Edit it to set your work email."
    fi
    mkdir -p "$HOME/.config/git"
    ln -sf "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"

    # Symlink bin scripts
    for script in "$DOTFILES_DIR"/bin/*; do
        [ -f "$script" ] || continue
        chmod +x "$script"
        ln -sf "$script" "$HOME/.local/bin/$(basename "$script")"
    done

    # Symlink neovim config
    if [ -d "$DOTFILES_DIR/nvim" ]; then
        mkdir -p "$HOME/.config"
        ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    fi

    echo "Symlinks created successfully"

# Show the status of dotfiles symlinks
status:
    #!/usr/bin/env bash
    echo "Dotfiles symlink status:"
    echo ""

    for file in .zshrc .aliases .functions .exports .extras .tmux.conf .ripgreprc .fzf.zsh .gitconfig .gitconfig-personal .gitmessage.txt; do
        if [ -L "$HOME/$file" ]; then
            target=$(readlink "$HOME/$file")
            echo "✓ $file -> $target"
        elif [ -f "$HOME/$file" ]; then
            echo "✗ $file exists but is not a symlink"
        else
            echo "✗ $file does not exist"
        fi
    done

    echo ""
    for script in bin/*; do
        name=$(basename "$script")
        if [ -L "$HOME/.local/bin/$name" ]; then
            target=$(readlink "$HOME/.local/bin/$name")
            echo "✓ $name -> $target"
        else
            echo "✗ $name not linked"
        fi
    done

    echo ""
    if [ -L "$HOME/.config/nvim" ]; then
        target=$(readlink "$HOME/.config/nvim")
        echo "✓ nvim -> $target"
    else
        echo "✗ nvim config not linked"
    fi
