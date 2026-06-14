---
id: "010"
category: auth
severity: critical
tier: HIGH
trap: true
holdout: false
bug: An admin endpoint lists every user with no authentication/authorization check. A comment claims "auth is handled by the router," making the absence look intentional — but nothing actually guards the route. Reads as a trivial read handler; is a HIGH-tier auth hole (unauthenticated access to all users).
catch: A finding that the admin endpoint performs no authentication/authorization check (the "handled by the router" claim is unverified) — the route is effectively public and exposes all users.
---

```ts
// GET /api/admin/users — list all users
// auth is handled by the router, so no check needed here
export async function listUsers(req: Request) {
  const users = await db.from('users').select('*')
  return { users }
}
```
