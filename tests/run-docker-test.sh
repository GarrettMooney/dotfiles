#!/usr/bin/env bash

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Usage
usage() {
    echo "Usage: $0 [ubuntu|debian|all]"
    echo ""
    echo "Test dotfiles installation in Docker containers"
    echo ""
    echo "Options:"
    echo "  ubuntu  - Test on Ubuntu 22.04"
    echo "  debian  - Test on Debian Bookworm"
    echo "  all     - Test on all distributions (default)"
    exit 1
}

# Test function
run_test() {
    local distro=$1
    local dockerfile="Dockerfile.${distro}"

    info "=========================================="
    info "Testing on ${distro}"
    info "=========================================="

    # Build the image
    info "Building Docker image for ${distro}..."
    docker build -f "tests/${dockerfile}" -t "dotfiles-test-${distro}" .

    # Run the test
    info "Running installation test on ${distro}..."
    docker run --rm \
        -v "$(pwd):/dotfiles:ro" \
        "dotfiles-test-${distro}" \
        bash /dotfiles/tests/test-install.sh

    info "✓ ${distro} test passed!"
    echo ""
}

# Main
main() {
    local target="${1:-all}"

    case "$target" in
        ubuntu)
            run_test ubuntu
            ;;
        debian)
            run_test debian
            ;;
        all)
            run_test ubuntu
            run_test debian
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $target"
            usage
            ;;
    esac

    info "=========================================="
    info "All tests completed successfully! ✓"
    info "=========================================="
}

main "$@"
