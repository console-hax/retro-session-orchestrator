#!/usr/bin/env bash
set -euo pipefail

choose() {
  i=1; for o in "$@"; do printf "%2d) %s\n" "$i" "$o"; i=$((i+1)); done
  read -rp "> " idx; echo "${@:$idx:1}"
}

log() { echo "[INFO] $*"; }

main() {
  log "retro-session-orchestrator"
  local mode label
  mode=$(choose "Hardware PS2" "PCSX2")
  read -rp "session label: " label
  log "mode=$mode label=$label"

  local BRIDGE_DIR="../hairglasses_ps2_visualizer_modern/bridge/ledfx-artnet-bridge"
  local APP_DIR="../hairglasses_ps2_visualizer_modern"
  local PY_PID_FILE="/tmp/vis_pyserve.pid"

  start_bridge(){
    if [[ -f "$BRIDGE_DIR/docker-compose.yml" ]]; then
      (cd "$BRIDGE_DIR" && sudo docker compose up -d)
      log "bridge up"
    else
      log "bridge compose not found (skipping)"
    fi
  }

  stop_bridge(){
    if [[ -f "$BRIDGE_DIR/docker-compose.yml" ]]; then
      (cd "$BRIDGE_DIR" && sudo docker compose down || true)
      log "bridge down"
    fi
  }

  start_web(){
    if [[ -f "$PY_PID_FILE" ]] && kill -0 "$(cat "$PY_PID_FILE")" 2>/dev/null; then
      log "web already running (pid $(cat "$PY_PID_FILE"))"
      return
    fi
    (
      cd "$APP_DIR"
      nohup python3 -m http.server 8080 -d public >/tmp/vis_pyserve.log 2>&1 & echo $! > "$PY_PID_FILE"
    )
    log "web up on http://localhost:8080"
  }

  stop_web(){
    if [[ -f "$PY_PID_FILE" ]] && kill -0 "$(cat "$PY_PID_FILE")" 2>/dev/null; then
      kill "$(cat "$PY_PID_FILE")" || true
      rm -f "$PY_PID_FILE"
      log "web down"
    else
      log "web not running"
    fi
  }

  dmx_test(){
    (
      cd "$APP_DIR"
      timeout 3s python3 tools_send_artdmx.py --host 127.0.0.1 --fps 15 || true
    )
    log "sent DMX test burst"
  }

  start_bridge
  start_web

  while true; do
    echo ""
    echo "Select action:"
    local action
    action=$(choose \
      "DMX test (3s)" \
      "Stop web" \
      "Start web" \
      "Stop bridge" \
      "Start bridge" \
      "Quit")
    case "$action" in
      "DMX test (3s)") dmx_test ;;
      "Stop web") stop_web ;;
      "Start web") start_web ;;
      "Stop bridge") stop_bridge ;;
      "Start bridge") start_bridge ;;
      "Quit") break ;;
    esac
  done
}

main "$@"




