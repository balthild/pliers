#!/usr/bin/env python3
"""Layer C end-to-end test driver.

Runs a real Pliers inside a throwaway systemd container and exercises the operations that
change host state. Everything happens in the container, which is destroyed on exit, so the
host is never touched. Results are written to .build/e2e.
"""

from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / ".build" / "e2e"
NAME = "pliers-e2e"
IMAGE = "localhost/pliers-e2e:latest"
PODMAN = ["sudo", "-n", "podman"]


def log(message: str) -> None:
  print(f"\n== {message} ==", flush=True)


def podman(*args: str, **kwargs) -> subprocess.CompletedProcess:
  return subprocess.run([*PODMAN, *args], **kwargs)


def cleanup() -> None:
  subprocess.run([*PODMAN, "rm", "-f", NAME], capture_output=True)


def wait_for(unit: str, timeout: int = 30) -> bool:
  for _ in range(timeout):
    state = podman(
      "exec", NAME, "systemctl", "is-active", unit, capture_output=True, text=True
    ).stdout.strip()
    if state == "active":
      return True
    time.sleep(1)
  return False


def main() -> int:
  OUT.mkdir(parents=True, exist_ok=True)
  try:
    log("building package")
    subprocess.run(["make", "package"], cwd=ROOT, check=True)

    log("building image")
    podman("build", "-t", IMAGE, "-f", ROOT / "Scripts/e2e/Containerfile", ROOT, check=True)

    log("starting container")
    cleanup()
    podman("run", "-d", "--systemd=always", "--name", NAME, IMAGE, check=True, capture_output=True)
    for _ in range(30):
      state = podman(
        "exec", NAME, "systemctl", "is-system-running", capture_output=True, text=True
      ).stdout.strip()
      if state in ("running", "degraded"):
        break
      time.sleep(1)

    log("provisioning")
    for user in ("alice", "bob"):
      podman("exec", NAME, "useradd", "-m", "-s", "/bin/bash", user, check=True)

    # install the package exactly as a deployment would; this pulls in the bundled Swift
    # runtime, the loader configuration, the unit, and the config file
    deb = next((ROOT / ".build/pkg").glob("*.deb"))
    podman("cp", deb, f"{NAME}:/root/pliers.deb", check=True)
    podman("exec", NAME, "apt-get", "install", "-y", "/root/pliers.deb", check=True)

    log("starting pliers")
    podman("exec", NAME, "systemctl", "enable", "--now", "pliers", capture_output=True)
    if not wait_for("pliers"):
      podman("exec", NAME, "journalctl", "-u", "pliers", "--no-pager")
      raise SystemExit("pliers failed to start")

    log("running checks")
    podman("cp", ROOT / "Scripts/e2e/checks.py", f"{NAME}:/root/checks.py", check=True)
    proc = podman("exec", NAME, "python3", "/root/checks.py", capture_output=True, text=True)
    sys.stdout.write(proc.stdout)
    sys.stderr.write(proc.stderr)
    (OUT / "results.txt").write_text(proc.stdout)
    (OUT / "results.err").write_text(proc.stderr)

    log("artifacts")
    journal = podman(
      "exec", NAME, "journalctl", "-u", "pliers", "--no-pager", capture_output=True, text=True
    ).stdout
    (OUT / "journal.txt").write_text(journal)
    print(f"wrote {OUT}")

    return proc.returncode
  finally:
    cleanup()


if __name__ == "__main__":
  sys.exit(main())
