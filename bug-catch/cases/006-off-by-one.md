---
id: "006"
category: correctness
severity: medium
holdout: false
bug: The loop condition `i <= arr.length` reads one index past the end (pushes `undefined`); it should be `i < arr.length`. (A negative start when `n > arr.length` is a secondary flaw.)
catch: A finding of the off-by-one — `i <= arr.length` accesses index `arr.length` (out-of-bounds, undefined) — or the equivalent boundary error.
---

```ts
export function lastNItems<T>(arr: T[], n: number): T[] {
  const out: T[] = []
  for (let i = arr.length - n; i <= arr.length; i++) {
    out.push(arr[i])
  }
  return out
}
```
