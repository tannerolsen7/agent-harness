---
id: "007"
category: concurrency
severity: high
holdout: true
bug: The `db.posts.update` write is not awaited, so the function returns success (and notifies subscribers) before the write is confirmed; a failed or late update is silently lost, and the rejection is unhandled.
catch: A finding that the `db.posts.update(...)` call is not awaited (fire-and-forget write — returns before persisted / unhandled promise rejection / race).
---

```ts
export async function publish(postId: string) {
  const post = await db.posts.get(postId)
  validate(post)
  db.posts.update(postId, { status: 'published', publishedAt: now() })
  await notifySubscribers(post)
  return { status: 'published' }
}
```
