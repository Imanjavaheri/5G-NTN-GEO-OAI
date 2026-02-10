#!/usr/bin/env bash
set -euo pipefail

CN_DIR="${CN_DIR:-$HOME/oai-cn5g}"
RAN_BUILD_DIR="${RAN_BUILD_DIR:-$HOME/openairinterface5g/cmake_targets/ran_build/build}"

cleanup_ghost_signals() {
  echo "[1/4] Cleaning ghost RF simulator signals..."
  sudo rm -f /dev/shm/oai_rfsim*
  sudo rm -f /tmp/rfsimulator*
}

start_core_network() {
  echo "[2/4] Starting OAI 5G core network..."
  cd "$CN_DIR"
  sudo docker compose up -d
}

verify_core_health() {
  echo "[3/4] Verifying core containers..."
  docker ps
  echo
  echo "Expected: oai-amf and oai-upf should show '(healthy)' in STATUS."
}

print_ran_commands() {
  echo "[4/4] Open two terminals and run the following commands:"
  echo
  echo "--- Terminal 1 (gNB Satellite Mode) ---"
  cat <<CMD
cd "$RAN_BUILD_DIR"
sudo ./nr-softmodem \\
  -O ../../../ci-scripts/conf_files/gnb.sa.band254.u0.25prb.rfsim.ntn.conf \\
  --rfsim \\
  --rfsimulator.serveraddr server
CMD

  echo
  echo "--- Terminal 2 (UE Satellite Mode) ---"
  cat <<CMD
cd "$RAN_BUILD_DIR"
sudo ./nr-uesoftmodem \\
  -O ../../../ci-scripts/conf_files/ue.sa.conf \\
  --rfsim \\
  --rfsimulator.serveraddr 127.0.0.1 \\
  --rfsimulator.prop_delay 238.74 \\
  --band 254 \\
  -r 25 \\
  --numerology 0 \\
  -C 2488400000 \\
  --CO -873500000 \\
  --ssb 60
CMD

  echo
  echo "Then verify link quality from Terminal 3:"
  echo "ping -I oaitun_ue1 192.168.70.135"
  echo "Expected RTT: roughly ~500 ms."
}

cleanup_ghost_signals
start_core_network
verify_core_health
print_ran_commands
