#!/bin/sh
set -eu

OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.3.2}"
OPENCLAW_PACKAGE="${OPENCLAW_PACKAGE:-openclaw@$OPENCLAW_VERSION}"
PACKAGES="${OPENCLAW_GLOBAL_NPM_PACKAGES:-@openai/codex @anthropic-ai/claude-code clawhub @steipete/summarize}"
AUTO_INSTALL="${OPENCLAW_NPM_AUTO_INSTALL:-1}"
SSH_AUTO_KEYGEN="${OPENCLAW_SSH_AUTO_KEYGEN:-1}"
SSH_KEY_PATH="${OPENCLAW_SSH_KEY_PATH:-/home/node/.ssh/id_ed25519}"
SSH_KEY_TYPE="${OPENCLAW_SSH_KEY_TYPE:-ed25519}"
SSH_KEY_COMMENT="${OPENCLAW_SSH_KEY_COMMENT:-openclaw@container}"
PREFIX="${NPM_CONFIG_PREFIX:-/home/node/.npm-global}"
CACHE_DIR="${npm_config_cache:-/home/node/.npm}"
OPENCLAW_DIR="$PREFIX/lib/node_modules/openclaw"
SSH_DIR="$(dirname "$SSH_KEY_PATH")"

export NPM_CONFIG_PREFIX="$PREFIX"
export PATH="$PREFIX/bin:$PATH"
export npm_config_cache="$CACHE_DIR"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ "$SSH_AUTO_KEYGEN" = "1" ] && [ ! -f "$SSH_KEY_PATH" ]; then
  ssh-keygen -q -t "$SSH_KEY_TYPE" -N "" -C "$SSH_KEY_COMMENT" -f "$SSH_KEY_PATH"
  chmod 600 "$SSH_KEY_PATH"
  chmod 644 "$SSH_KEY_PATH.pub"
  echo "Generated SSH key for git pushes: $SSH_KEY_PATH"
  echo "Public key:"
  cat "$SSH_KEY_PATH.pub"
fi

if [ "$AUTO_INSTALL" = "1" ]; then
  mkdir -p "$PREFIX" "$CACHE_DIR"
  need_install=0

  if [ ! -f "$OPENCLAW_DIR/package.json" ]; then
    need_install=1
  fi

  if [ "$need_install" -eq 0 ] && [ -n "$PACKAGES" ]; then
    for pkg in $PACKAGES; do
      if ! npm ls -g --depth=0 "$pkg" >/dev/null 2>&1; then
        need_install=1
        break
      fi
    done
  fi

  if [ "$need_install" -eq 1 ]; then
    npm install -g "$OPENCLAW_PACKAGE" $PACKAGES
  fi
fi

exec "$@"
