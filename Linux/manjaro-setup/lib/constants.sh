#!/usr/bin/env bash
# ==============================================================================
# Constants: package lists, URLs, versions
# ==============================================================================

BASE_PACKAGES=(base-devel git wget curl unzip zip tar gzip)
CLI_TOOLS=(zsh fzf tldr htop btop fastfetch tree)
X_TOOLS=(zellij joshuto eza bottom)
CONTAINER_PKGS=(docker docker-compose-plugin lazydocker lazygit)
FONT_PKGS=(noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd)
INPUT_PKGS=(fcitx5 fcitx5-configtool fcitx5-chinese-addons fcitx5-qt fcitx5-gtk fcitx5-rime rime-ice-git)
SECURITY_PKGS=(ufw tailscale openssh)
NPM_GLOBALS=(pnpm yarn tsx nodemon)

DOTFILES_REPO_HTTPS="https://github.com/Euler0525/dotfiles.git"
DOTFILES_REPO_SSH="git@github.com:Euler0525/dotfiles.git"

SSH_PORT=22

PACMAN_UPDATED=false
