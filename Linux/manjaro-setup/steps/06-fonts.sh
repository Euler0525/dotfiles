#!/usr/bin/env bash
# ==============================================================================
# Step 6: Fonts, CJK support & input method (Fcitx5 + Rime)
# ==============================================================================

step_fonts() {
  step_start "Configuring fonts & CJK environment"

  # --- Fonts ---
  run_cmd yay -S --needed --noconfirm "${FONT_PKGS[@]}"

  # --- Input method ---
  run_cmd yay -S --needed --noconfirm "${INPUT_PKGS[@]}"

  # --- Rime config ---
  mkdir -p "$HOME/.local/share/fcitx5/rime"
  cat > "$HOME/.local/share/fcitx5/rime/default.custom.yaml" << 'EOF'
patch:
  __include: rime_ice_suggestion:/
  __patch:
    key_binder/bindings/+:
      - { when: paging, accept: comma, send: Page_Up }
      - { when: has_menu, accept: period, send: Page_Down }
EOF
  log "Rime input method config written"

  # --- Environment variables ---
  append_zshrc_block "fcitx5" <<'EOF'
# Fcitx5
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF

  step_done
}
