# HA-LLM-Voice

Local voice assistant stack for Home Assistant: Ollama (LLM) + Whisper (STT) + Piper (TTS),
running in two Proxmox LXC containers alongside an existing HA instance.

Target hardware: MINISFORUM UM773 Lite (Ryzen 7 7735HS, 32GB RAM), Proxmox host at `192.168.68.240`.
HA instance: `192.168.0.211`.

```
[Mic/device] → HA Assist pipeline → Whisper (STT) → Ollama (LLM) → Piper (TTS) → [Speaker]
```

Two containers:
- **CT1 — Ollama**: LLM inference, CPU-heavy, isolated so it can be resource-capped
  or later given GPU passthrough without touching STT/TTS.
- **CT2 — Whisper + Piper**: STT/TTS via the Wyoming protocol, lightweight and bursty.

## Usage

1. In the Proxmox UI, create the two LXC containers (Debian 12) per the sizing below.
2. Copy the matching script into each container and run it as root.
3. Note each container's IP (`hostname -I`).
4. Wire the endpoints into Home Assistant (see [docs/home-assistant-setup.md](docs/home-assistant-setup.md)).

| Container | Script | CPU | RAM | Disk |
|---|---|---|---|---|
| CT1 (Ollama) | `scripts/setup-ollama.sh` | 6 cores | 16 GB | 40 GB |
| CT2 (Whisper + Piper) | `scripts/setup-whisper-piper.sh` | 2 cores | 2 GB | 10 GB |

Example, run from the Proxmox host after `pct create`/`pct start`:

```bash
pct push <CT1_ID> scripts/setup-ollama.sh /root/setup-ollama.sh
pct exec <CT1_ID> -- bash /root/setup-ollama.sh

pct push <CT2_ID> scripts/setup-whisper-piper.sh /root/setup-whisper-piper.sh
pct exec <CT2_ID> -- bash /root/setup-whisper-piper.sh
```

Or just paste the script contents into a root shell inside each container.

## Expected performance

- Whisper `base-int8`: ~1-2s transcription for a short sentence
- Ollama `8b-instruct-q4_K_M`: ~1-2s first-token latency, ~5-10 tok/s generation
- Piper: <1s synthesis
- Total round-trip: roughly 5-10 seconds per exchange

See [docs/troubleshooting.md](docs/troubleshooting.md) for common issues.
