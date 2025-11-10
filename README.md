# Dotfiles

Personal dotfiles for zsh, tmux, neovim, and various shell utilities. Supports both macOS and Linux.

## What's Included

### Shell Configuration
- **zsh**: Main shell configuration with oh-my-zsh
  - `zshrc` - Main zsh configuration
  - `aliases` - Command aliases
  - `functions` - Custom shell functions
  - `exports` - Environment variables
  - `extras` - Additional zsh plugins and settings
  - `ripgreprc` - Ripgrep configuration
  - `fzf.zsh` - FZF configuration

### Terminal Multiplexer
- **tmux**: Terminal multiplexer configuration
  - `tmux.conf` - Tmux settings with vim-like keybindings
  - `tmux-sessionizer` - Quick project switching script

### Editor
- **nvim**: Neovim configuration (to be added)

## Features

### Aliases
- Git shortcuts (g, ga, gc, gs, etc.)
- Directory navigation (.., ..., cd shortcuts)
- Quick editing of dotfiles (ea, et, ez)
- Tmux shortcuts (t, tat, tls, etc.)

### Functions
- `addToPath` / `addToPathFront` - Safely add to PATH
- `mkcd` - Create directory and cd into it
- `bootstrap` - Setup Python virtual environments
- `todo` - Quick access to TODO.md files
- `listkernels` / `removekernel` - Manage Jupyter kernels
- `dockercleanup` - Clean up Docker containers
- And many more...

### Tools Installed
- **oh-my-zsh** - Zsh framework
- **fzf** - Fuzzy finder
- **ripgrep** - Fast grep alternative
- **eza** - Modern ls replacement
- **bat** - Cat with syntax highlighting
- **direnv** - Directory-based environment variables
- **zoxide** - Smart cd replacement
- **neovim** - Modern vim
- **tmux** - Terminal multiplexer
- **thefuck** - Command corrector
- **just** - Command runner for project tasks
- **nvm** - Node version manager
- **rust/cargo** - Rust toolchain

## Installation

### Quick Start (Fresh Machine)

```bash
# Install git if not already installed
# Then run:
curl -fsSL https://raw.githubusercontent.com/GarrettMooney/dotfiles/main/bootstrap.sh | bash
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/GarrettMooney/dotfiles.git ~/.dotfiles

# Run the installation script
cd ~/.dotfiles
./install.sh
```

The installation script will:
1. Backup your existing dotfiles
2. Install all dependencies (Homebrew on macOS, apt/dnf/pacman on Linux)
3. Install oh-my-zsh, Rust, NVM, and other tools
4. Create symlinks to all dotfiles
5. Change your default shell to zsh

### What Gets Installed

#### macOS (via Homebrew)
- zsh, zsh-autosuggestions, zsh-syntax-highlighting
- fzf, ripgrep, eza, bat
- direnv, zoxide, thefuck, just
- neovim, tmux, git, gh, jq, yq

#### Linux (via apt/dnf/pacman)
- zsh, fzf, ripgrep, bat
- direnv, zoxide, tmux, git
- build tools, curl, jq
- neovim (latest appimage on Ubuntu)
- eza (from community repos)
- just (via cargo or precompiled binary)

#### Cross-platform
- oh-my-zsh
- Rust/Cargo
- NVM (Node Version Manager) + Node 22
- fzf (git version)

## Post-Installation

### Setting up API Keys and Tokens

1. Copy the tokens template:
   ```bash
   cp ~/.dotfiles/zsh/tokens.template ~/.tokens
   ```

2. Edit `~/.tokens` with your actual API keys and tokens
   ```bash
   vim ~/.tokens
   ```

3. The `.tokens` file is gitignored and will not be committed

### Neovim Setup

If you have an existing neovim configuration:
```bash
# Copy or symlink your nvim config
cp -r ~/.config/nvim ~/.dotfiles/nvim
# Or if it's already a git repo:
cd ~/.dotfiles
git submodule add <your-nvim-repo-url> nvim
```

### Customization

#### Adding Personal Overrides

