---
name: cr-security
description: Security-focused 3-pass review for changes touching authentication,
access policies, public endpoints, or data boundaries. Pass 3 defers backend-specific
deep checks to the project's database-safety adapter skill. Every finding is MUST FIX.
Auto-fixes with Opus after review. Triggers on changes to auth, middleware, public-path
config, access policies, server actions, share tokens, or cross-tenant isolation.
---

# /cr-security — Security review

Opt-in. Run manually before committing any change touching:
- Authentication or middleware/route guards
- Public unauthenticated handlers (e.g. share-token routes, callback routes)
- Access policies or data-access boundaries
- Cross-tenant isolation (anything that could return another tenant's data)
- Share tokens or any public/unauthenticated RPC/endpoint
- Server actions (verify auth check present)
- New database functions (privileged-execution / grant check)

---

## Step 1 — Gather context

- Run `git diff HEAD` or `git diff main..HEAD`
- Read AGENTS.md → routing table and access-policy strategy
- Note every file touching auth, middleware, or data access

---

## Step 2 — Spawn 3 review agents IN PARALLEL

Every finding is MUST FIX — no SUGGESTION tier.

### Pass 1 — Security & Auth (Sonnet)

- Auth checks only on the client that could be bypassed by a direct server request
- Server actions / handlers missing the project's auth + tenant guard
- Queries that could return another tenant's data if the tenant/owner param is omitted or swapped
- Unsanitized user input reaching DB queries, redirects, or logs
- Hardcoded secrets, API keys, or tokens in code
- Environment variables exposed to the client bundle (client-exposed/`NEXT_PUBLIC_`-style vars)
- Redirect targets built from user input — use only a resolved pathname, never raw query/hash
- Public-path allowlist additions that still sit behind a route-group/layout auth gate (gate still fires)

### Pass 2 — Data Boundary Integrity (Sonnet)

- Backend/data-store SDK called outside the project's data-access layer — only that layer may touch it
- Public/unauthenticated RPC or endpoint: enforce a security allowlist — no sensitive fields (internal ids,
  tokens, timestamps, contact/PII fields) exposed beyond the documented allowlist
- Every mutation in the data-access layer takes the tenant/owner scope as an argument and uses it in the query
- New tables/resources: access policies enabled and scoped to the tenant/owner
- New database functions: privileged execution revoked from public where not intended
- Privileged (definer-rights) functions: only the intended public access, no blanket exposure

### Pass 3 — Backend Security Checklist (Sonnet) — via the project's DB-safety adapter

The harness does not hardcode a backend. Invoke **this project's database-safety skill** (its backend
adapter, named in the project's config) and run its security checklist against the diff. That adapter owns
the backend-specific form of these universal classes:

- Privilege escalation via user-controlled metadata used in authorization decisions
- Auth-claim staleness used in authorization without accounting for token refresh
- User deletion without session/credential revocation
- Service-role / admin secret reachable from client code or client-exposed env vars
- Policy bypass: views or owner-rights that read around row-level access controls
- Missing companion policies (e.g. an UPDATE policy with no matching SELECT — silent no-op)
- Privileged functions in an exposed namespace without an explicit execution revoke
- Storage/object access policies incomplete for upload flows (e.g. INSERT without SELECT/UPDATE)

If the project declares no DB-safety adapter and the diff touches the database, that is a MUST FIX routing
gap (see the routing-assertion gate) — surface it.

---

## Step 3 — Auto-fix (Opus)

Compile all MUST FIX → spawn one Opus agent.
Fix only the listed items. Minimum changes.
Flag NEEDS HUMAN if fix requires architectural redesign or intent is ambiguous.

After fixes: run the project's test suite (e.g. `npx vitest run`). Surface failures without retry.

---

## Step 4 — Surface NEEDS HUMAN items

Every unresolved item must be addressed before the commit lands.
