---
id: "004"
category: money
severity: high
holdout: false
bug: Tax is applied with floating-point multiplication on integer cents, producing fractional cents and float rounding error; money must use integer-cents arithmetic with explicit rounding.
catch: A finding that money is computed with floating-point math producing fractional/rounding-unsafe cents (no integer rounding / not exact).
---

```ts
export function totalCents(items: { priceCents: number; qty: number }[]): number {
  return items.reduce((sum, i) => sum + i.priceCents * i.qty * 1.0825, 0)
}
```
