#!/usr/bin/env bash
set -euo pipefail

choose() {
  i=1; for o in "$@"; do printf "%2d) %s\n" "$i" "$o"; i=$((i+1)); done
  read -rp "> " idx; echo "${@:$idx:1}"
}

log() { echo "[INFO] $*"; }

main() {
  log "retro-session-orchestrator"
  local mode
  mode=$(choose "Hardware PS2" "PCSX2")
  local label
  read -rp "session label: " label
  log "mode=$mode label=$label"
  # Start bridge via compose if present
  if [[ -f "../hairglasses_ps2_visualizer_modern/bridge/ledfx-artnet-bridge/docker-compose.yml" ]]; then
    (cd ../hairglasses_ps2_visualizer_modern/bridge/ledfx-artnet-bridge && docker compose up -d)
    log "bridge up"
  else
    log "bridge compose not found (skipping)"
  fi
  # TODO: Invoke mcp2-toolbox to prep VMC
  log "session ready: $label"
}

main "$@"




