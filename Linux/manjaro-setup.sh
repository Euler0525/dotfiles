#!/usr/bin/env bash
# ==============================================================================
# Manjaro/Arch Setup Script (single-file)
# Author: Euler0525
# Usage: ./manjaro-setup.sh
# ==============================================================================
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# --- Logging ---
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
fail()  { echo -e "${RED}[FAIL]${NC} $*" >&2; exit 1; }

# --- Run command, report success/failure, stop on failure ---
run() {
  info "Running: $*"
  if "$@"; then
    ok "$*"
  else
    fail "$* (exit code: $?)"
  fi
}

# --- Append idempotent block to ~/.zshrc ---
zshrc_block() {
  local name="$1"
  local begin="# >>> ${name} <<<"
  local end="# <<< ${name} <<<"
  grep -qF "$begin" ~/.zshrc 2>/dev/null && return 0
  { echo ""; echo "$begin"; cat; echo "$end"; } >> ~/.zshrc
  ok "Appended zshrc block: ${name}"
}

# ==============================================================================
# Pre-flight
# ==============================================================================
[[ $EUID -eq 0 ]] && fail "Do not run as root"
[[ ! -f /etc/manjaro-release && ! -f /etc/arch-release ]] && fail "Only Manjaro/Arch supported"
ping -c 1 -W 3 archlinux.org &>/dev/null || fail "No network connection"

# Sudo keepalive
sudo -v || fail "Cannot acquire sudo"
while true; do sudo -v; sleep 60; done &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null' EXIT

START=$(date +%s)

# ==============================================================================
# Step 1: System update & yay
# ==============================================================================
info "=== Step 1/8: System update & yay ==="

sudo sed -i '/^#Color/s/^#//' /etc/pacman.conf 2>/dev/null || true
sudo sed -i '/^#ParallelDownloads/s/^#//' /etc/pacman.conf 2>/dev/null || true

run sudo pacman-mirrors -i -c China -m rank
run sudo pacman -Syy
run sudo pacman -Syu --noconfirm
run sudo pacman -S --needed --noconfirm base-devel git wget curl unzip zip tar gzip

if ! command -v yay &>/dev/null; then
  info "Building yay from AUR..."
  tmp=$(mktemp -d /tmp/yay-build.XXXXXX)
  git clone --depth 1 https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && GOPROXY=https://goproxy.cn makepkg -si --noconfirm)
  rm -rf "$tmp"
  ok "yay installed"
else
  run yay -Syu --noconfirm
fi

# ==============================================================================
# Step 2: CLI tools & zsh
# ==============================================================================
info "=== Step 2/8: CLI tools & zsh ==="

run yay -S --needed --noconfirm tldr htop btop fastfetch tree

if [[ "$SHELL" != *"zsh"* ]]; then
  chsh -s "$(command -v zsh)"
  ok "Default shell set to zsh"
else
  ok "zsh is already the default shell"
fi

# ==============================================================================
# Step 3: x-cmd & modern CLI tools
# ==============================================================================
info "=== Step 3/8: x-cmd & modern CLI tools ==="

if ! command -v x &>/dev/null; then
  run bash -c "curl -fsSL https://get.x-cmd.com | sh"
fi

zshrc_block "x-cmd" <<'EOF'
[ -f "$HOME/.x-cmd/init.zsh" ] && . "$HOME/.x-cmd/init.zsh"
EOF

run source ~/.zshrc

for tool in zellij eza bottom; do
  command -v "$tool" &>/dev/null && continue
  x install "$tool" || fail "x install $tool failed"
  ok "Installed $tool"
done

# ==============================================================================
# Step 4: Dev environment (Neovim, Node, Python, Rust)
# ==============================================================================
info "=== Step 4/8: Dev environment ==="

# Neovim
run x env use bit
run x env use nvim

# NVM & Node
run yay -S --needed --noconfirm nvm

zshrc_block "nvm" <<'EOF'
source /usr/share/nvm/init-nvm.sh
EOF

export NVM_DIR="$HOME/.nvm"
[ -s /usr/share/nvm/init-nvm.sh ] && source /usr/share/nvm/init-nvm.sh

if ! command -v node &>/dev/null; then
  run nvm install --lts
  run nvm use --lts
