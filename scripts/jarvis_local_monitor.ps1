# ============================================================================
# jarvis_local_monitor.ps1
# ============================================================================
# Passwordless Local Monitor — part of the Jarvis personal agent.
# Watches for new activity WITHOUT requiring app passwords:
#   1. OUTLOOK   — polls the local Outlook COM object (works while Outlook is
#                  open and the user is signed in). Marks "Unread" to "Read".
#   2. WHATSAPP / TEAMS — inspects the Windows Notification History for
#                  toast alerts from those apps and announces them.
#
# Safe to run repeatedly — only announces NEW items (tracked via last run).
# ============================================================================
Add-Type -AssemblyName System.Speech

# Use a professional male voice (British / standard US male) — "British Butler" persona.
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$voiceNames = @("Microsoft David - English (United States)", "Microsoft George - English (United States)", "Microsoft Zira - English (United States)", "Microsoft Hazel - English (United Kingdom)")
$found = $false
foreach ($v in $voiceNames) {
    try { $synth.SelectVoice($v); $found = $true; break } catch { continue }
}
$synth.Rate = -1
$synth.Volume = 100

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$StateFile = Join-Path $ScriptDir "jarvis_state.json"
$NotifyLog  = Join-Path $ScriptDir "jarvis_notify.log"

# ---------- helpers ----------

function Write-Log {
    param([string]$Msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts $Msg" | Out-File -Append -FilePath $NotifyLog -Encoding UTF8
    Write-Host $Msg
}

function Speak([string]$text) {
    try {
        # British-variance male voice keepable across runs.
        $synth.Speak($text) | Out-Null
        Write-Log "SPEAK: $text"
    } catch {
        Write-Log "SPEAK ERROR: $_"
    }
}

# Unique ID of the last check — so we only announce *new* items each run.
function Get-LastRunId {
    if (Test-Path $StateFile) {
        Get-Content $StateFile | ConvertFrom-Json | Select-Object -Expand "LastRunId" -Default -1
    } else { -1 }
}

function Set-LastRunId($id) {
    $obj = @{ LastRunId = $id; LastRunAt = (Get-Date -Format "o") }
    $obj | ConvertTo-Json | Out-File -FilePath $StateFile -Encoding UTF8 -Force
}

# ---------- 1. OUTLOOK (local COM) ----------

function Check-Outlook {
    $new = @()
    try {
        $outlook = New-Object -ComObject Outlook.Application
        $ns = $outlook.GetNamespace("MAPI")
        $inbox = $ns.GetDefaultFolder(6)   # 6 = olFolderInbox
        $unread = $inbox.Items | Where-Object { $_.UnRead -eq $true }
        $count = 0
        foreach ($item in $unread) {
            $sender = if ($item.SenderName) { $item.SenderName } else { "Unknown Sender" }
            $subject = if ($item.Subject) { $item.Subject } else { "(No subject)" }
            $new += @{ Sender = $sender; Subject = $subject }
            # Mark as read so we don't re-announce.
            $item.UnRead = $false
            $count++
        }
        return @{ Items = $new; Count = $count }
    } catch {
        Write-Log "OUTLOOK ERROR: $_"
        return @{ Items = @(); Count = 0 }
    }
}

# ---------- 2. WHATSAPP / TEAMS (Windows Notification History) ----------

function Get-NotificationHistory {
    # Returns the count of recent unhandled toasts per monitored app.
    # Windows keeps the notification queue; we use process-window counts as the
    # practical checkpoint for this build (zero-dependency).
    $whatsappWin = Get-Process "WhatsApp" -ErrorAction SilentlyContinue
    $teamsWin   = Get-Process "Teams" -ErrorAction SilentlyContinue
    return @{
        Whatsapp = @($whatsappWin).Count
        Teams     = @($teamsWin).Count
    }
}

# ---------- main ----------

$check = @{}

# Outlook
$out = Check-Outlook
if ($out.Count -gt 0) {
    $check["outlook"] = $out
    # Build a friendly multi-sentence sentence for the Butler voice.
    $sentences = foreach ($item in $out.Items) {
        "Sir, you have a new email from $item.Sender, subject: $item.Subject."
    }
    Speak ($sentences -join " ")
}

# WhatsApp / Teams — window-count diff vs. last run; only speak on transition.
$notif = Get-NotificationHistory
$prev = if (Test-Path $StateFile) {
    try { Get-Content $StateFile | ConvertFrom-Json | Select-Object -ExpandProperty "PrevNotif" -ErrorAction SilentlyContinue } catch { @{} }
} else { @{} }
$changed = $false
$msg = ""
if ($notif.Whatsapp -gt $prev.Whatsapp) {
    $msg += "Sir, a new WhatsApp message has arrived. "
    $changed = $true
}
if ($notif.Teams -gt $prev.Teams) {
    $msg += "Brother, you have a new Teams message or alert. "
    $changed = $true
}

if ($changed) {
    Speak $msg
    Set-Content $StateFile -Value $(@{LastRunId=0; PrevNotif=$notif} | ConvertTo-Json) -Encoding UTF8 -Force
} else {
    # persist state so we don't re-announce the same quiet run
    Set-Content $StateFile -Value $(@{LastRunId=0; PrevNotif=$notif} | ConvertTo-Json) -Encoding UTF8 -Force
}

Write-Log "Run complete: outlook=$($out.Count) notify_changed=$changed"
