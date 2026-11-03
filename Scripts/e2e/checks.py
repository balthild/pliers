#!/usr/bin/env python3
"""In-container checks for the Layer C end-to-end run.

Drives a real Pliers over HTTP and inspects the host state it changes. Runs inside the
container, where the server listens on 127.0.0.1, and prints a result table (exiting non-zero
on any failure).

Sessions are written straight into the state database rather than obtained through the D-Bus
token flow: that flow cannot resolve the caller id inside the container, so it is out of scope
here. The rows written match what the session driver stores, so the HTTP stack is still real.
"""

import http.cookiejar
import json
import socket
import sqlite3
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

BASE = "http://127.0.0.1:7577"
DB = "/var/lib/pliers/dashboard/db.sqlite"


class NoRedirect(urllib.request.HTTPRedirectHandler):
  # keep 303 visible; the cookie processor still handles Set-Cookie
  def redirect_request(self, *_) -> None:
    return None


# the host's proxy settings leak into `podman exec`; the server is local, so bypass them
_opener = urllib.request.build_opener(
  urllib.request.ProxyHandler({}),
  urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()),
  NoRedirect(),
)

results: list[tuple[str, str, object, object, bool]] = []


def sql(statement: str, params: tuple = ()) -> None:
  con = sqlite3.connect(DB)
  try:
    con.execute("PRAGMA busy_timeout = 5000")
    con.execute(statement, params)
    con.commit()
  finally:
    con.close()


def seed_user(username: str, privileges: list[str] = []) -> str:
  uid = str(uuid.uuid4()).upper()  # Fluent stores UUIDs upper-cased
  sql(
    "insert into user (id, username, privileges) values (?, ?, ?)",
    (uid, username, json.dumps(privileges)),
  )
  return uid


def seed_session(uid: str) -> str:
  key = str(uuid.uuid4())
  sql(
    "insert into _fluent_sessions (id, key, data) values (?, ?, ?)",
    (str(uuid.uuid4()), key, json.dumps({"_UserSession": uid})),
  )
  return key


def request(
  method: str, path: str, key: str | None = None, data: dict | None = None, *, origin: bool = True
) -> int:
  body = urllib.parse.urlencode(data).encode() if data is not None else None
  req = urllib.request.Request(BASE + path, data=body, method=method)
  if origin:
    req.add_header("Origin", BASE)
  if key:
    req.add_header("Cookie", f"pliers_session={key}")
  try:
    with _opener.open(req) as resp:
      return resp.status
  except urllib.error.HTTPError as exc:
    return exc.code


def check(tid: str, scenario: str, expected: object, actual: object) -> None:
  results.append((tid, scenario, expected, actual, expected == actual))


def crontab(user: str) -> str:
  return subprocess.run(["crontab", "-l", "-u", user], capture_output=True, text=True).stdout


def alice_cron_id() -> str:
  con = sqlite3.connect(DB)
  try:
    row = con.execute(
      "select c.id from cron c join user u on c.user_id = u.id where u.username = 'alice'"
    ).fetchone()
    return row[0] if row else ""
  finally:
    con.close()


def wait_ready(timeout: float = 20.0) -> bool:
  # systemd reports the unit active before the socket is bound
  deadline = time.monotonic() + timeout
  while time.monotonic() < deadline:
    try:
      with socket.create_connection(("127.0.0.1", 7577), 1):
        return True
    except OSError:
      time.sleep(0.5)
  return False


def main() -> int:
  if not wait_ready():
    print("server did not become ready")
    return 1

  check("T1", "unauth GET /cron redirects to login", 303, request("GET", "/cron"))
  check("T2", "cross-site POST rejected", 403, request("POST", "/logout", origin=False))

  alice = seed_session(seed_user("alice"))
  check("T3", "alice GET /cron", 200, request("GET", "/cron", alice))
  check("T4", "alice forbidden from /user", 403, request("GET", "/user", alice))
  check(
    "T5",
    "alice creates a cron",
    303,
    request("POST", "/cron/create", alice, {"expr": "*/5 * * * *", "command": "/bin/true"}),
  )
  check("T6", "her crontab is updated", True, "/bin/true" in crontab("alice"))

  admin = seed_session(seed_user("root"))
  cid = alice_cron_id()
  check(
    "T7",
    "admin edits another user's cron",
    303,
    request(
      "POST",
      f"/cron/{cid}/update",
      admin,
      {"expr": "*/10 * * * *", "command": "/bin/echo owner-context"},
    ),
  )
  check("T8", "the owner's crontab is rewritten", True, "owner-context" in crontab("alice"))
  check("T9", "the admin's crontab is untouched", False, "owner-context" in crontab("root"))

  return report()


def report() -> int:
  failed = 0
  for tid, scenario, expected, actual, ok in results:
    failed += not ok
    verdict = "PASS" if ok else "FAIL"
    print(f"{tid:<4} {verdict:<5} {scenario:<40} exp={expected!s:<7} act={actual!s}")
  print(f"\n{len(results) - failed} passed, {failed} failed")
  return 1 if failed else 0


if __name__ == "__main__":
  sys.exit(main())
