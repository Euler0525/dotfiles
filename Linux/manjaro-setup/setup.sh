#!/usr/bin/env bash
# ==============================================================================
# Manjaro/Arch Secure Deployment Script (v3.0 — modular)
# Author: Euler0525
# Features: strict mode, auto-backup, idempotent execution, failure recovery, non-interactive
# ==============================================================================
set -euo pipefail

# Resolve script directory (handles symlinks)
SETUP_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
export SETUP_ROOT

# Source libraries
# shellcheck source=lib/utils.sh
source "${SETUP_ROOT}/lib/utils.sh"
# shellcheck source=lib/constants.sh
source "${SETUP_ROOT}/lib/constants.sh"

# Export for step modules
export LOG_FILE BACKUP_BASE DRY_RUN STEP TOTAL_STEPS START_TIME

# ==============================================================================
# Argument parsing
# ==============================================================================
RUN_STEP=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; export DRY_RUN; shift ;;
    --step)
      RUN_STEP="$2"; shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [--step N] [--help]"
      echo "  --dry-run    Simulate execution, no system changes"
      echo "  --step N     Run only step N (1-8)"
      echo "  --help       Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ==============================================================================
# Source step modules
# ==============================================================================

# shellcheck source=steps/01-system.sh
source "${SETUP_ROOT}/steps/01-system.sh"
# shellcheck source=steps/02-tools.sh
source "${SETUP_ROOT}/steps/02-tools.sh"
# shellcheck source=steps/03-xcmd.sh
source "${SETUP_ROOT}/steps/03-xcmd.sh"
# shellcheck source=steps/04-dev.sh
source "${SETUP_ROOT}/steps/04-dev.sh"
# shellcheck source=steps/05-containers.sh
source "${SETUP_ROOT}/steps/05-containers.sh"
# shellcheck source=steps/06-fonts.sh
source "${SETUP_ROOT}/steps/06-fonts.sh"
# shellcheck source=steps/07-security.sh
source "${SETUP_ROOT}/steps/07-security.sh"
# shellcheck source=steps/08-dotfiles.sh
source "${SETUP_ROOT}/steps/08-dotfiles.sh"

# ==============================================================================
# Pre-flight checks
# ==============================================================================

check_root
check_distro
check_network
setup_error_handler

# Initialize log
mkdir -p "$(dirname "$LOG_FILE")"
echo "=== Manjaro Setup Log: $(date) ===" > "$LOG_FILE"

log "Starting system deployment (log: $LOG_FILE)"
$DRY_RUN && warn "DRY-RUN mode active, no system changes will be made"

# ==============================================================================
# Run steps
# ==============================================================================

start_sudo_keepalive
trap stop_sudo_keepalive EXIT

STEPS=(
  "step_system"
  "step_tools"
  "step_xcmd"
  "step_dev"
  "step_containers"
  "step_fonts"
  "step_security"
  "step_dotfiles"
)

if [[ -n "$RUN_STEP" ]]; then
  if [[ "$RUN_STEP" -lt 1 || "$RUN_STEP" -gt "${#STEPS[@]}" ]]; then
    error "Invalid step number: $RUN_STEP (range: 1-${#STEPS[@]})"
    exit 1
  fi
  STEP=$((RUN_STEP - 1))
  "${STEPS[$((RUN_STEP - 1))]}"
else
  for step_fn in "${STEPS[@]}"; do
    "$step_fn"
  done
fi

stop_sudo_keepalive

# ==============================================================================
# Summary & next steps
# ==============================================================================

echo
success "System deployment complete! Time elapsed: $(( $(date +%s) - START_TIME )) seconds"
echo -e "${BLUE}Required post-install steps:${NC}"
echo "  1. Reload shell: exec zsh"
echo "  2. Reboot to apply: systemctl reboot"
echo "  3. Neovim plugin auto-install on first launch: nvim --headless +Lazy!sync +qa"
echo "  4. Docker group permissions: newgrp docker or re-login"
echo -e "${BLUE}Common commands:${NC}"
echo "  • Update: yay -Syu  • Clean: yay -Yc  • Search: yay -Ss <pkg>"
echo "  • Log: tail -f $LOG_FILE"
echo "  • Backup restore: ls $BACKUP_BASE"
