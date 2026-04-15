#!/usr/bin/env bash
# ==============================================================================
# Backwards-compatible wrapper — delegates to modular setup
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
exec "${SCRIPT_DIR}/manjaro-setup/setup.sh" "$@"
