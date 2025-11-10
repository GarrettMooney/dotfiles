.PHONY: help install backup update clean test

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install dotfiles and dependencies
	./install.sh

backup: ## Backup existing dotfiles
	@echo "Creating backup..."
	@BACKUP_DIR="$$HOME/.dotfiles_backup_$$(date +%Y%m%d_%H%M%S)"; \
	mkdir -p "$$BACKUP_DIR"; \
	for file in .zshrc .aliases .functions .exports .extras .tmux.conf .ripgreprc .fzf.zsh; do \
		if [ -f "$$HOME/$$file" ]; then \
			cp "$$HOME/$$file" "$$BACKUP_DIR/"; \
			echo "Backed up $$file"; \
		fi; \
	done; \
	echo "Backup created at: $$BACKUP_DIR"

update: ## Update dotfiles from repository
	git pull --rebase
	git submodule update --init --recursive

clean: ## Remove symlinks (does not remove installed packages)
	@echo "Removing symlinks..."
	@for file in .zshrc .aliases .functions .exports .extras .tmux.conf .ripgreprc .fzf.zsh; do \
		if [ -L "$$HOME/$$file" ]; then \
			rm "$$HOME/$$file"; \
			echo "Removed $$file"; \
		fi; \
	done
	@if [ -L "$$HOME/.local/bin/tmux-sessionizer" ]; then \
		rm "$$HOME/.local/bin/tmux-sessionizer"; \
		echo "Removed tmux-sessionizer"; \
	fi
	@if [ -L "$$HOME/.config/nvim" ]; then \
		rm "$$HOME/.config/nvim"; \
		echo "Removed nvim config"; \
	fi
	@echo "Symlinks removed"

test: ## Test dotfiles configuration
	@echo "Testing zsh configuration..."
	@zsh -n zsh/zshrc && echo "✓ zshrc syntax OK" || echo "✗ zshrc syntax error"
	@echo ""
	@echo "Testing tmux configuration..."
	@tmux -f tmux/tmux.conf source-file tmux/tmux.conf \; display-message "tmux config loaded" && echo "✓ tmux.conf OK" || echo "✗ tmux.conf error"
	@echo ""
	@echo "Checking for required commands..."
	@for cmd in zsh tmux nvim git fzf rg bat eza; do \
		command -v $$cmd >/dev/null 2>&1 && echo "✓ $$cmd installed" || echo "✗ $$cmd not found"; \
	done
