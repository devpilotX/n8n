# devpilotX / n8n

n8n automation workflows built by **Dipanshu Kumar** ([@devpilotX](https://github.com/devpilotX)).

> **Status as of 10 September 2026: NOT HOSTED.**
> The VPS that previously ran `n8n.devpilotx.com` has been decommissioned. There is no live n8n instance, no live webhook endpoint, and no running database behind this repository. Everything here is source material: importable workflow JSON and archived infrastructure configuration.

---

## What this repository is now

A portfolio and source-of-truth repository for automation workflows I designed and built. Each workflow is a complete, importable n8n JSON file. They are designed to run, but they are **not currently running anywhere**, and several contain deliberate placeholder values that must be replaced before use (see [Placeholders](#placeholders-you-must-replace)).

**How these were built, stated plainly:** I specified, architected, tested and debugged these systems using AI coding tools. I chose the problems, designed the data flow, defined the error and retry paths, and iterated until they worked. I did not hand-write the code line by line. I am saying this up front because I would rather be trusted than look impressive.

---

## Repository layout

```
.
├── workflow/                 # Main workflow library (7 production-scale systems)
│   └── README.md             # Catalogue: node counts, webhooks, credentials, placeholders
├── workflows/                # Legacy: 3 small test/utility workflows from the VPS era
├── docker-compose.yml        # ARCHIVED - VPS-era self-host config, not in use
├── nginx/                    # ARCHIVED - VPS-era reverse-proxy vhost, not in use
├── scripts/                  # ARCHIVED - VPS-era backup + CLI switcher, not in use
└── .env.example              # Template only. No real secrets have ever been committed.
```

### Archived files

`docker-compose.yml`, `nginx/n8n.devpilotx.com.conf`, `scripts/backup.sh` and `scripts/ai-switch` all assume a live server at `n8n.devpilotx.com` with host-networked PostgreSQL, Let's Encrypt DNS-01 certificates, nightly cron backups, UFW and fail2ban. **None of that exists any more.** They are kept deliberately as a record of infrastructure I designed and operated, not as working configuration. Do not run them expecting a result.

---

## The workflow library

Seven production-scale automation systems. Full detail in [`workflow/README.md`](workflow/README.md).

| Workflow | Nodes | Domain |
|---|---|---|
| AP Payment Integrity & GST ITC Recovery Engine v1.0 | 111 | Accounts payable, GST input tax credit |
| AI Business Operator v1 | 105 | Multi-channel AI front desk, voice, follow-up |
| BharatAP — Zero-Leak Invoice-to-Pay & GST ITC Engine | 99 | Invoice-to-pay, GSTR-2B reconciliation |
| MSME Receivables + IT s.43B(h) Compliance Autopilot | 67 | MSME receivables, 45-day compliance |
| Coaching Institute Admission Engine v3.0 | 58 | Admissions lead response |
| Clinic Appointment & Reputation Engine v3.0 | 54 | Appointments, review generation |
| AI Admission Response Engine — Coaching Institute | 39 | Admissions enquiry agent |
| **Total** | **533** | 10 webhook paths, 399 node connections |

---

## Running these without a server

Since there is no VPS, pick one of these three:

### 1. n8n Cloud (easiest, recommended)
Sign up at [n8n.io](https://n8n.io). The Starter plan is around USD 24/month for roughly 5,000 executions. Webhooks, credentials storage and scheduling all work out of the box with no infrastructure to maintain. **This is the right choice if any of these workflows are going to a paying customer.**

### 2. Local Docker (free)
```bash
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -e GENERIC_TIMEZONE="Asia/Kolkata" \
  -e TZ="Asia/Kolkata" \
  docker.io/n8nio/n8n
```
Open `http://localhost:5678`. Note that **inbound webhooks will not work from the public internet** unless you tunnel (for example with `cloudflared` or `ngrok`). Fine for development and demos.

### 3. n8n Desktop (free)
Download the desktop app. Same limitation on public webhooks.

### Importing a workflow
`Workflows` → `Import from File` → select the JSON from `workflow/` → then open each red-flagged node and attach credentials.

---

## Placeholders you must replace

These workflows were built as complete designs but have **not** been connected to a live customer environment. Before any of them will run you must replace:

| Placeholder | Appears in | Replace with |
|---|---|---|
| `https://your-n8n.com/webhook/...` | Clinic v3, Coaching v3 | Your real n8n webhook base URL |
| `Bearer YOUR_PERMANENT_TOKEN` | Clinic v3, Coaching v3 | Meta WhatsApp Cloud API permanent token |
| `https://g.page/r/YOUR_REVIEW_CODE/review` | Clinic v3 | The clinic's real Google review link |
| `REPLACE_ERP_HOST` | AP Integrity Engine | Customer ERP hostname |
| `REPLACE_GSP_HOST` | AP Integrity, BharatAP | GST Suvidha Provider endpoint |
| `REPLACE_ITSM_HOST` | AP Integrity Engine | ITSM/ticketing endpoint |
| `REPLACE_MCA_PROVIDER` | AP Integrity Engine | MCA data provider endpoint |
| `https://n8n.example.com` | Several | Your n8n base URL |
| `api.example-kyc.in`, `erp.internal.example`, `wiki.internal` | Several | Real internal endpoints |
| `httpbin.org/post` | Test paths | Real target endpoint |

Also set the sandbox-vs-production toggles: several workflows point at `api.sandbox.co.in/gst` and `einv-apisandbox.nic.in`, which are sandbox GST/e-invoice endpoints.

---

## Credentials required

No credential values are stored in this repository — n8n exports contain credential *names* only. You will need to create these yourself in your own n8n instance:

- **PostgreSQL** — `BharatAP Postgres`, `MSME Ledger Postgres`, plus AP Integrity's Postgres
- **SMTP** — `BharatAP SMTP`, `MSME Outbound SMTP`, Coaching v3 SMTP
- **Gmail OAuth2** and **IMAP** (`invoices@company.com`) — AP Integrity Engine
- **Google Sheets OAuth2** — AP Integrity, Clinic v3, Coaching v3
- **Slack API** — AP Integrity Engine
- **Telegram Bot API** (`DevPilotX`) — Clinic v3, Coaching v3
- **WhatsApp Trigger / HTTP Header Auth** (Meta Cloud API) — Clinic v3, Coaching v3
- **OpenAI / Anthropic / Google Gemini** — several workflows
- **Vapi** (voice) and **Cal.com** — AI Business Operator

---

## Security

All seven workflow files were scanned before publication. **No live API keys, tokens, private keys, IP addresses or credential values are present.** The only bearer token string in the repository is the literal placeholder `YOUR_PERMANENT_TOKEN`. Three 32-character hex strings appear in the files; these are n8n internal `versionId` and `instanceId` values, not secrets.

If you believe you have found a real secret in this repository, open an issue immediately and do not include the secret in the issue body.

---

## Contact

**Dipanshu Kumar**
connect.dipanshukumar@gmail.com · [linkedin.com/in/dipanshu03j](https://linkedin.com/in/dipanshu03j) · [github.com/devpilotX](https://github.com/devpilotX)

Available for AI operations, automation implementation and n8n consulting work. Open to relocation and to remote.
