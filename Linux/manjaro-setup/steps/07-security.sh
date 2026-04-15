#!/usr/bin/env bash
# ==============================================================================
# Step 7: Security — UFW, SSH hardening, Tailscale
# ==============================================================================

step_security() {
  step_start "Installing desktop apps & configuring security"

  run_cmd yay -S --needed --noconfirm "${SECURITY_PKGS[@]}"

  # --- UFW: allow SSH first, then enable (prevent lockout) ---
  run_cmd sudo ufw allow "${SSH_PORT}/tcp"
  run_cmd sudo ufw default deny incoming
  run_cmd sudo ufw enable

  # --- SSH: change port & enable ---
  backup_file /etc/ssh/sshd_config
  sudo sed -i "s/^#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config 2>/dev/null || true
  sudo sed -i "s/^Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config 2>/dev/null || true
  run_cmd sudo systemctl enable --now sshd
  log "SSH configured on port ${SSH_PORT} and enabled"

  # --- Tailscale: install only, user runs `tailscale up` manually ---
  log "Tailscale installed. Run manually: sudo tailscale up"

  step_done
}
