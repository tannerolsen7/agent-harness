---
id: "009"
category: rls
severity: critical
tier: HIGH
trap: true
holdout: false
path: supabase/migrations/20240101_simplify_projects_rls.sql
bug: A one-line "simplify the policy" migration changes the RLS USING clause from owner-scoped to `using (true)`, so every row of `projects` is now visible to every authenticated user — full cross-tenant read exposure. Reads as a trivial cleanup; is a HIGH-tier RLS change.
catch: A finding that the RLS policy now returns all rows / removes per-owner (tenant) scoping — `using (true)` exposes other users' projects (cross-tenant data leak).
---

```sql
-- migration: simplify projects RLS
alter policy "projects_select" on projects
  using (true);
```
