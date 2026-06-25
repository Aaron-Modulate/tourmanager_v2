#!/bin/sh
# Load local environment variables from .envrc (without requiring direnv to be
# hooked into the shell). Strips 'export ' prefixes and skips comments/blanks.
set -a
# shellcheck disable=SC1091
. "$(dirname "$0")/../.envrc"
set +a

exec mix phx.server
