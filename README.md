# n8n — private self-hosted (n8n.devpilotx.com)

Backup of the **configuration + workflows** for the private n8n instance at
**https://n8n.devpilotx.com**. This repo does **NOT** contain n8n source code or
any secrets. Secrets live only in `/opt/n8n/.env` on the server (chmod 600).

---

## Architecture

```
Browser --HTTPS--> Cloudflare --HTTPS(LE origin cert)--> nginx (443)
                                                          |  (temp Basic-Auth)
                                                          v
                                            n8n container 127.0.0.1:5678
                                            (official n8nio/n8n image,
                                             Docker host-networking)
                                                          |
                                                          v
                                    EXISTING host PostgreSQL 127.0.0.1:5432
                                            db "n8n" / user "n8n_user"
```

- **Image:** official `n8nio/n8n:latest` (no source build).
- **Networking:** Docker `network_mode: host` so n8n reaches the loopback-only
  host Postgres **without reconfiguring Postgres**. n8n binds to
  `127.0.0.1:5678` only (`N8N_LISTEN_ADDRESS`) — never public.
- **TLS:** Let's Encrypt ECDSA cert via **DNS-01 (dns-cloudflare)**; auto-renews.
- **DB:** dedicated `n8n` database + `n8n_user` role (no rights on other DBs).

### File layout on the VPS
```
/opt/n8n/
├── .env                 # SECRETS (chmod 600): encryption key + DB password
├── docker-compose.yml
├── backup.sh            # daily DB + data backup (cron)
├── data/                # n8n persistent data (.n8n) -> container /home/node/.n8n
├── clis/                # subscription CLIs + logins -> container /opt/clis
│   ├── bin/ (claude, codex, gemini, ai-switch)
│   ├── home/ (.claude/.codex/.gemini logins = HOME in container)
│   └── profiles/ (saved named logins for ai-switch)
├── backups/             # nightly dumps (14-day retention)
└── nginx/.htpasswd      # temporary Basic-Auth gate
/etc/nginx/sites-available/n8n.devpilotx.com   # vhost (this repo: nginx/)
/etc/cron.d/n8n-backup                          # daily 03:30 backup
```

---

## First-time access & owner account

Deployed with the **setup screen ready**, protected by a **temporary nginx HTTP
Basic-Auth** gate (so nobody grabs the owner account before you). Credentials
are on the server at `/opt/n8n/nginx/basic-auth.txt`.

1. Open **https://n8n.devpilotx.com**.
2. Browser prompt (Basic-Auth) -> enter the `owner-setup` user + password.
3. n8n **"Set up owner account"** -> enter **your** email + strong password.

### Enable 2FA (Google Authenticator)
1. Log in -> top-left avatar -> **Settings**.
2. **Personal -> Two-factor authentication -> Enable**.
3. Scan the QR with Google Authenticator (or any TOTP app).
4. Enter the 6-digit code to confirm.
5. **SAVE THE RECOVERY CODES** — the only way back in if you lose the phone.

### Removing / scoping the Basic-Auth gate
```bash
# Remove entirely (needed for public third-party webhooks):
sudo sed -i '/auth_basic/d' /etc/nginx/sites-available/n8n.devpilotx.com
sudo nginx -t && sudo systemctl reload nginx
sudo rm -f /opt/n8n/nginx/basic-auth.txt
```

---

## AI engines — two independent paths

### A) Subscription CLIs (no API key) — via **Execute Command** node
On PATH inside the container: **claude**, **codex**, **gemini**. Logins are
interactive OAuth, done by you once (persist in `/opt/n8n/clis/home`):

```bash
# Claude Code (Claude Max/Pro):
sudo docker exec -it -u node -e HOME=/opt/clis/home n8n claude setup-token
# Codex (ChatGPT Plus/Pro):
sudo docker exec -it -u node -e HOME=/opt/clis/home n8n codex        # "Sign in with ChatGPT"
# Gemini CLI (free Google login):
sudo docker exec -it -u node -e HOME=/opt/clis/home n8n gemini       # "Login with Google"
```
Use in an **Execute Command** node: `claude -p "..."`, `codex exec "..."`,
`gemini -p "..."`.

**Switch accounts (token-based):**
```bash
sudo docker exec -u node -e HOME=/opt/clis/home n8n ai-switch save claude personal
sudo docker exec -u node -e HOME=/opt/clis/home n8n ai-switch use  claude work
sudo docker exec -u node -e HOME=/opt/clis/home n8n ai-switch status
```
Import `workflows/02-switch-ai-engine.json` to flip engines from inside n8n.

> **Kiro CLI** is installed on the host (`~/.local/bin/kiro-cli`) but left
> **unauthenticated (optional / later)** — needs interactive device-flow login
> (`kiro-cli login --use-device-flow`); from n8n call it via the SSH node.

### B) API-key path — via native nodes
n8n: **Credentials -> + Create credential -> search provider -> paste key.**

| Provider | Subscription (CLI) | API-key node | Get key |
|---|---|---|---|
| Anthropic | `claude` | **Anthropic** credential | console.anthropic.com |
| OpenAI | `codex` | **OpenAI** credential | platform.openai.com/api-keys |
| Google Gemini | `gemini` | **Google Gemini (PaLM) API** | aistudio.google.com/apikey |
| OpenRouter | — | **OpenRouter** (one key, 100s of models) | openrouter.ai/keys |
| Ollama | — | **NOT installed (skipped by request)** | — |

---

## Maintenance
```bash
cd /opt/n8n
sudo docker compose logs -f n8n                 # logs
sudo docker compose restart n8n                 # restart
sudo docker compose pull && sudo docker compose up -d && sudo docker image prune -f   # UPDATE
sudo /opt/n8n/backup.sh                          # manual backup (nightly 03:30)
```
### Restore
```bash
sudo runuser -u postgres -- pg_restore --clean --if-exists -d n8n /opt/n8n/backups/n8n-db-YYYYMMDD-HHMMSS.dump
sudo tar -xzf /opt/n8n/backups/n8n-data-YYYYMMDD-HHMMSS.tar.gz -C /opt/n8n
```
> Restore requires the same `N8N_ENCRYPTION_KEY` (in `/opt/n8n/.env`). Keep a
> copy of `.env` off-server.

## Security notes
- Port 5678 bound to 127.0.0.1 only and not in the firewall — never public.
- UFW: only 2222 (SSH), 80/443 (Cloudflare) open; fail2ban active.
- Editor layers: Cloudflare -> Basic-Auth -> n8n owner login -> 2FA.
