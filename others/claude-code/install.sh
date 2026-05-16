#!/usr/bin/env bash
#
# Claude Code dotfiles installer for Linux/macOS
# Restores Claude Code configuration from a dotfiles backup.
# Backs up existing config before overwriting.
#
# Usage: ./install.sh [--force]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
FORCE=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

step()   { echo -e "\n${CYAN}==> $1${NC}"; }
info()   { echo -e "    ${GRAY}$1${NC}"; }
warn()   { echo -e "    ${YELLOW}WARNING: $1${NC}"; }
success(){ echo -e "    ${GREEN}$1${NC}"; }

# Parse args
for arg in "$@"; do
    case $arg in
        --force|-f) FORCE=true ;;
    esac
done

# --- Step 1: Backup existing config ---
step "Checking existing configuration"

if [[ -d "$CLAUDE_DIR" ]]; then
    settings_path="$CLAUDE_DIR/settings.json"
    if [[ -f "$settings_path" ]] && [[ "$FORCE" != "true" ]]; then
        backup_name="settings.json.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backing up existing settings.json -> $backup_name"
        cp "$settings_path" "$CLAUDE_DIR/$backup_name"
    fi
else
    info "Creating ~/.claude/ directory"
    mkdir -p "$CLAUDE_DIR"
fi

# --- Step 2: Restore settings.json with path adaptation ---
step "Restoring settings.json"

settings_source="$SCRIPT_DIR/config/settings.json"
settings_dest="$CLAUDE_DIR/settings.json"

if [[ -f "$settings_source" ]]; then
    content=$(cat "$settings_source")

    # Replace hardcoded user paths with current user's $HOME
    # Common patterns: /Users/username/, C:\Users\username\
    if echo "$content" | grep -qE '/Users/[a-zA-Z0-9._-]+|C:\\\\Users\\\\[a-zA-Z0-9._-]+'; then
        # Normalize HOME for replacement
        home_path="$HOME"
        content=$(echo "$content" | sed -E \
            -e "s|/Users/[a-zA-Z0-9._-]+|${home_path}|g" \
            -e "s|C:\\\\Users\\\\[a-zA-Z0-9._-]+|${home_path}|g" \
            -e "s|C:/Users/[a-zA-Z0-9._-]+|${home_path}|g")
        info "Adapted user paths -> $home_path"
    fi

    echo "$content" > "$settings_dest"
    success "Restored settings.json"
else
    warn "config/settings.json not found, skipping"
fi

# --- Step 3: Restore CLAUDE.md ---
step "Restoring CLAUDE.md"

claudemd_source="$SCRIPT_DIR/config/CLAUDE.md"
claudemd_dest="$CLAUDE_DIR/CLAUDE.md"

if [[ -f "$claudemd_source" ]]; then
    cp "$claudemd_source" "$claudemd_dest"
    success "Restored CLAUDE.md"
fi

# --- Step 4: Restore blocklist.json ---
step "Restoring plugin blocklist"

blocklist_source="$SCRIPT_DIR/config/blocklist.json"
plugins_dir="$CLAUDE_DIR/plugins"

if [[ -f "$blocklist_source" ]]; then
    mkdir -p "$plugins_dir"
    cp "$blocklist_source" "$plugins_dir/blocklist.json"
    success "Restored plugins/blocklist.json"
fi

# --- Step 5: Restore memory ---
step "Restoring memory system"

memory_source="$SCRIPT_DIR/memory"
memory_dest="$CLAUDE_DIR/memory"

if [[ -d "$memory_source" ]]; then
    mkdir -p "$memory_dest"
    mem_count=0
    for file in "$memory_source"/*; do
        [[ -f "$file" ]] || continue
        cp "$file" "$memory_dest/$(basename "$file")"
        ((mem_count++))
    done
    success "Restored $mem_count memory file(s)"
fi

# --- Step 6: Restore skills ---
step "Restoring skills"

skills_source="$SCRIPT_DIR/skills"
skills_dest="$CLAUDE_DIR/skills"

if [[ -d "$skills_source" ]]; then
    mkdir -p "$skills_dest"
    skill_count=0
    for dir in "$skills_source"/*/; do
        [[ -d "$dir" ]] || continue
        name=$(basename "$dir")
        dest="$skills_dest/$name"
        rm -rf "$dest"
        cp -r "$dir" "$dest"
        ((skill_count++))
    done
    success "Restored $skill_count skill(s)"
fi

# --- Summary ---
step "Restore complete!"

# Count plugins from settings.json
plugin_count=0
if [[ -f "$settings_dest" ]]; then
    plugin_count=$(python3 -c "
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    plugins = data.get('enabledPlugins', {})
    print(sum(1 for v in plugins.values() if v is True))
except: print(0)
" "$settings_dest" 2>/dev/null || echo 0)
fi
mem_count=$(find "$memory_dest" -type f 2>/dev/null | wc -l | tr -d ' ')
skill_count=$(find "$skills_dest" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo -e "  ${GREEN}Restored:${NC}"
echo -e "    Plugins enabled: $plugin_count"
echo -e "    Memory files:    $mem_count"
echo -e "    Skills:          $skill_count"
echo ""
echo -e "  ${YELLOW}Next steps:${NC}"
echo -e "    1. Run 'ccswitch' to configure your API key and model"
echo -e "    2. Launch 'claude' to start Claude Code"
echo -e "    3. Plugins will be auto-installed on first launch"
echo ""
