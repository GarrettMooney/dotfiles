# New machine checklist (manual steps)

Steps that `install.sh` cannot do for you. Run them after `./install.sh`.

- [ ] Set your git identity: edit `~/.gitconfig.local` and set your work email
      (created from `git/gitconfig.local.template` on first run). Repos under
      `~/personal/` automatically use the personal identity.
- [ ] Generate an SSH key and add it to work GitHub/GitLab:
      `ssh-keygen -t ed25519 -C "you@work.com"` then add `~/.ssh/id_ed25519.pub`.
- [ ] Grant Accessibility + Input Monitoring permissions: Karabiner-Elements, Raycast.
- [ ] Sign in: Slack, Spotify, Obsidian, Google Drive, 1Password (or org password manager).
- [ ] App Store sign-in, then install any `mas` apps (or add `mas` lines to the Brewfile).
- [ ] Set Raycast as the Spotlight replacement (cmd-space) in Raycast settings.
- [ ] Confirm Ghostty loaded its config (terminal looks right).
- [ ] Optional: `just macos` to apply macOS defaults.
- [ ] Restart the terminal so brew shellenv + oh-my-zsh load.
