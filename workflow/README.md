# Workflow library

Seven production-scale n8n automation systems. **533 nodes, 399 connections, 10 webhook paths** in total.

> **These are not currently hosted.** The VPS that previously ran them was decommissioned in 2026. Import them into n8n Cloud, local Docker, or n8n Desktop — see the [root README](../README.md) for setup.
>
> **All of these were built by me using AI coding tools.** I chose the problem, designed the flow and the failure paths, and tested until they worked. I did not hand-write the code line by line.

---

## 1. AP Payment Integrity & GST ITC Recovery Engine v1.0

**File:** `ap-integrity-engine.workflow.json` · **111 nodes** · largest system in the library

Stops money leaking out of accounts payable, and recovers GST input tax credit that would otherwise be lost.

- Duplicate and near-duplicate invoice detection
- Three-way match engine (PO ↔ GRN ↔ invoice)
- GSTIN checksum validation and tax integrity checks against `api.gstincheck.co.in`
- Bank account and IFSC validation via `ifsc.razorpay.com`
- Vendor sanctions screening via `api.opensanctions.org`
- ITC reconciliation engine and cash/early-payment-discount optimiser
- **Triggers:** ERP webhook (`ap-integrity/ingest`), 15-minute IMAP poll of `invoices@company.com`, monthly ITC cycle, Monday 08:00 IST CFO digest, dedicated error trigger
- **Integrations:** PostgreSQL, Gmail, IMAP, Google Sheets, Slack, OpenAI

---

## 2. AI Business Operator v1

**File:** `ai-business-operator.json` · **105 nodes**

An always-on AI front desk covering six roles for a small business.

- Multi-channel intake: web, WhatsApp, email
- Outbound AI voice calls via Vapi (`api.vapi.ai/call`)
- Meeting booking through Cal.com v2
- Embeddings-backed knowledge retrieval for answering enquiries
- Autonomous follow-up sweep every 30 minutes deciding who to nudge
- Daily 20:00 IST owner digest
- **Webhooks:** `intake`, `vapi-events`
- **Models:** Anthropic Messages API, OpenAI chat + embeddings, Gemini 2.0 Flash

---

## 3. BharatAP — Zero-Leak Invoice-to-Pay & GST ITC Recovery Engine (India)

**File:** `BharatAP_Zero_Leak_Invoice_to_Pay_GST_ITC_Engine.json` · **99 nodes**

Full invoice-to-pay pipeline built specifically around Indian GST mechanics.

- Invoice intake, field validation and classification
- GSTR-2B upload and reconciliation
- E-invoice verification against `einv-apisandbox.nic.in`
- Self-installing database schema (a manual trigger node creates all tables and seeds data)
- Approval callback loop, savings report builder, error classification engine
- **Webhooks:** `ap-invoice-intake`, `ap-approval-callback`, `ap-gstr2b-upload`
- **Schedules:** five, including a 07:00 IST payment run
- **Credentials:** `BharatAP Postgres`, `BharatAP SMTP`

---

## 4. MSME Receivables + IT s.43B(h) Compliance Autopilot

**File:** `MSME-Receivables-43Bh-Autopilot.json` · **67 nodes**

Chases overdue MSME receivables while keeping the buyer compliant with the 45-day payment rule under Income Tax section 43B(h) and MSMED sections 15/16.

- Udyam registration verification
- A compliance clock engine tracking the statutory deadline per invoice
- Multilingual vendor reminder composer
- Razorpay payment link generation and WhatsApp reminders
- 09:00 IST CFO digest
- 15 sticky notes documenting the logic inline, and 9 decision branches
- **Webhooks:** `msme/invoice-ingest`, `msme/payment-callback`
- **Credentials:** `MSME Ledger Postgres`, `MSME Outbound SMTP`

---

## 5. DevPilotX — Coaching Institute Admission Engine v3.0 (Production)

**File:** `wf_coaching_v3.json` · **58 nodes**

Answers every admission enquiry in seconds instead of hours. Built to be sold and deployed to local coaching institutes.

- Website form and WhatsApp intake
- Lead scoring and automatic message composition
- Timed follow-up sequences with reply matching back to the right lead
- Google Sheets as a lightweight CRM
- Instant Telegram alerts to the owner, plus a daily report
- A single `02 SETTINGS - EDIT ONLY THIS NODE` node so a non-technical operator can configure the whole workflow in one place
- Dedicated error trigger
- **Webhook:** `coaching-enquiry`

---

## 6. DevPilotX — Clinic Appointment & Reputation Engine v3.0 (Production)

**File:** `wf_clinic_v3.json` · **54 nodes**

WhatsApp-first appointment booking plus automated Google review generation.

- Patient validation and cleaning
- Double-booking prevention with slot matching
- Tomorrow's-patients reminder run and today's-patients list
- Post-visit Google review request flow
- Telegram owner alerts, daily digest, error trigger
- **Webhook:** `clinic-appointment`

---

## 7. AI Admission Response Engine — Coaching Institute

**File:** `AI_Admission_Response_Engine_Coaching_Institute.json` · **39 nodes**

A leaner, agent-first version of the admissions system.

- LangChain agent (`Admission Counsellor AI`) with structured output parsing and buffered conversation memory
- Enquiry normalisation and CRM logging to Google Sheets
- Owner report builder
- **Webhook:** `admission-enquiry`

---

## Engineering notes

Things that are true across the library and that I would want a reviewer to notice:

- **Error handling is not an afterthought.** Six of the seven workflows have a dedicated error-trigger path rather than relying on n8n defaults.
- **Retry and escalation sweepers** run on schedules rather than assuming first-attempt success.
- **Idempotency** is handled explicitly on ingest paths so a replayed webhook does not double-process an invoice or a lead.
- **HTTP semantics are correct**: `202 Accepted` for async ingest, `400` for malformed payloads, `401` for failed auth, `200` only on completed synchronous work.
- **Scheduled digests are timezone-pinned to Asia/Kolkata**, because these were designed for Indian businesses.
- **Configuration is centralised** where a non-technical owner has to touch it (see the single settings node pattern in v3.0 workflows).

## Known limitations

- None of these has been run against a live paying customer's systems. Placeholder hosts and tokens are still in place — see the [root README](../README.md#placeholders-you-must-replace).
- Several GST integrations point at sandbox endpoints, not production.
- No automated tests. Validation was manual, inside the n8n editor.
