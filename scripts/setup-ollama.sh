#!/usr/bin/env bash
# CT1: Ollama LLM inference container.
# Run as root inside a Debian 12 LXC (recommended: 6 cores, 16GB RAM, 40GB disk).
set -euo pipefail

MODEL="${OLLAMA_MODEL:-llama3.1:8b-instruct-q4_K_M}"

apt update && apt upgrade -y
apt install -y curl
curl -fsSL https://ollama.com/install.sh | sh
systemctl enable ollama

# Expose Ollama to the LAN (default is localhost-only).
mkdir -p /etc/systemd/system/ollama.service.d
cat > /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

systemctl daemon-reload
systemctl restart ollama

echo "Pulling model: ${MODEL}"
ollama pull "${MODEL}"

echo
echo "=== Ollama setup complete ==="
echo "IP address(es): $(hostname -I)"
echo "Test with: ollama run ${MODEL} \"Say hello in one sentence.\""
