#!/usr/bin/env bash
# CT2: Wyoming Whisper (STT) + Wyoming Piper (TTS) container.
# Run as root inside a Debian 12 LXC (recommended: 2 cores, 2GB RAM, 10GB disk).
set -euo pipefail

WHISPER_MODEL="${WHISPER_MODEL:-base-int8}"
WHISPER_LANG="${WHISPER_LANG:-en}"
PIPER_VOICE="${PIPER_VOICE:-en_US-lessac-medium}"

apt update && apt install -y python3-pip python3-venv git ffmpeg

python3 -m venv /opt/whisper-env
source /opt/whisper-env/bin/activate
pip install --upgrade pip
pip install wyoming-faster-whisper wyoming-piper

mkdir -p /opt/whisper-data /opt/piper-data

echo "Downloading Piper voice: ${PIPER_VOICE}"
python -m piper.download_voices "${PIPER_VOICE}" --data-dir /opt/piper-data
deactivate

cat > /etc/systemd/system/wyoming-whisper.service << EOF
[Unit]
Description=Wyoming Faster Whisper
After=network.target

[Service]
ExecStart=/opt/whisper-env/bin/python -m wyoming_faster_whisper \\
  --model ${WHISPER_MODEL} \\
  --language ${WHISPER_LANG} \\
  --uri tcp://0.0.0.0:10300 \\
  --data-dir /opt/whisper-data \\
  --download-dir /opt/whisper-data
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/wyoming-piper.service << EOF
[Unit]
Description=Wyoming Piper
After=network.target

[Service]
ExecStart=/opt/whisper-env/bin/python -m wyoming_piper \\
  --voice ${PIPER_VOICE} \\
  --uri tcp://0.0.0.0:10200 \\
  --data-dir /opt/piper-data
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now wyoming-whisper
systemctl enable --now wyoming-piper

echo
echo "=== Whisper + Piper setup complete ==="
echo "IP address(es): $(hostname -I)"
echo "Whisper (STT): tcp://<this-ip>:10300"
echo "Piper (TTS):   tcp://<this-ip>:10200"
echo "Check status with: systemctl status wyoming-whisper wyoming-piper"
