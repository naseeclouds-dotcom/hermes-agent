# ============================================================================
# jarvis_final.py
# ============================================================================
# Standalone Jarvis voice-agent monitor — runs the local PowerShell monitor in
# a tight background loop. It speaks new Outlook emails and WhatsApp/Teams
# notifications via Windows SAPI (no app passwords required).
#
# Usage:
#   python jarvis_final.py            # foreground (debug)
#   python jarvis_final.py --daemon   # background (no console)
# ============================================================================
import os
import subprocess
import sys
import time
import signal

# Make the script directory first on sys.path so sibling imports work.
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

PS_SCRIPT = os.path.join(HERE, "jarvis_local_monitor.ps1")
BIN = os.environ.get("COMSPEC", "cmd.exe")

SHUTDOWN = False


def handle_term(signum, frame):
    global SHUTDOWN
    SHUTDOWN = True
    print("Jarvis monitor: shutdown signal received.", flush=True)


def run_monitor():
    """Run the PowerShell monitor once."""
    try:
        subprocess.run(
            ["powershell", "-ExecutionPolicy", "Bypass", "-File", PS_SCRIPT],
            shell=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception as exc:  # pragma: no cover - defensive
        print(f"Jarvis monitor error: {exc}", flush=True)


def daemonize():
    """Classic fork-to-background pattern (Unix). On Windows we fall back to
    detaching via START /B so the process keeps running after the caller exits."""
    if os.name == "nt":
        # Detach: run the monitor under START /B so it outlives this shell.
        subprocess.Popen(
            ["powershell", "-ExecutionPolicy", "Bypass", "-File", PS_SCRIPT],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=subprocess.CREATE_NEW_CONSOLE,
        )
        return
    # POSIX fork
    try:
        pid = os.fork()
        if pid > 0:
            os._exit(0)
    except OSError as exc:
        print(f"fork failed: {exc}", flush=True)
        sys.exit(1)
    # Child continues
    os.setsid()
    try:
        pid = os.fork()
        if pid > 0:
            os._exit(0)
    except OSError as exc:
        print(f"fork failed: {exc}", flush=True)
        sys.exit(1)


def main():
    global SHUTDOWN
    if len(sys.argv) > 1 and sys.argv[1] == "--daemon":
        daemonize()
    else:
        # Foreground: keep running until the user stops us.
        signal.signal(signal.SIGINT, handle_term)
        signal.signal(signal.SIGTERM, handle_term)

    interval = 20  # seconds between runs
    print("Jarvis voice monitor started (interval=%ds)." % interval, flush=True)

    while not SHUTDOWN:
        run_monitor()
        # Wait, but wake on signal
        for _ in range(interval):
            if SHUTDOWN:
                break
            time.sleep(1)

    print("Jarvis monitor stopped.", flush=True)


if __name__ == "__main__":
    main()
