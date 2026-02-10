# 5G-NTN-GEO-OAI Daily Operations

This repository packages a repeatable **start-of-day** and **end-of-day** workflow for running an OAI GEO NTN RFsim setup.

## What this repo includes

- `scripts/start_ntn_day.sh`: morning startup routine (cleanup + core start + verification + gNB/UE launch commands).
- `scripts/stop_ntn_day.sh`: evening shutdown routine (RAN stop + core stop + cleanup + verification).

## Prerequisites

- OAI Core directory available at `~/oai-cn5g`.
- OAI RAN build available at `~/openairinterface5g/cmake_targets/ran_build/build`.
- `docker compose`, `sudo`, and the OAI softmodems installed.

> You can override paths via environment variables:
>
> - `CN_DIR` (default: `~/oai-cn5g`)
> - `RAN_BUILD_DIR` (default: `~/openairinterface5g/cmake_targets/ran_build/build`)

## Morning Routine (START UP)

### 1) Clean ghost RF simulator signals

```bash
sudo rm -f /dev/shm/oai_rfsim*
sudo rm -f /tmp/rfsimulator*
```

### 2) Start the Core Network

```bash
cd ~/oai-cn5g
sudo docker compose up -d
```

Verify containers (look for `(healthy)` on `oai-amf` and `oai-upf`):

```bash
docker ps
```

### 3) Start gNB (Terminal 1)

```bash
cd ~/openairinterface5g/cmake_targets/ran_build/build

sudo ./nr-softmodem \
  -O ../../../ci-scripts/conf_files/gnb.sa.band254.u0.25prb.rfsim.ntn.conf \
  --rfsim \
  --rfsimulator.serveraddr server
```

### 4) Start UE (Terminal 2)

```bash
cd ~/openairinterface5g/cmake_targets/ran_build/build

sudo ./nr-uesoftmodem \
  -O ../../../ci-scripts/conf_files/ue.sa.conf \
  --rfsim \
  --rfsimulator.serveraddr 127.0.0.1 \
  --rfsimulator.prop_delay 238.74 \
  --band 254 \
  -r 25 \
  --numerology 0 \
  -C 2488400000 \
  --CO -873500000 \
  --ssb 60
```

### 5) Verify link works (Terminal 3)

```bash
ping -I oaitun_ue1 192.168.70.135
```

Expected latency is around **~500 ms**.

## Evening Routine (CLEAN STOP)

### 1) Stop RAN

```bash
sudo killall -9 nr-softmodem nr-uesoftmodem
```

### 2) Stop Core Network

```bash
cd ~/oai-cn5g
sudo docker compose down
```

### 3) Clean ghost RF simulator signals again

```bash
sudo rm -f /dev/shm/oai_rfsim*
sudo rm -f /tmp/rfsimulator*
```

### 4) Verify everything is off

```bash
# Check 1: Are containers gone?
docker ps

# Check 2: Are OAI processes gone?
pgrep -a softmodem
```

Both checks should return empty results.

---

## Quick Usage

Make scripts executable once:

```bash
chmod +x scripts/start_ntn_day.sh scripts/stop_ntn_day.sh
```

Run morning startup helper:

```bash
./scripts/start_ntn_day.sh
```

Run evening shutdown helper:

```bash
./scripts/stop_ntn_day.sh
```
