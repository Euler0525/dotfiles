#!/usr/bin/env bash
# ==============================================================================
# Step 3: x-cmd ecosystem & modern terminal tools
# ==============================================================================

step_xcmd() {
  step_start "Configuring x-cmd ecosystem"

  if ! command -v x &>/dev/null; then
    run_cmd bash -c "curl -fsSL https://get.x-cmd.com | sh"
  fi
  run_cmd x upgrade

  append_zshrc_block "x-cmd" <<'EOF'
# x-cmd
[ -f "$HOME/.x-cmd/init.zsh" ] && . "$HOME/.x-cmd/init.zsh"
EOF

  for tool in "${X_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
      run_cmd x install "$tool" || warn "$tool install skipped"
    fi
  done

  step_done
}
