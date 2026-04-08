
#region conda initialize
# !! Contents within this block are managed by 'conda init' !!
If (Test-Path "C:\Software\Anaconda\Scripts\conda.exe") {
    (& "C:\Software\Anaconda\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | ?{$_} | Invoke-Expression
}
#endregion

