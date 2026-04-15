#!/usr/bin/env bash
# ==============================================================================
# Step 1: System update & yay installation
# ==============================================================================

step_system() {
  step_start "System update & yay installation"

  # --- pacman.conf ---
  backup_file /etc/pacman.conf

  sudo sed -i '/^#Color/s/^#//' /etc/pacman.conf 2>/dev/null || true
  sudo sed -i '/^#ParallelDownloads = 5/s/^#//' /etc/pacman.conf 2>/dev/null || true
  sudo sed -i '/^#VerbosePkgLists/s/^#//' /etc/pacman.conf 2>/dev/null || true

  # --- pacman mirrors: use fastest Chinese mirrors ---
  run_cmd sudo pacman-mirrors --country China --fastest 5
  run_cmd sudo pacman -Syy

  # --- System update ---
  run_cmd sudo pacman -Syu --noconfirm
  run_cmd sudo pacman -S --needed --noconfirm "${BASE_PACKAGES[@]}"

  # --- yay ---
  if ! command -v yay &>/dev/null; then
    log "Building yay from AUR..."
    local build_dir
    build_dir=$(mktemp -d /tmp/yay-build.XXXXXX)
    (
      cd "$build_dir/yay" || exit 1
      git clone --depth 1 https://aur.archlinux.org/yay.git "$build_dir/yay"
      makepkg -si --noconfirm
    )
    rm -rf "$build_dir"
    log "yay installation complete"
  else
    run_cmd yay -Syu --noconfirm
  fi

  PACMAN_UPDATED=true
  step_done
}
