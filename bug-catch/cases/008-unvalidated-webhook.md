---
id: "008"
category: validation
severity: high
holdout: false
bug: The external webhook body is parsed and its fields used to mutate orders with no schema validation and no signature/authenticity check — arbitrary external input is trusted across a trust boundary.
catch: A finding that the external/webhook input is unvalidated (no schema) and/or unauthenticated (no signature check) before being used to mutate data.
---

```ts
// POST /api/webhook
export async function handleWebhook(req: Request) {
  const payload = JSON.parse(req.body)
  await orders.updateStatus(payload.orderId, payload.status)
  return { ok: true }
}
```
