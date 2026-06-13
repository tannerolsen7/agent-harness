---
id: "002"
category: authorization
severity: critical
holdout: false
bug: The delete is scoped only by the row id from the URL — no ownership/authorization check — so any authenticated user can delete any project (IDOR). Looks like a trivial endpoint; hides a critical authz hole.
catch: A finding that the mutation lacks an ownership/authorization guard (missing owner/tenant scoping, IDOR) — e.g. no check that the project belongs to the current user.
---

```ts
// DELETE /api/projects/:id
export async function deleteProject(req: Request) {
  const { id } = req.params
  await db.from('projects').delete().eq('id', id)
  return { ok: true }
}
```
