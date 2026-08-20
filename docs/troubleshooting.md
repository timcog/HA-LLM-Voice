# Troubleshooting

- **Ollama unreachable from HA**: check the systemd override applied
  (`systemctl status ollama`, confirm `OLLAMA_HOST` via
  `systemctl show ollama | grep Environment`) and that the CT's firewall
  (if any) allows port 11434.
- **Whisper/Piper CT using 100% CPU idle**: shouldn't happen — Wyoming services
  are request-driven. If it does, check for a crash-loop in
  `journalctl -u wyoming-whisper` or `journalctl -u wyoming-piper`.
- **Slow responses**: drop to a smaller model (`phi3:mini` or
  `qwen2.5:7b-instruct-q4_K_M`) or reduce the Whisper model size
  (e.g. from `small-int8` to `base-int8`) before assuming the hardware is the
  bottleneck — Q4 8B should be fine on this CPU.
