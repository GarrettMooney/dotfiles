# Dotfiles Testing

Docker-based tests for validating dotfiles installation on different Linux distributions.

## Prerequisites

- Docker installed and running
- Run from the dotfiles root directory

## Quick Start

```bash
# Test on all distributions
./tests/run-docker-test.sh

# Test on specific distribution
./tests/run-docker-test.sh ubuntu
./tests/run-docker-test.sh debian
```

## What Gets Tested

The test suite validates:

1. **Installation** - All dependencies are installed correctly
2. **Symlinks** - Dotfiles are properly symlinked to home directory
3. **Syntax** - Shell configurations have valid syntax
4. **Commands** - Essential commands are available:
   - zsh
   - tmux
   - nvim
   - fzf
   - ripgrep (rg)
   - git
   - just

## Supported Distributions

- **Ubuntu 22.04** - `tests/Dockerfile.ubuntu`
- **Debian Bookworm** - `tests/Dockerfile.debian`

## Manual Testing

You can also run the tests manually:

```bash
# Build the test image
docker build -f tests/Dockerfile.ubuntu -t dotfiles-test-ubuntu .

# Run the container interactively
docker run -it --rm -v $(pwd):/dotfiles:ro dotfiles-test-ubuntu bash

# Inside the container, run the test script
bash /dotfiles/tests/test-install.sh
```

## Adding New Distributions

To add a new distribution:

1. Create `tests/Dockerfile.<distro>`
2. Update `tests/run-docker-test.sh` to include the new distro
3. Test it: `./tests/run-docker-test.sh <distro>`
