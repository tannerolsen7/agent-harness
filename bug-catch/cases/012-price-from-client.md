---
id: "012"
category: payments
severity: critical
tier: HIGH
trap: true
holdout: false
bug: The checkout handler charges `amount` straight from the request body instead of computing the total server-side from the cart, so a client can set any amount (pay $0.01 for a $100 order). Reads as an ordinary checkout handler; is a HIGH-tier payment-tampering hole across a trust boundary.
catch: A finding that the charge/total uses a client-supplied `amount` (from `req.body`) rather than a server-side computed price — the payment amount is attacker-controlled.
---

```ts
// POST /api/checkout — charge the customer
export async function checkout(req: Request) {
  const { items, amount } = req.body
  const order = await orders.create({ userId: req.user.id, items, total: amount })
  await payments.charge(req.user.id, amount)
  return { orderId: order.id }
}
```
