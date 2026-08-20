# Wiring the stack into Home Assistant

In HA (`192.168.0.211`):

1. **Settings → Devices & Services → Add Integration → Ollama**
   - URL: `http://<CT1-IP>:11434`
   - Model: `llama3.1:8b-instruct-q4_K_M`

2. **Add Integration → Wyoming Protocol** (add twice — once for Whisper, once for Piper)
   - Whisper: `<CT2-IP>:10300`
   - Piper: `<CT2-IP>:10200`

3. **Settings → Voice Assistants → Add Assistant**
   - Conversation agent: Ollama
   - Speech-to-text: Faster Whisper
   - Text-to-speech: Piper
   - Set as preferred if you want it as the default assistant

4. Test via the **Assist** icon in the HA sidebar (mic button) before wiring up a
   physical device.

## Physical mic/speaker (optional)

Options, roughly cheapest → most polished:

- **ESP32-S3-BOX** — official HA voice hardware, ~$50, wake word built in
- **Home Assistant Voice Preview Edition** — purpose-built, best out-of-box experience
- Any old phone running the HA Companion app also works as an Assist client for testing
