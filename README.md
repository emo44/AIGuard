# IAGuard

**Local-first network threat detection with an on-device AI analyst.**

IAGuard watches the network traffic of your machine in real time, flags
suspicious behavior, explains it with a local AI, and — if you enable it —
cuts off attacker IPs at the system firewall. **Nothing leaves your
computer**: scanning, analysis, history and blocking decisions all run
locally.

## Highlights

- **Real-time monitoring** — live connection table with a risk score
  (0..1) per connection, sortable and filterable, updated every few seconds.
- **Heuristic detectors** (no AI needed, instant):
  - Port scans (`SYN_SENT` bursts)
  - Failed login bursts (brute force)
  - Outbound fan-out (a process connecting to many distinct IPs)
  - Unexpected listeners (services opening ports), with a whitelist of known processes
  - Bad reputation (local 24 h memory + an external signed feed)
  - Process fingerprints (SHA-256 of binaries matched against the feed)
- **On-device AI analyst** — suspicious events are queued, batched and
  explained by a local model (Ollama), with streaming answers, cooldown
  controls and periodic digests. You can also ask direct questions.
- **Signed reputation feed** — threat rules arrive as a versioned,
  RSA-2048/SHA-256 signed JSON feed, verified on download before being
  applied; users are notified when a new feed is published.
- **Optional firewall blocking (inbound + outbound)** — attacker IPs can
  be blocked in the system firewall, manually or automatically with a
  short expiry. Off by default.
- **Native OS notifications** for critical alerts (throttled), event
  history in a local SQLite database, and on-demand packet capture for
  risky events.

## How it works

### Layer 1 — Real-time heuristics (no AI)

Every scan (default every 5 s) reads the connection table (`ss` on Linux,
`netstat` on Windows) and applies fast heuristics: sensitive ports, scan
bursts, login failures, reputation matches. Each connection gets a risk
score; rows above the alert threshold light up in the analysis panel.

### Layer 2 — Local AI analyst (on demand)

A local LLM (Ollama) reviews the suspicious events with context and gives
a diagnosis and recommendations. Events are batched and rate-limited on
purpose: a ~9B model on CPU takes ~10 s or more per generation, so
analyzing every scan would saturate the queue. Real time comes from the
heuristics; the AI adds context when there is a real reason.

### Signed reputation feed

Reputation rules (CIDR/IP network blocks, process fingerprints, listener
whitelists) are distributed as a single JSON file signed with
RSA-2048/SHA-256:

- The signature covers a canonical representation of the feed, so any
  modification invalidates it and the feed is **rejected before use**.
- Each feed has a monotonic **version**, a **`valid_until`** expiry, and a
  **fingerprint** of its content.
- IAGuard downloads it from a configurable URL (typically a GitHub raw
  link), verifies it against the public key configured in Settings, and
  shows the feed status in the status bar.
- When a new valid version is published, users get a notification.
  If a download fails or the signature is invalid, the last good feed is
  kept.
- This repository hosts the official feed at `signatures.json`.

### Optional IP blocking

Blocking is **off by default**. With it enabled, an attacker IP can be
blocked (inbound **and** outbound) in the system firewall:

- Manual, automatic-with-expiry, or unblock-all.
- Automatic blocks have a short lifetime (default 1 h) and unblock
  themselves.
- Safety guards: loopback/link-local IPs are never blocked; RFC1918
  private networks are never blocked unless explicitly enabled in
  Settings; a whitelist excludes specific IPs/CIDRs.
- Per-OS one-time setup (never a runtime password):
  - **Windows** — run IAGuard as an administrator (`New-NetFirewallRule`
    Inbound + Outbound requires it).
  - **Linux (ufw)** — download the helper from this repo once (no clone
    needed) and authorize it with a NOPASSWD rule for it only:
    ```bash
    sudo curl -fsSL https://raw.githubusercontent.com/emo44/AIGuard/main/tools/iaguard-firewall.sh -o /usr/local/sbin/iaguard-firewall
    sudo chmod 0755 /usr/local/sbin/iaguard-firewall

    echo '%wheel ALL=(root) NOPASSWD: /usr/local/sbin/iaguard-firewall status, /usr/local/sbin/iaguard-firewall list, /usr/local/sbin/iaguard-firewall deny *, /usr/local/sbin/iaguard-firewall allow *' | sudo tee /etc/sudoers.d/iaguard
    sudo chmod 440 /etc/sudoers.d/iaguard
    sudo visudo -cf /etc/sudoers.d/iaguard   # must not report errors

    sudo ufw enable
    ```
    If your user is not in the `wheel` group, replace `%wheel` with your
    username.
  - **macOS (pfctl)** — create the `com.iaguard` anchor with a persistent
    `blocked` table and authorize the helper in sudoers; configure the
    anchor to block both directions
    (`block in from <blocked>` + `block out to <blocked>`).
- If blocking is unavailable, detection and analysis keep working; the
  status is shown in Settings.

## Getting started

1. Download and run the latest release for your operating system
   (Windows / Linux; macOS supported for detection and AI analysis).
2. Install Ollama locally and pull a model.
3. Launch IAGuard. It detects installed models and shows them in the
   toolbar dropdown; select one.
4. (Recommended) In **Settings → Signatures**, set the feed URL
   (default: the official `signatures.json` raw link) and verify the
   public key so the signed feed applies.
5. (Optional) Enable **IP blocking** in Settings and do the one-time
   per-OS setup above.

### Useful settings

| Setting | Default | Meaning |
|---|---|---|
| Scan interval | 5 s | How often the connection table is read |
| Risk threshold | 0.25 | Minimum risk to mark a row as an alert |
| Suspicious ports | 22, 23, 445, … | Listening ports considered sensitive |
| Suspicious processes | xmrig, minerd, … | Process names highlighted (miners, backdoors) |
| AI mode | events | manual · on events · periodic + events |
| AI cooldown | 60 s | Silence between automatic analyses |
| Auto-block | off | Block attacker IPs automatically with short expiry |

## Privacy

Everything is local: connection scans, event history (SQLite), packet
capture and AI analysis run on your machine. No telemetry, no cloud. The
only network access is the one you configure: the Ollama endpoint and the
signed reputation feed URL.

## Notes and limitations

- Without a GPU, large models are slow: use small models or a GPU.
- Login logs (`auth.log` / event 4625) may need permissions; without
  them the app still monitors connections.
- IAGuard is a heuristic + local-AI visibility layer, not a full IDS
  (Snort/Suricata territory). Use it as monitoring, analysis and
  first-response blocking.
