# Create scheduled task using the admin password read from Cred.txt
$CredFile = "C:\Users\Naseeh-A\AppData\Local\hermes\cache\scratch\Cred.txt"
$p = Get-Content $CredFile -Raw
$p = $p.Trim()

Write-Host "Password received from file (length=$($p.Length))" -ForegroundColor Gray

$taskName = "Jarvis Voice Monitor"
$pythonExe = "C:\Users\Naseeh-A\Downloads\hermes-agent-0.22.5\.venv\Scripts\python.exe"
$workdir = "C:\Users\Naseeh-A\Downloads\hermes-agent-0.22.5"
$runCommand = "cmd /c cd /d `"$workdir`" && `"$pythonExe`" jarvis_final.py"
$cmd = "schtasks /Create /TN `"$taskName`" /RU Administrator /RP `"$p`" /TR `"$runCommand`" /SC ONLOGON /F"
Write-Host "Executing: $cmd" -ForegroundColor Gray

Invoke-Expression $cmd | Out-String | Write-Host -ForegroundColor Gray
exit $LASTEXITCODE
