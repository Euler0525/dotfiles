#!/usr/bin/env bash
# ==============================================================================
# Shared utilities: logging, backup, run_cmd, sudo keepalive, zshrc blocks
# ==============================================================================

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Global state
LOG_FILE="${LOG_FILE:-$HOME/.manjaro-setup.log}"
BACKUP_BASE="${BACKUP_BASE:-$HOME/.manjaro-setup.bak}"
DRY_RUN="${DRY_RUN:-false}"
STEP="${STEP:-0}"
TOTAL_STEPS=8
START_TIME="${START_TIME:-$(date +%s)}"

# ==============================================================================
# Logging
# ==============================================================================

log() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE" >&2; }

# ==============================================================================
# Backup
# ==============================================================================

backup_file() {
  local target="$1"
  local backup_dir="${BACKUP_BASE}/$(date +%F_%H%M%S)/${target//\//_}"
  if [[ -e "$target" ]]; then
    mkdir -p "$backup_dir"
    cp -a "$target" "$backup_dir/"
    log "Backed up: $target -> $backup_dir"
  fi
}

# ==============================================================================
# Command execution — no eval, proper PIPESTATUS
# ==============================================================================

run_cmd() {
  local exit_code
  if $DRY_RUN; then
    warn "[DRY RUN] $*"
    return 0
  fi
  log "Executing: $*"
  set +e
  "$@" 2>&1 | tee -a "$LOG_FILE"
  exit_code=${PIPESTATUS[0]}
  set -e
  if [[ $exit_code -ne 0 ]]; then
    error "Command failed (exit code: $exit_code): $*"
    return $exit_code
  fi
}

# ==============================================================================
# Sudo keepalive — background loop with cleanup
# ==============================================================================

SUDO_KEEPALIVE_PID=""

start_sudo_keepalive() {
  sudo -v || { error "Cannot acquire sudo, check password or visudo config"; exit 1; }
  while true; do sudo -v; sleep 60; done &
  SUDO_KEEPALIVE_PID=$!
}

stop_sudo_keepalive() {
  [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
}

# ==============================================================================
# .zshrc block management — marker-based idempotency
# ==============================================================================

append_zshrc_block() {
  local name="$1"
  local marker_begin="# >>> MANJARO-SETUP ${name} <<<"
  local marker_end="# <<< MANJARO-SETUP ${name} <<<"
  local zshrc="${HOME}/.zshrc"

  # Skip if block already exists
  if grep -qF "$marker_begin" "$zshrc" 2>/dev/null; then
    log "zshrc block '${name}' already exists, skipping"
    return 0
  fi

  if $DRY_RUN; then
    warn "[DRY RUN] Would append zshrc block: ${name}"
    return 0
  fi

  log "Appending zshrc block: ${name}"
  {
    echo ""
    echo "$marker_begin"
    cat
    echo "$marker_end"
  } >> "$zshrc"
}

remove_zshrc_block() {
  local name="$1"
  local marker_begin="# >>> MANJARO-SETUP ${name} <<<"
  local marker_end="# <<< MANJARO-SETUP ${name} <<<"
  local zshrc="${HOME}/.zshrc"

  if ! grep -qF "$marker_begin" "$zshrc" 2>/dev/null; then
    return 0
  fi

  log "Removing zshrc block: ${name}"
  sed -i "/^${marker_begin}/,/^${marker_end}/d" "$zshrc"
}

# ==============================================================================
# Pre-flight checks
# ==============================================================================

check_root() {
  if [[ $EUID -eq 0 ]]; then
    error "Do not run as root. The script will request sudo as needed."
    exit 1
  fi
}

check_distro() {
  if [[ ! -f /etc/manjaro-release && ! -f /etc/arch-release ]]; then
    error "This script only supports Manjaro / Arch Linux"
    exit 1
  fi
}

check_network() {
  if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
    error "Cannot connect to archlinux.org, check network"
    exit 1
  fi
}

# ==============================================================================
# Error handler
# ==============================================================================

setup_error_handler() {
  trap 'error_handler $? $LINENO "${BASH_SOURCE[1]:-$0}"' ERR
}

error_handler() {
  local exit_code=$1 line=$2 source="${3:-unknown}"
  stop_sudo_keepalive
  error "Script exited unexpectedly at ${source} line ${line} (code: ${exit_code})"
  echo -e "\n${RED}========================================${NC}"
  echo -e "${YELLOW}Deployment interrupted, follow these steps to recover:${NC}"
  echo -e "1. View full log: tail -n 50 $LOG_FILE"
  echo -e "2. Restore configs: cp -r ${BACKUP_BASE}/$(date +%F)*/* ~/ or /etc/ as needed"
  echo -e "3. Clean temporary state: yay -Scc 2>/dev/null; rm -rf /tmp/yay-build-*"
  echo -e "4. Re-run: $0 (script is idempotent, safe to re-run)"
  echo -e "${RED}========================================${NC}"
  exit $exit_code
}

# ==============================================================================
# Step progress helpers
# ==============================================================================

step_start() {
  ((STEP++))
  log ">>> Step ${STEP}/${TOTAL_STEPS}: $1..."
}

step_done() {
  success "Step ${STEP}/${TOTAL_STEPS} done"
}
