#!/usr/bin/env bash
set -euo pipefail

CN_DIR="${CN_DIR:-$HOME/oai-cn5g}"

stop_ran_processes() {
  echo "[1/4] Stopping RAN (gNB & UE)..."
  sudo killall -9 nr-softmodem nr-uesoftmodem 2>/dev/null || true
}

stop_core_network() {
  echo "[2/4] Stopping OAI 5G core network..."
  cd "$CN_DIR"
  sudo docker compose down
}

cleanup_ghost_signals() {
  echo "[3/4] Cleaning ghost RF simulator signals..."
  sudo rm -f /dev/shm/oai_rfsim*
  sudo rm -f /tmp/rfsimulator*
}

verify_everything_off() {
  echo "[4/4] Verifying all services are off..."
  echo "# Check 1: Containers"
  docker ps
  echo
  echo "# Check 2: OAI processes"
  pgrep -a softmodem || true
  echo
  echo "Expected: both checks should return empty results."
}

stop_ran_processes
stop_core_network
cleanup_ghost_signals
verify_everything_off
