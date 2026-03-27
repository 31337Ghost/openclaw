#!/usr/bin/env bash
set -euo pipefail

LABEL="local.android.mcp"
HOST="127.0.0.1"
PORT="8000"
PLIST_PATH="${HOME}/Library/LaunchAgents/${LABEL}.plist"
HTTP_URL="http://${HOST}:${PORT}"

log() {
  printf '[android-mcp] %s\n' "$*"
}

warn() {
  printf '[android-mcp] warning: %s\n' "$*" >&2
}

die() {
  printf '[android-mcp] error: %s\n' "$*" >&2
  exit 1
}

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    die "this installer supports macOS only"
  fi
}

current_uid() {
  id -u
}

launch_domain() {
  printf 'gui/%s' "$(current_uid)"
}

launch_service_target() {
  printf '%s/%s' "$(launch_domain)" "${LABEL}"
}

ensure_launchagents_dir() {
  mkdir -p "${HOME}/Library/LaunchAgents"
}

ensure_uv() {
  if command -v uv >/dev/null 2>&1; then
    log "uv already available: $(command -v uv)"
    return
  fi

  log "uv not found; installing via official installer"
  if command -v curl >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  else
    die "curl is required to install uv automatically"
  fi

  export PATH="${HOME}/.local/bin:${PATH}"

  if ! command -v uv >/dev/null 2>&1; then
    die "uv was installed but is still not available in PATH; expected it under ${HOME}/.local/bin"
  fi

  log "uv installed successfully: $(command -v uv)"
}

ensure_tool_installed() {
  if uv tool list | grep -q '^uiautomator2-mcp-server[[:space:]]'; then
    log "uiautomator2-mcp-server is already installed"
    return
  fi

  log "installing uiautomator2-mcp-server via uv tool install"
  uv tool install uiautomator2-mcp-server >/dev/null 2>&1

  if ! uv tool list | grep -q '^uiautomator2-mcp-server[[:space:]]'; then
    die "uiautomator2-mcp-server was not found in uv tool list after installation attempt"
  fi

  log "uiautomator2-mcp-server is installed"
}

resolve_binary() {
  local binary_path=""

  if binary_path="$(which uiautomator2-mcp-server 2>/dev/null)"; then
    :
  elif [[ -x "${HOME}/.local/bin/uiautomator2-mcp-server" ]]; then
    binary_path="${HOME}/.local/bin/uiautomator2-mcp-server"
  fi

  if [[ -z "${binary_path}" ]]; then
    die "unable to resolve uiautomator2-mcp-server via which; ensure uv tool bin directory is on PATH"
  fi

  printf '%s\n' "${binary_path}"
}

warn_if_adb_missing() {
  if ! command -v adb >/dev/null 2>&1; then
    warn "adb not found in PATH; service can still be installed, but Android device discovery may not work until adb is installed"
  fi
}

plist_contents() {
  local binary_path="$1"
  cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${binary_path}</string>
    <string>http</string>
    <string>--host</string>
    <string>${HOST}</string>
    <string>--port</string>
    <string>${PORT}</string>
    <string>--no-token</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>${HOME}</string>
    <key>PATH</key>
    <string>${HOME}/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    <key>USER</key>
    <string>${USER:-$(id -un)}</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>WorkingDirectory</key>
  <string>${HOME}</string>
</dict>
</plist>
EOF
}

write_plist() {
  local binary_path="$1"

  ensure_launchagents_dir
  plist_contents "${binary_path}" > "${PLIST_PATH}"
  plutil -lint "${PLIST_PATH}" >/dev/null
  log "launch agent plist written: ${PLIST_PATH}"
}

bootout_agent() {
  if launchctl print "$(launch_service_target)" >/dev/null 2>&1; then
    log "unloading existing launch agent"
    launchctl bootout "$(launch_domain)" "${PLIST_PATH}" >/dev/null 2>&1 || launchctl bootout "$(launch_service_target)" >/dev/null 2>&1 || true
    return
  fi

  if launchctl list | grep -q "${LABEL}"; then
    log "launch agent appears loaded; performing compatible unload"
    launchctl bootout "$(launch_domain)" "${PLIST_PATH}" >/dev/null 2>&1 || launchctl unload "${PLIST_PATH}" >/dev/null 2>&1 || true
  fi
}

bootstrap_agent() {
  log "loading launch agent"
  launchctl bootstrap "$(launch_domain)" "${PLIST_PATH}" >/dev/null 2>&1 || {
    bootout_agent
    launchctl bootstrap "$(launch_domain)" "${PLIST_PATH}" >/dev/null 2>&1
  }
}

