---
id: "003"
category: correctness
severity: high
holdout: false
bug: `find` returns undefined when no contact is marked primary, so `contact.email` throws at runtime; the unguarded dereference is the bug.
catch: A finding that `contact` can be undefined (Array.find returns undefined) and is dereferenced without a guard.
---

```ts
export function primaryEmail(user: User): string {
  const contact = user.contacts.find(c => c.primary)
  return contact.email.toLowerCase()
}
```
