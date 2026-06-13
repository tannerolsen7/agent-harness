---
id: "005"
category: security
severity: critical
holdout: false
bug: The user-supplied `term` is interpolated directly into the SQL string — a SQL injection. It must be a parameterized/bound query.
catch: A finding that user input is interpolated into the SQL string (injection) and should be parameterized.
---

```ts
export async function searchUsers(term: string) {
  return db.query(`SELECT id, name FROM users WHERE name LIKE '%${term}%'`)
}
```
