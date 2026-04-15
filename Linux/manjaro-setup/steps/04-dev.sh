#!/usr/bin/env bash
# ==============================================================================
# Step 4: Development environment — Neovim, Node, Python, Rust
# ==============================================================================

step_dev() {
  step_start "Configuring development environment"

  # --- Neovim ---
  run_cmd x env use bit nvim

  # --- NVM & Node ---
  append_zshrc_block "nvm" <<'EOF'
# NVM
source /usr/share/nvm/init-nvm.sh
EOF

  if ! command -v nvm &>/dev/null; then
    run_cmd yay -S --needed --noconfirm nvm
  fi

  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  [ -s /usr/share/nvm/init-nvm.sh ] && source /usr/share/nvm/init-nvm.sh

  if ! command -v node &>/dev/null; then
    run_cmd nvm install --lts
    run_cmd nvm use --lts
  fi

  run_cmd npm install -g "${NPM_GLOBALS[@]}"

  # --- Python (uv) ---
  if ! command -v uv &>/dev/null; then
    run_cmd bash -c "curl -fsSL https://astral.sh/uv/install.sh | sh"
  fi

  append_zshrc_block "uv" <<'EOF'
# uv shell completion
eval "$(uv generate-shell-completion zsh)" 2>/dev/null || true
EOF

  # --- Rust ---
  if ! command -v rustup &>/dev/null; then
    run_cmd bash -c "curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y"
  fi

  append_zshrc_block "cargo" <<'EOF'
# Cargo
source "$HOME/.cargo/env" 2>/dev/null || true
EOF

  step_done
}
