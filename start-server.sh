#!/usr/bin/env bash
#
# .devcontainer/start-server.sh
#
# Runs every time the Codespace starts/resumes (wired up via
# "postStartCommand" in devcontainer.json) — unlike setup.sh, which only
# runs once on creation.
#
# Starts PHP's built-in webserver in the background, pointed at Drupal's
# docroot, so port 8080 (forwarded in devcontainer.json) always has
# something listening on it.

set -euo pipefail

DOCROOT="web"
PORT="8080"

# If a server is already bound to the port (e.g. this is a reattach, not a
# fresh boot), don't start a second one.
if ! (echo > /dev/tcp/127.0.0.1/"$PORT") 2>/dev/null; then
  echo "── Starting PHP built-in server on port $PORT ──────────────────────"
  # nohup + & + disown: keep the server alive after this script (and its
  # parent shell) exits, since postStartCommand doesn't stay attached.
  nohup php -S 0.0.0.0:"$PORT" -t "$DOCROOT" > /tmp/php-server.log 2>&1 &
  disown
else
  echo "── Server already running on port $PORT ────────────────────────────"
fi
