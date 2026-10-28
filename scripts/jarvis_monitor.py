#!/usr/bin/env python3
# ============================================================================
# jarvis_monitor.py
# ============================================================================
# Single-shot wrapper: runs jarvis_local_monitor.ps1 once, then exits.
# Used by the Hermes cron scheduler as a no_agent job (schedule-driven).
# ============================================================================
import subprocess
import sys

PS_SCRIPT = "/c/Users/Naseeh-A/Downloads/hermes-agent-0.22.5/scripts/jarvis_local_monitor.ps1"

def main():
    try:
        result = subprocess.run(
            ["powershell", "-ExecutionPolicy", "Bypass", "-File", PS_SCRIPT],
            capture_output=True,
            text=True,
            timeout=60,
        )
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
        return result.returncode
    except Exception as exc:  # pragma: no cover - defensive
        print(f"Jarvis monitor error: {exc}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
