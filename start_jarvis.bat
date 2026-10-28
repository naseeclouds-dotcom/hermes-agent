@echo off
rem ============================================================================
rem start_jarvis.bat
rem ============================================================================
rem Auto-start entry for the Jarvis voice-agent monitor.
rem Runs the monitor in a 20s loop (foreground) from the source checkout.
rem ============================================================================

setlocal
cd /d "C:\Users\Naseeh-A\Downloads\hermes-agent-0.22.5"
"C:\Users\Naseeh-A\Downloads\hermes-agent-0.22.5\.venv\Scripts\python.exe" jarvis_final.py
