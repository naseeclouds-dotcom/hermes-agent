
Add-Type -AssemblyName System.Speech

$log_file = "C:\Users\Naseeh-A\AppData\Local\hermes\scripts\luuzr_voice_log.txt"
function Write-Log($text) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $text" | Out-File -FilePath $log_file -Append
}

Write-Log "Starting Luuzr Listener (Fixed Async)..."

try {
    $recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
    $recognizer.SetInputToDefaultAudioDevice()
    
    $choices = New-Object System.Speech.Recognition.Choices
    $choices.Add("Hey Luuzr")
    $choices.Add("Luuzr")

    $gb = New-Object System.Speech.Recognition.GrammarBuilder
    $gb.Append($choices)
    $grammar = New-Object System.Speech.Recognition.Grammar($gb)
    $recognizer.LoadGrammar($grammar)

    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

    $global:isListeningForCommand = $false

    $onSpeechRecognized = {
        param($sender, $e)
        $text = $e.Result.Text
        Write-Log "Heard: $text"
        if ($text -match "Hey Luuzr" -or $text -match "Luuzr") {
            $synth.Speak("Hi bro, I'm here, any help needed?")
            $global:isListeningForCommand = $true
        } 
        elseif ($global:isListeningForCommand) {
            try {
                $body = @{ command = $text } | ConvertTo-Json
                Invoke-RestMethod -Uri "http://localhost:8080" -Method Post -Body $body -ContentType "application/json"
            } catch {
                Write-Log "Error sending to server: $_"
            }
            $global:isListeningForCommand = $false
        }
    }

    Register-ObjectEvent -InputObject $recognizer -EventName SpeechRecognized -Action $onSpeechRecognized
    
    # FIXED: Call RecognizeAsync without the problematic type array
    $recognizer.RecognizeAsync()
    Write-Log "SAPI Recognition started. Listening for 'Hey Luuzr'..."

} catch {
    Write-Log "CRITICAL ERROR: $_"
}

while($true) { Start-Sleep -Seconds 1 }
