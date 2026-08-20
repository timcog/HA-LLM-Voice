#!/usr/bin/env bash
set -euo pipefail

CT1_ID="${CT1_ID:-201}"
CT2_ID="${CT2_ID:-202}"
BRIDGE="${BRIDGE:-vmbr0}"
STORAGE="${STORAGE:-local-lvm}"
TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-local}"
REPO_RAW="https://raw.githubusercontent.com/timcog/HA-LLM-Voice/claude/local-proxmox-setup-pc062e"

TEMPLATE=$(pveam list "${TEMPLATE_STORAGE}" | awk '/debian-12-standard/ {print $1}' | tail -1)
if [ -z "${TEMPLATE}" ]; then
  pveam update
  LATEST=$(pveam available --section system | awk '/debian-12-standard/ {print $2}' | sort -V | tail -1)
  pveam download "${TEMPLATE_STORAGE}" "${LATEST}"
  TEMPLATE=$(pveam list "${TEMPLATE_STORAGE}" | awk '/debian-12-standard/ {print $1}' | tail -1)
fi

if ! pct status "${CT1_ID}" >/dev/null 2>&1; then
  pct create "${CT1_ID}" "${TEMPLATE}" \
    --hostname ollama \
    --cores 6 \
    --memory 16384 \
    --rootfs "${STORAGE}:40" \
    --net0 "name=eth0,bridge=${BRIDGE},ip=dhcp" \
    --onboot 1 \
    --features nesting=1 \
    --unprivileged 1
fi
pct start "${CT1_ID}"

if ! pct status "${CT2_ID}" >/dev/null 2>&1; then
  pct create "${CT2_ID}" "${TEMPLATE}" \
    --hostname whisper-piper \
    --cores 2 \
    --memory 2048 \
    --rootfs "${STORAGE}:10" \
    --net0 "name=eth0,bridge=${BRIDGE},ip=dhcp" \
    --onboot 1 \
    --features nesting=1 \
    --unprivileged 1
fi
pct start "${CT2_ID}"

sleep 10

curl -fsSL "${REPO_RAW}/scripts/setup-ollama.sh" -o /root/setup-ollama.sh
curl -fsSL "${REPO_RAW}/scripts/setup-whisper-piper.sh" -o /root/setup-whisper-piper.sh

pct push "${CT1_ID}" /root/setup-ollama.sh /root/setup-ollama.sh
pct push "${CT2_ID}" /root/setup-whisper-piper.sh /root/setup-whisper-piper.sh

pct exec "${CT1_ID}" -- bash /root/setup-ollama.sh
pct exec "${CT2_ID}" -- bash /root/setup-whisper-piper.sh

CT1_IP=$(pct exec "${CT1_ID}" -- hostname -I | awk '{print $1}')
CT2_IP=$(pct exec "${CT2_ID}" -- hostname -I | awk '{print $1}')

echo
echo "=== Deployment complete ==="
echo "Ollama (CT${CT1_ID}):        http://${CT1_IP}:11434"
echo "Whisper (CT${CT2_ID}, STT):  ${CT2_IP}:10300"
echo "Piper (CT${CT2_ID}, TTS):    ${CT2_IP}:10200"
