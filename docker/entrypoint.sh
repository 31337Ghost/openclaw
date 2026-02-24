#!/usr/bin/env sh
set -eu

RUNTIME_DIR="/home/node/.npm-global"
PACKAGE_NAME="openclaw"
PACKAGE_VERSION="latest"
OPENCLAW_BIN="${RUNTIME_DIR}/bin/openclaw"

mkdir -p "${RUNTIME_DIR}"

# Bootstrap only once: install OpenClaw if runtime binary is missing.
if [ ! -x "${OPENCLAW_BIN}" ]; then
  npm install --global --no-audit --no-fund --prefix "${RUNTIME_DIR}" "${PACKAGE_NAME}@${PACKAGE_VERSION}"
fi

exec "${OPENCLAW_BIN}" "$@"