kickstart_agent() {
  launchctl kickstart -k "$(launch_service_target)" >/dev/null 2>&1 || true
}

start_agent() {
  if [[ ! -f "${PLIST_PATH}" ]]; then
    die "launch agent plist does not exist: ${PLIST_PATH}; run install first"
  fi

  if launchctl print "$(launch_service_target)" >/dev/null 2>&1; then
    log "launch agent already loaded; kickstarting"
    kickstart_agent
  else
    bootstrap_agent
  fi
}

stop_agent() {
  if [[ ! -f "${PLIST_PATH}" ]]; then
    log "launch agent plist is absent; nothing to stop"
    return
  fi

  bootout_agent
  log "launch agent stopped"
}

restart_agent() {
  if [[ ! -f "${PLIST_PATH}" ]]; then
    die "launch agent plist does not exist: ${PLIST_PATH}; run install first"
  fi

  bootout_agent
  bootstrap_agent
  kickstart_agent
  log "launch agent restarted"
}

http_check() {
  local attempts="${1:-5}"
  local delay="${2:-2}"
  local attempt=1
  local http_code=""

  while (( attempt <= attempts )); do
    http_code="$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 3 "${HTTP_URL}" || true)"
    if [[ "${http_code}" != "000" && -n "${http_code}" ]]; then
      log "HTTP endpoint is reachable: ${HTTP_URL} (status ${http_code})"
      return 0
    fi

    log "HTTP endpoint not ready yet (${attempt}/${attempts}): ${HTTP_URL}"
    sleep "${delay}"
    attempt=$((attempt + 1))
  done

  return 1
}

show_binary_path() {
  local binary_path
  if binary_path="$(resolve_binary 2>/dev/null)"; then
    printf 'Binary path: %s\n' "${binary_path}"
  else
    printf 'Binary path: not found\n'
  fi
}

show_plist_status() {
  if [[ -f "${PLIST_PATH}" ]]; then
    printf 'LaunchAgent plist: present (%s)\n' "${PLIST_PATH}"
  else
    printf 'LaunchAgent plist: missing (%s)\n' "${PLIST_PATH}"
  fi
}

show_launch_status() {
  if launchctl print "$(launch_service_target)" >/dev/null 2>&1; then
    printf 'LaunchAgent status: loaded (%s)\n' "$(launch_service_target)"
    launchctl print "$(launch_service_target)" 2>/dev/null | sed -n '1,20p'
  else
    printf 'LaunchAgent status: not loaded (%s)\n' "${LABEL}"
  fi
}

show_http_status() {
  local http_code=""
  http_code="$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 3 "${HTTP_URL}" || true)"

  if [[ "${http_code}" != "000" && -n "${http_code}" ]]; then
    printf 'HTTP check: reachable (%s, status %s)\n' "${HTTP_URL}" "${http_code}"
  else
    printf 'HTTP check: unreachable (%s)\n' "${HTTP_URL}"
  fi
}

install() {
  require_macos
  ensure_uv
  warn_if_adb_missing
  ensure_tool_installed

  local binary_path
  binary_path="$(resolve_binary)"
  log "using binary: ${binary_path}"

  write_plist "${binary_path}"
  bootout_agent
  bootstrap_agent
  kickstart_agent

  printf '\nInstallation checks\n'
  printf '%s\n' '-------------------'
  show_binary_path
  show_plist_status
  show_launch_status
  if ! http_check 8 2; then
    warn "HTTP endpoint did not become reachable after retries: ${HTTP_URL}"
  fi
  show_http_status
}

status() {
  require_macos
  printf 'User: %s\n' "${USER:-$(id -un)}"
  printf 'Home: %s\n' "${HOME}"
  show_binary_path
  show_plist_status
  show_launch_status
  show_http_status
}

run_foreground() {
  require_macos
  ensure_uv
  warn_if_adb_missing
  ensure_tool_installed

  local binary_path
  binary_path="$(resolve_binary)"
  log "starting server in foreground: ${binary_path}"
  exec "${binary_path}" http --host "${HOST}" --port "${PORT}" --no-token
}

usage() {
  cat <<EOF
Usage: $0 {install|start|stop|restart|status|run}
EOF
}

main() {
  local command="${1:-}"

  case "${command}" in
    install)
      install
      ;;
    start)
      start_agent
      ;;
    stop)
      stop_agent
      ;;
    restart)
      restart_agent
      ;;
    status)
      status
      ;;
    run)
      run_foreground
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "${1:-}"
