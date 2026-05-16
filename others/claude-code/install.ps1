#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Code dotfiles installer for Windows
.DESCRIPTION
    Restores Claude Code configuration from a dotfiles backup.
    Backs up existing config before overwriting.
.EXAMPLE
    .\install.ps1
    .\install.ps1 -Force    # Skip confirmation prompts
#>
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

function Write-Step($msg) {
    Write-Host "`n==> $msg" -ForegroundColor Cyan
}

function Write-Info($msg) {
    Write-Host "    $msg" -ForegroundColor Gray
}

function Write-Warn($msg) {
    Write-Host "    WARNING: $msg" -ForegroundColor Yellow
}

# --- Step 1: Backup existing config ---
Write-Step "Checking existing configuration"

if (Test-Path $ClaudeDir) {
    $settingsPath = Join-Path $ClaudeDir "settings.json"
    if ((Test-Path $settingsPath) -and -not $Force) {
        $backupName = "settings.json.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        $backupPath = Join-Path $ClaudeDir $backupName
        Write-Info "Backing up existing settings.json -> $backupName"
        Copy-Item $settingsPath $backupPath
    }
} else {
    Write-Info "Creating ~/.claude/ directory"
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

# --- Step 2: Restore settings.json with path adaptation ---
Write-Step "Restoring settings.json"

$settingsSource = Join-Path $ScriptDir "config\settings.json"
$settingsDest = Join-Path $ClaudeDir "settings.json"

if (Test-Path $settingsSource) {
    $content = Get-Content $settingsSource -Raw

    # Replace hardcoded user paths with current user's path
    # Common patterns: /Users/username/, C:\Users\username\
    $homeUnix = $env:USERPROFILE -replace '\\', '/'
    $patterns = @(
        '/Users/[a-zA-Z0-9._-]+',
        'C:\\Users\\[a-zA-Z0-9._-]+',
        "C:/Users/[a-zA-Z0-9._-]+"
    )
    $adapted = $false
    foreach ($pattern in $patterns) {
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $homeUnix
            Write-Info "Adapted path: $pattern -> $homeUnix"
            $adapted = $true
        }
    }
    if (-not $adapted) {
        Write-Info "No hardcoded user paths found, skipping path adaptation"
    }

    Set-Content -Path $settingsDest -Value $content -NoNewline
    Write-Info "Restored settings.json"
} else {
    Write-Warn "config/settings.json not found, skipping"
}

# --- Step 3: Restore CLAUDE.md ---
Write-Step "Restoring CLAUDE.md"

$claudemdSource = Join-Path $ScriptDir "config\CLAUDE.md"
$claudemdDest = Join-Path $ClaudeDir "CLAUDE.md"

if (Test-Path $claudemdSource) {
    Copy-Item $claudemdSource $claudemdDest -Force
    Write-Info "Restored CLAUDE.md"
}

# --- Step 4: Restore blocklist.json ---
Write-Step "Restoring plugin blocklist"

$blocklistSource = Join-Path $ScriptDir "config\blocklist.json"
$pluginsDir = Join-Path $ClaudeDir "plugins"

if (Test-Path $blocklistSource) {
    if (-not (Test-Path $pluginsDir)) {
        New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
    }
    Copy-Item $blocklistSource (Join-Path $pluginsDir "blocklist.json") -Force
    Write-Info "Restored plugins/blocklist.json"
}

# --- Step 5: Restore memory ---
Write-Step "Restoring memory system"

$memorySource = Join-Path $ScriptDir "memory"
$memoryDest = Join-Path $ClaudeDir "memory"

if (Test-Path $memorySource) {
    if (-not (Test-Path $memoryDest)) {
        New-Item -ItemType Directory -Path $memoryDest -Force | Out-Null
    }
    $memFiles = Get-ChildItem $memorySource -File
    foreach ($file in $memFiles) {
        Copy-Item $file.FullName (Join-Path $memoryDest $file.Name) -Force
    }
    Write-Info "Restored $($memFiles.Count) memory file(s)"
}

# --- Step 6: Restore skills ---
Write-Step "Restoring skills"

$skillsSource = Join-Path $ScriptDir "skills"
$skillsDest = Join-Path $ClaudeDir "skills"

if (Test-Path $skillsSource) {
    if (-not (Test-Path $skillsDest)) {
        New-Item -ItemType Directory -Path $skillsDest -Force | Out-Null
    }
    $skillDirs = Get-ChildItem $skillsSource -Directory
    foreach ($dir in $skillDirs) {
        $dest = Join-Path $skillsDest $dir.Name
        if (Test-Path $dest) {
            # Remove existing to ensure clean copy
            Remove-Item $dest -Recurse -Force
        }
        Copy-Item $dir.FullName $dest -Recurse -Force
    }
    Write-Info "Restored $($skillDirs.Count) skill(s)"
}

# --- Summary ---
Write-Step "Restore complete!"

$pluginCount = 0
if (Test-Path (Join-Path $ClaudeDir "settings.json")) {
    try {
        $settingsContent = Get-Content (Join-Path $ClaudeDir "settings.json") -Raw | ConvertFrom-Json
        $plugins = $settingsContent.enabledPlugins
        if ($plugins) {
            $pluginCount = ($plugins.PSObject.Properties | Where-Object { $_.Value -eq $true }).Count
        }
    } catch {
        $pluginCount = 0
    }
}

$memCount = (Get-ChildItem (Join-Path $ClaudeDir "memory") -File -ErrorAction SilentlyContinue).Count
$skillCount = (Get-ChildItem (Join-Path $ClaudeDir "skills") -Directory -ErrorAction SilentlyContinue).Count

Write-Host ""
Write-Host "  Restored:" -ForegroundColor Green
Write-Host "    Plugins enabled: $pluginCount" -ForegroundColor Green
Write-Host "    Memory files:    $memCount" -ForegroundColor Green
Write-Host "    Skills:          $skillCount" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "    1. Run 'ccswitch' to configure your API key and model" -ForegroundColor Yellow
Write-Host "    2. Launch 'claude' to start Claude Code" -ForegroundColor Yellow
Write-Host "    3. Plugins will be auto-installed on first launch" -ForegroundColor Yellow
Write-Host ""
