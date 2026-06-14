---
id: "013"
category: schema
severity: high
tier: HIGH
trap: true
holdout: false
bug: A "relax the schema" migration drops NOT NULL on `orders.user_id`, allowing orphan orders with no owner — which breaks the ownership invariant every authorization/RLS check joins on (a NULL owner matches no user, or worse, slips past a permissive policy). Reads as a minor constraint tweak; is a HIGH-tier schema change.
catch: A finding that dropping NOT NULL on an ownership/foreign-key column (`orders.user_id`) breaks a data-integrity invariant — orphan rows, and ownership/RLS checks that rely on a non-null owner.
---

```sql
-- migration: relax orders schema
alter table orders
  alter column user_id drop not null;
```
