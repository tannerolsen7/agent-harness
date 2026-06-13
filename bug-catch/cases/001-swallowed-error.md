---
id: "001"
category: error-handling
severity: high
holdout: false
bug: The catch block swallows the error and returns an empty object cast as Settings, so a failed fetch looks like "no settings" and the `as Settings` hides missing required fields downstream.
catch: A finding that the error is caught and discarded (swallowed) and/or that `{} as Settings` masks a failure as valid data.
---

```ts
export async function loadSettings(orgId: string): Promise<Settings> {
  try {
    return await api.fetchSettings(orgId)
  } catch {
    return {} as Settings
  }
}
```
