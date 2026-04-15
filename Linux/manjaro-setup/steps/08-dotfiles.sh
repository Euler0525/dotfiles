#!/usr/bin/env bash
# ==============================================================================
# Step 8: Dotfiles — clone repo, create symlinks
# ==============================================================================

step_dotfiles() {
  step_start "Deploying dotfiles"

  # --- Backup existing configs ---
  backup_file ~/.config/nvim
  backup_file ~/.zshrc
  backup_file ~/.gitconfig

  # --- Clone/pull dotfiles ---
  if [[ ! -d ~/dotfiles ]]; then
    clone_dotfiles
  else
    (cd ~/dotfiles && run_cmd git pull --recurse-submodules) || warn "dotfiles update failed, using existing version"
  fi

  # --- Create symlinks ---
  mkdir -p ~/.config
  ln -sf ~/dotfiles/submodules/nvim-config ~/.config/nvim
  ln -sf ~/dotfiles/Linux/.gitconfig ~/.gitconfig
  log "Dotfiles symlinks created"

  # --- Append alias config to ~/.zshrc ---
  local marker="# >>> dotfiles-manjaro >>>"
  if ! grep -q "$marker" ~/.zshrc 2>/dev/null; then
    printf '\n%s\n%s\n# <<< dotfiles-manjaro <<<\n' "$marker" "$(cat ~/dotfiles/Linux/zshrc_alias.sh)" >> ~/.zshrc
    log "dotfiles alias config appended to ~/.zshrc"
  else
    log "dotfiles alias config already present, skipping"
  fi

  step_done
}

clone_dotfiles() {
  local repo_url="$DOTFILES_REPO_HTTPS"

  # Test SSH key is registered with GitHub before using SSH URL.
  # GitHub returns "successfully authenticated" but exits with code 1,
  # so we grep the output instead of checking exit code.
  if [[ -f ~/.ssh/id_ed25519.pub ]] && ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    repo_url="$DOTFILES_REPO_SSH"
    log "SSH key verified, cloning via SSH"
  fi

  run_cmd git clone --recurse-submodules "$repo_url" ~/dotfiles
}
