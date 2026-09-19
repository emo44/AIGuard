[![Total Downloads](https://img.shields.io/github/downloads/emo44/AIGuard/total?label=Total%20Downloads&style=flat-square&color=2ea44f)](https://github.com/emo44/AIGuard/releases)[![Latest Release Downloads](https://img.shields.io/github/downloads-pre/emo44/AIGuard/latest/total?label=Latest%20Downloads%20%28incl.%20pre-releases%29&style=flat-square)](https://github.com/emo44/AIGuard/releases)
# IAGuard
Network security monitor with local AI. Watches your connections in real time,
flags suspicious activity with local heuristics, and — **optionally** — a local
AI analyst (Ollama) interprets what it sees. **Nothing leaves your computer**:
no account, no cloud, no telemetry.

## Features

- **Real-time monitoring** of active connections and system events, with a
  configurable interval.
- **Local heuristics**: possible port scans, new ports listening, failed login
  attempts (brute force) and connections to IPs with a bad reputation. These
  work with or without AI.
- **Optional AI analyst** (Ollama): rates the risk, explains what is suspicious
  and why, and suggests actions. Answers your questions in streaming about the
  current state of your network. Everything runs on your own machine.
- **Connections panel** that is sortable and filterable, with instant risk score
  and suspicious processes flagged.
- **Event history** with analysis and search by time window.
- **Native notifications** on alerts (scans, failed logins).
- **Optional blocking** of malicious IPs through the system firewall, with
  whitelist and configurable duration.
- **Reputation feed** updated and signed (cryptographically verified).
- **No GPU required**: works well with small models on CPU (AI features).

## Platforms

Only **Windows** and **Linux** builds are published.

## Requirements

- **Windows**: Windows 10 or 11 (64-bit). Nothing else needs to be installed.
- **Linux**: standard tools already present on virtually every distro —
  `ss` (iproute2) for connections and `journalctl` (systemd) for failed-login
  detection. No root required for monitoring.
- **Optional**: Ollama running locally with an installed model
  (recommended without GPU: `llama3.2:3b`, `qwen3:4b`) to enable the AI analyst.
  The app works fully without it.

## Disclaimer

Project in **beta**: distributed "as is", without warranties. Use it as a
visibility and analysis layer — it does not replace a full IDS/IPS system.

## ScreenShoot

<img width="1628" height="878" alt="iaward" src="https://github.com/user-attachments/assets/2469f129-ab8a-4dab-a6a7-1e370b42f262" />


