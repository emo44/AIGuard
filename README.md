# IAGuard

Network security monitor with local AI. Watches your connections in real time
and a local AI analyst (Ollama) interprets what it sees — **nothing leaves your
computer**: no account, no cloud, no telemetry.

## Features

- **Real-time monitoring** of active connections and system events, with a
  configurable interval.
- **Local heuristics**: possible port scans, new ports listening, failed login
  attempts (brute force) and connections to IPs with a bad reputation.
- **Local AI analyst** (Ollama): rates the risk, explains what is suspicious and
  why, and suggests actions. Answers your questions in streaming, directly about
  the current state of your network.
- **Connections panel** that is sortable and filterable, with instant risk score
  and suspicious processes flagged.
- **Event history** with analysis and search by time window.
- **Native notifications** on alerts (scans, failed logins).
- **Optional blocking** of malicious IPs through the system firewall, with
  whitelist and configurable duration.
- **Reputation feed** updated and signed (cryptographically verified).
- **No GPU required**: works well with small models on CPU.

## Platforms

Only **Windows** and **Linux** builds are published.

## Requirements

- Ollama running locally with an installed model
  (recommended without GPU: `llama3.2:3b`, `qwen3:4b`).

## Disclaimer

Project in **beta**: distributed "as is", without warranties. Use it as a
visibility and analysis layer — it does not replace a full IDS/IPS system.

## ScreenShoot

<img width="1628" height="878" alt="iaward" src="https://github.com/user-attachments/assets/2469f129-ab8a-4dab-a6a7-1e370b42f262" />


