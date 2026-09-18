# IAGuard

IAGuard is a desktop network security monitor that watches live connections, detects suspicious
outbound traffic and new listening services, and flags connections to hosts with a bad
reputation — all on your local machine.

Optionally, it can:

- **Import a signed reputation feed** published here, so it keeps an up-to-date blocklist of
  abusive networks (currently sourced from Spamhaus DROP).
- **Block attacker IPs at the firewall** (Linux/macOS) with a small, verifiable helper script.

Everything is local by design: the app analyzes your network on-device and never uploads your
traffic or events anywhere.

## ScreenShoot

<img width="1628" height="878" alt="iaward" src="https://github.com/user-attachments/assets/2469f129-ab8a-4dab-a6a7-1e370b42f262" />

## Features

- Live connection monitoring with confidence/risk scoring
- Detection of new listeners, anomalous outbound fanout, and connections to negative-reputation hosts
- Local AI analysis (offline LLM) with manual, event-driven, or periodic modes — all traffic stays on your machine
- Optional signed detection feed (see below)
- Optional bidirectional IP blocking with whitelist and automatic expiry
- Works on Linux (ufw), macOS (pfctl), and Windows (built-in firewall rules)

## Signed detection feed

The app can load a signed rules feed. The signature (RSA-2048/SHA-256) is verified against a
public key embedded in the app: any alteration, downgrade, or expiration causes the feed to be
rejected and the last known-good feed to be kept.

**Published feed:** <https://raw.githubusercontent.com/emo44/AIGuard/main/out/signatures.json>

**Delivery:**
- **Manual (default):** copy `signatures.json` into the app's signatures folder (Settings →
  "Open signatures folder" shows you where).
- **Opt-in URL (recommended):** set the feed URL in Settings. The app fetches it with a plain
  **GET request** at startup and on "Refresh now". Nothing is ever uploaded.

The feed currently includes Spamhaus DROP CIDR ranges (local/private/reserved networks are
filtered out).

## Optional firewall helper (Linux/macOS)

To actually block attacker IPs, the app uses a tiny "one job" helper
([`tools/iaguard-firewall.sh`](tools/iaguard-firewall.sh)) installed once by you with root
rights. The app never asks for a password at runtime — it only runs `sudo -n`, which fails
instantly if you have not authorized the helper.

Blocking is **bidirectional**: each IP gets an inbound rule and an outbound rule (e.g. malware
phoning home to its command-and-control server is blocked too). Whitelist entries, RFC1918
opt-in, and short-expiry automatic blocking are all configurable in Settings.

### Install (Linux)

```bash
# 1. Download and install the helper (exact file matching the published SHA-256 below)
sudo curl -fsSL https://raw.githubusercontent.com/emo44/AIGuard/main/tools/iaguard-firewall.sh \
  -o /usr/local/sbin/iaguard-firewall
sudo chmod 0755 /usr/local/sbin/iaguard-firewall

# 2. Authorize ONLY this helper in sudoers (never a generic sudo)
#    /etc/sudoers.d/iaguard — validate with: sudo visudo -cf /etc/sudoers.d/iaguard
%wheel ALL=(root) NOPASSWD: /usr/local/sbin/iaguard-firewall status, \
    /usr/local/sbin/iaguard-firewall list, \
    /usr/local/sbin/iaguard-firewall deny *, \
    /usr/local/sbin/iaguard-firewall allow *, \
    /usr/local/sbin/iaguard-firewall uninstall

# 3. Make sure ufw is running
sudo ufw enable
```

Then restart IAGuard so it detects the helper. On macOS the helper uses a dedicated
`com.iaguard` pfctl anchor (configure it to block in both directions).

### Fingerprint verification

IAGuard **verifies the helper's SHA-256 before every use** (at startup and before each action),
the same way it verifies the signed feed. If the installed file does not match, blocking is
disabled with a clear notice — a tampered or stale helper is never executed.

**Expected SHA-256 of the published helper:**

```
d53e5b9235cedb7ebb1eb0efbfa4ebfefb77fa257ef009f5ac53ce0a0443cefd
```

You can cross-check your installed copy with:

```bash
sha256sum /usr/local/sbin/iaguard-firewall
```

> If a future update changes the helper, install the new helper **and** the matching app release
> together. An old app + new helper (or the reverse) deliberately disables blocking until both
> match — that is by design.

## Uninstalling the helper

**From the app (Linux):** Settings → IP blocking → "Uninstall helper" (requires the `uninstall`
entry in your sudoers, shown above). It removes the helper's own firewall rules, the sudoers
file, and the helper itself.

**Manual (any OS):** unblock everything from the app (Tools → Blocked IPs → Unblock all), then:

```bash
sudo rm /etc/sudoers.d/iaguard
sudo rm /usr/local/sbin/iaguard-firewall
```

Your firewall (ufw/pf) is left as it was, with no IAGuard rules remaining.

## Privacy

- All scanning and analysis happens locally; nothing is uploaded.
- The feed URL, if configured, is fetched with a **GET-only** request.
- The helper is restricted to `status`, `list`, `deny`, `allow`, and `uninstall` via a
  least-privilege sudoers rule, and its integrity is verified by fingerprint before every use.
