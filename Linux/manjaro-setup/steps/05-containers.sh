#!/usr/bin/env bash
# ==============================================================================
# Step 5: Container tools — Docker, Podman
# ==============================================================================

step_containers() {
  step_start "Installing container tools"

  run_cmd yay -S --needed --noconfirm "${CONTAINER_PKGS[@]}"

  run_cmd sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER" 2>/dev/null || true
  warn "Docker group change requires re-login or run: newgrp docker"

  step_done
}