fi
run npm install -g pnpm yarn tsx nodemon

# Python (uv)
if ! command -v uv &>/dev/null; then
  run bash -c "curl -fsSL https://astral.sh/uv/install.sh | sh"
fi
zshrc_block "uv" <<'EOF'
eval "$(uv generate-shell-completion zsh)" 2>/dev/null || true
EOF

# Rust
if ! command -v rustup &>/dev/null; then
  run bash -c "curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y"
fi
zshrc_block "cargo" <<'EOF'
source "$HOME/.cargo/env" 2>/dev/null || true
EOF

# ==============================================================================
# Step 5: Container tools (Docker)
# ==============================================================================
info "=== Step 5/8: Container tools ==="

run yay -S --needed --noconfirm docker docker-compose-plugin lazydocker lazygit
run sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
ok "Added $USER to docker group (re-login to apply)"

# ==============================================================================
# Step 6: Fonts & input method (Fcitx5 + Rime)
# ==============================================================================
info "=== Step 6/8: Fonts & input method ==="

run yay -S --needed --noconfirm noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd
run yay -S --needed --noconfirm fcitx5 fcitx5-configtool fcitx5-chinese-addons fcitx5-qt fcitx5-gtk fcitx5-rime rime-ice-git

mkdir -p ~/.local/share/fcitx5/rime
cat > ~/.local/share/fcitx5/rime/default.custom.yaml << 'EOF'
patch:
  __include: rime_ice_suggestion:/
  __patch:
    key_binder/bindings/+:
      - { when: paging, accept: comma, send: Page_Up }
      - { when: has_menu, accept: period, send: Page_Down }
EOF
ok "Rime config written"

zshrc_block "fcitx5" <<'EOF'
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF

# ==============================================================================
# Step 7: Security (UFW, SSH, Tailscale)
# ==============================================================================
info "=== Step 7/8: Security ==="

run yay -S --needed --noconfirm ufw tailscale openssh

run sudo ufw allow 22/tcp
run sudo ufw default deny incoming
run sudo ufw enable

sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config 2>/dev/null || true
run sudo systemctl enable --now sshd
ok "SSH enabled on port 22"

info "Tailscale installed. Run manually: sudo tailscale up"

# ==============================================================================
# Step 8: Dotfiles
# ==============================================================================
info "=== Step 8/8: Dotfiles ==="

# Backup
for f in ~/.config/nvim ~/.zshrc ~/.gitconfig; do
  [[ -e "$f" ]] && cp -a "$f" "${f}.bak.$(date +%F_%H%M%S)" && ok "Backed up $f"
done

# Clone
if [[ ! -d ~/dotfiles ]]; then
  repo="https://github.com/Euler0525/dotfiles.git"
  if [[ -f ~/.ssh/id_ed25519.pub ]] && ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    repo="git@github.com:Euler0525/dotfiles.git"
  fi
  run git clone --recurse-submodules "$repo" ~/dotfiles
else
  (cd ~/dotfiles && git pull --recurse-submodules) || info "dotfiles update skipped, using existing"
fi

# Symlinks
mkdir -p ~/.config
ln -sf ~/dotfiles/submodules/nvim-config ~/.config/nvim
git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim

ln -sf ~/dotfiles/Linux/.gitconfig ~/.gitconfig
ok "Dotfiles symlinks created"

# Append alias
marker="# >>> dotfiles-manjaro >>>"
if ! grep -q "$marker" ~/.zshrc 2>/dev/null; then
  printf '\n%s\n%s\n# <<< dotfiles-manjaro <<<\n' "$marker" "$(cat ~/dotfiles/Linux/zshrc_alias.sh)" >> ~/.zshrc
  ok "dotfiles alias appended to ~/.zshrc"
fi

# ==============================================================================
# Done
# ==============================================================================
echo ""
ok "All done! Elapsed: $(( $(date +%s) - START ))s"
echo ""
info "Post-install:"
echo "  1. exec zsh"
echo "  2. systemctl reboot"
echo "  3. nvim --headless +Lazy!sync +qa"
echo "  4. newgrp docker  (or re-login for Docker)"
echo "  5. sudo tailscale up"
