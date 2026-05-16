# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Cross-platform dotfiles repository for Windows and Linux (Manjaro/Arch). Contains shell configs, editor settings, and Claude Code configuration backups. Clone with `git clone --recurse-submodules`.

## Repository structure

```
Linux/          # Manjaro/Arch dotfiles (.gitconfig, zsh aliases, setup script)
Windows/        # Windows dotfiles (PowerShell, VSCode, conda, ideavim, Claude Code)
others/         # Cross-platform configs (Claude Code backup, RSS subscriptions)
submodules/     # Git submodules (nvim-config)
```

## Key conventions

- **Line endings**: LF for all text files, CRLF for `.bat`/`.cmd` only (see `.gitattributes`).
- **No secrets**: Never commit `.env`, `*.secret`, or API keys. The `.gitignore` already covers these.
- **Vim keybindings everywhere**: The user uses Vim-style navigation in VSCode, IdeaVim (JetBrains), and Neovim. `<Space>` maps to `:`, `jk` escapes insert mode, `Q`/`W` are write/quit shortcuts. Both VSCode and IdeaVim configs are kept in sync with these mappings.
- **Python style**: Strict PEP 8, English-only comments/docstrings, type hints, f-strings preferred. See `others/claude-code/memory/user_python_style.md`.

## Platform-specific details

### Linux (`Linux/`)
- `manjaro-setup.sh` — Full system bootstrap for fresh Manjaro/Arch installs. Idempotent, uses `zshrc_block` helper to append to `~/.zshrc`. Sets up yay, zsh, x-cmd, nvm/node, Rust, Docker, fonts (Maple Mono), UFW, Tailscale, and symlinks dotfiles.
- `zshrc_alias.sh` — Shell aliases: `ls`→eza, `vim`→nvim, `git`→bit, `ll`→joshuto, `lg`→lazygit, `ld`→lazydocker. Zellij session shortcuts (`n`, `sl`, `at`, `ks`, `ds`, `ka`).

### Windows (`Windows/`)
- `PowerShell/` — Profile scripts: auto-saves session transcripts to `~/.log/` (30-day retention), conda init.
- `VSCode/settings.json` — Full VS Code config with Vim extension, language-specific formatters (Python: autopep8, Verilog: veriloghdl, C++: clang-format LLVM style, LaTeX: xelatex/biber recipes). Terminal profile includes a "Tcl Shell" via `vivado.bat -mode tcl`.
- `Users/.condarc` — Anaconda config using Tsinghua mirrors.
- `Users/` — Also contains `.ideavimrc` and Claude Code `settings.json`.

### Claude Code backup (`others/claude-code/`)
- `install.ps1` / `install.sh` — Restore scripts that back up existing config, then copy `settings.json`, `CLAUDE.md`, `blocklist.json`, memory files, and skills into `~/.claude/`. The installers auto-adapt hardcoded user paths to the current machine's `$HOME`.
- `config/settings.json` — Enabled plugins: claude-hud, code-simplifier, compound-engineering, pua, ralph-loop, superpowers. Permissions pre-allow common dev commands, require confirmation for `git commit`/`git push`, and deny `rm -rf`/`sudo`.

## What NOT to do

- Don't modify `submodules/nvim-config` directly — it's tracked in a separate repo.
- Don't commit `.claude/` directory contents (gitignored) — the canonical backup is in `others/claude-code/`.
- Don't add machine-specific absolute paths; use `$HOME` or `%USERPROFILE%` with the path-adaptation pattern from the install scripts.
