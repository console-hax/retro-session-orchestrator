#!/usr/bin/env bash
set -euo pipefail

use_gum=0
if command -v gum >/dev/null 2>&1; then use_gum=1; fi

choose() {
  if [[ $use_gum -eq 1 ]]; then
    printf "%s\n" "$@" | gum choose
  else
    i=1; for o in "$@"; do printf "%2d) %s\n" "$i" "$o"; i=$((i+1)); done
    read -rp "> " idx; echo "${@:$idx:1}"
  fi
}

log() { if [[ $use_gum -eq 1 ]]; then gum log --structured --level info -- "$*"; else echo "[INFO] $*"; fi }

main() {
  log "retro-session-orchestrator"
  local mode
  mode=$(choose "Hardware PS2" "PCSX2")
  local label
  if [[ $use_gum -eq 1 ]]; then
    label=$(gum input --placeholder "session label")
  else
    read -rp "session label: " label
  fi
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


