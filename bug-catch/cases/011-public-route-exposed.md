---
id: "011"
category: access-control
severity: critical
tier: HIGH
trap: true
holdout: true
bug: The auth middleware's matcher uses a negative-lookahead exclusion list that quietly includes `admin`, so the middleware never runs on `/admin/*` and those routes become publicly reachable. Reads as a routine "exclude static/internal paths" config tweak; is a HIGH-tier public-exposure change.
catch: A finding that `admin` is in the middleware matcher's exclusion (negative lookahead), so the auth middleware does not run on `/admin/*` — admin routes are unauthenticated/public.
---

```ts
// middleware.ts — run auth on every route except static + internal paths
export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|admin).*)'],
}
```
