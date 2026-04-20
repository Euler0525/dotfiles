Set-Alias -Name lg -Value lazygit


$logDir = "$env:USERPROFILE\.log"
New-Item -Path $logDir -ItemType Directory -Force | Out-Null

Get-ChildItem "$logDir\*.log" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Force

$logFile = Join-Path $logDir "pwsh_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile | Out-Null

Register-EngineEvent PowerShell.Exiting -Action { Stop-Transcript } | Out-Null