Create a `~/.tokens` file for sensitive data (API keys, tokens, etc.) that shouldn't be committed:
```bash
# ~/.tokens
export ANTHROPIC_API_KEY="your-key-here"
export OPENAI_API_KEY="your-key-here"
```

#### Modifying Configurations

All dotfiles are symlinked, so you can edit them directly in your home directory:
```bash
vim ~/.zshrc  # Edits ~/.dotfiles/zsh/zshrc
```

Or edit in the dotfiles directory:
```bash
cd ~/.dotfiles
vim zsh/zshrc
```

## Managing Dotfiles with Just

The repository includes a `justfile` for common tasks. Run `just` to see all available commands:

```bash
cd ~/.dotfiles
just
```

### Available Commands

- `just install` - Run the installation script
- `just backup` - Backup existing dotfiles before making changes
- `just update` - Pull latest changes from git and update submodules
- `just link` - Create symlinks for all dotfiles
- `just clean` - Remove all symlinks
- `just test` - Test configurations (syntax check for zsh, tmux, check installed tools)
- `just status` - Show the status of all dotfile symlinks

### Examples

```bash
# Backup current dotfiles
just backup

# Update to latest version
just update

# Check if everything is properly linked
just status

# Test configurations before applying
just test
```

## Tmux Keybindings

Prefix: `Ctrl+a`

### Session Management
- `Ctrl+a f` - Fuzzy find and switch to project (tmux-sessionizer)
- `Ctrl+a H` - Jump to home directory
- `Ctrl+a G` - Jump to ~/git
- `Ctrl+a W` - Jump to ~/work
- `Ctrl+a P` - Jump to ~/personal
- `Ctrl+a S` - Jump to ~/scratchpad
- `Ctrl+a D` - Open TODO.md

### Window/Pane Management
- `Ctrl+a |` - Split pane vertically
- `Ctrl+a -` - Split pane horizontally
- `Ctrl+a h/j/k/l` - Navigate panes (vim-style)
- `Ctrl+a ^` - Last window

### Other
- `Ctrl+a r` - Reload tmux config
- Vi mode for copy mode

## Updating

To pull the latest changes:
```bash
cd ~/.dotfiles
git pull
```

To push your changes:
```bash
cd ~/.dotfiles
git add .
git commit -m "Update dotfiles"
git push
```

## Directory Structure

```
.
├── README.md
├── install.sh          # Main installation script
├── bootstrap.sh        # Quick bootstrap for fresh machines
├── justfile            # Task runner commands
├── .gitignore
├── zsh/
│   ├── zshrc
│   ├── aliases
│   ├── functions
│   ├── exports
│   ├── extras
│   ├── ripgreprc
│   ├── fzf.zsh
│   └── tokens.template
├── tmux/
│   └── tmux.conf
├── nvim/               # Neovim configuration (git submodule)
├── bin/
│   └── tmux-sessionizer
└── tests/              # Docker-based testing
    ├── README.md
    ├── Dockerfile.ubuntu
    ├── Dockerfile.debian
    ├── test-install.sh
    └── run-docker-test.sh
```

## Testing

Docker-based tests are available to validate the installation on different Linux distributions:

```bash
# Test on all distributions
./tests/run-docker-test.sh

# Test on specific distribution
./tests/run-docker-test.sh ubuntu
./tests/run-docker-test.sh debian
```

The tests validate:
- All dependencies are installed correctly
- Dotfiles are properly symlinked
- Shell configurations have valid syntax
- Essential commands are available

See [tests/README.md](tests/README.md) for more details.

## Troubleshooting

### Zsh plugins not loading
Make sure the plugins are installed:
```bash
# macOS
brew install zsh-autosuggestions zsh-syntax-highlighting

# Linux - install manually or via package manager
```

### Tmux colors not working
Make sure your terminal supports 256 colors and true color:
```bash
echo $TERM  # Should be "xterm-256color" or "tmux-256color"
```

### NVM not found
Restart your shell or source the configuration:
```bash
source ~/.zshrc
```

## Credits

Configurations inspired by various dotfiles repos and ThePrimeagen's setup.

## License

MIT License - Feel free to use and modify as needed.
