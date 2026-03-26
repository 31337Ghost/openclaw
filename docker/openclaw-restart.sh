#!/bin/sh
set -eu

MODE="container"
DELAY_SECONDS="1"

usage() {
  cat <<'EOF'
Usage: openclaw-restart [--gateway] [--help]

Without flags:
  Restart the whole container by sending SIGTERM to the OpenClaw launcher.

With --gateway:
  Restart only the OpenClaw gateway process by sending SIGUSR1 to openclaw-gateway.
EOF
}

if [ "${1:-}" = "--gateway" ]; then
  MODE="gateway"
  shift
elif [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 0 ]; then
  usage >&2
  exit 2
fi

if [ "$MODE" = "gateway" ]; then
  TARGET_PID="$(pgrep -f -o '(^|[[:space:]/])openclaw-gateway([[:space:]]|$)' || true)"
  SIGNAL="USR1"
  DESCRIPTION="gateway"
else
  TARGET_PID="$(pgrep -x -o openclaw || true)"
  SIGNAL="TERM"
  DESCRIPTION="container"
fi

if ! kill -0 "$TARGET_PID" 2>/dev/null; then
  echo "OpenClaw $DESCRIPTION target is not running." >&2
  exit 1
fi

(
  sleep "$DELAY_SECONDS"
  kill "-$SIGNAL" "$TARGET_PID"
) >/dev/null 2>&1 &

if [ "$MODE" = "gateway" ]; then
  echo "OpenClaw gateway restart requested for PID $TARGET_PID via SIG$SIGNAL."
else
  echo "OpenClaw container restart requested via launcher PID $TARGET_PID; container will restart shortly."
fi
