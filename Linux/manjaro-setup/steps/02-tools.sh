#!/usr/bin/env bash
# ==============================================================================
# Step 2: CLI tools & zsh default shell
# ==============================================================================

step_tools() {
  step_start "Installing system tools & terminal enhancements"

  run_cmd yay -S --needed --noconfirm "${CLI_TOOLS[@]}"

  if [[ "$SHELL" != *"zsh"* ]]; then
    log "Setting zsh as default shell..."
    chsh -s "$(command -v zsh)" || warn "chsh failed, run manually: chsh -s \$(which zsh)"
  fi

  step_done
}
