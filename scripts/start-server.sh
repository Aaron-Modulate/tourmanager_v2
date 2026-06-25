#!/bin/sh
# Kill any existing Phoenix/BEAM process on port 4000, then restart.
# Load local environment variables from .envrc (without requiring direnv to be
# hooked into the shell). Strips 'export ' prefixes and skips comments/blanks.

existing_pid=$(lsof -ti:4000 2>/dev/null)
if [ -n "$existing_pid" ]; then
  echo "Stopping existing server (PID $existing_pid) on port 4000..."
  kill "$existing_pid" 2>/dev/null
  sleep 1
  # Force-kill if it didn't stop gracefully
  if kill -0 "$existing_pid" 2>/dev/null; then
    kill -9 "$existing_pid" 2>/dev/null
  fi
fi

set -a
# shellcheck disable=SC1091
. "$(dirname "$0")/../.envrc"
set +a

exec mix phx.server
