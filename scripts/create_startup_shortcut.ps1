# Create a startup shortcut for the Jarvis voice monitor.
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut(
    "C:\Users\Naseeh-A\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Jarvis Voice Monitor.lnk"
)
$shortcut.TargetPath  = "C:\Users\Naseeh-A\Downloads\hermes-agent-0.22.5\start_jarvis.bat"
$shortcut.WorkingDirectory = "C:\Users\Naseeh-A\Downloads\hermes-agent-0.22.5"
$shortcut.Description  = "Jarvis Voice Monitor (auto-start)"
$shortcut.Save()
Write-Host "Startup shortcut created." -ForegroundColor Green
