#!/bin/sh
set -eu

OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.3.2}"
OPENCLAW_PACKAGE="${OPENCLAW_PACKAGE:-openclaw@$OPENCLAW_VERSION}"
PACKAGES="${OPENCLAW_GLOBAL_NPM_PACKAGES:-@openai/codex @anthropic-ai/claude-code clawhub @steipete/summarize}"
AUTO_INSTALL="${OPENCLAW_NPM_AUTO_INSTALL:-1}"
PREFIX="${NPM_CONFIG_PREFIX:-/home/node/.npm-global}"
CACHE_DIR="${npm_config_cache:-/home/node/.npm}"
OPENCLAW_DIR="$PREFIX/lib/node_modules/openclaw"

export NPM_CONFIG_PREFIX="$PREFIX"
export PATH="$PREFIX/bin:$PATH"
export npm_config_cache="$CACHE_DIR"

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
