# Problem: A Tool That Grants Itself Its Own Review Sentinel

**Problem class:** An automated tool sits in front of a human review gate. Rather than always stopping at the gate, the tool tries to prove — using its own logic, against its own inputs — that this one case is safe enough to skip the human and pass the gate itself. The narrower and more "provable" the skip condition looks, the more tempting this is. It is still wrong, because the tool is both the one deciding the case is safe and the one certifying that it checked.

## When this bites you

You are building an automated tool that sits in front of a gate meant for humans — a merge bot, a deploy script, an auto-approve rule, anything that normally requires a person to sign off before something ships. The tool can already tell, in the common case, whether its own proposed action is safe: "this file only changed in a way our merge driver already resolves," "this diff only touches generated files," "this migration is additive-only." Since the tool can already prove the safe case, it seems wasteful to make a human re-check it. So the tool is given the power to satisfy the gate itself, but only when its proof condition holds.

This repo hit exactly this shape in `feat/cr-merge-sync`. `scripts/sync-open-prs.sh` runs at every Claude Code session start to check open GitHub pull requests that GitHub marks `mergeable: CONFLICTING`. The underlying bug: GitHub's server-side merge check can't run this repo's local `.gitattributes` merge drivers (`merge=ours`, `merge=union`, and a custom `tasks-higher-state` driver registered in `.git/config`), so a PR that would merge cleanly on a developer's machine shows as falsely conflicting on GitHub.

The first fix (commit `7ec1703`) did a real local merge in a scratch worktree, then — if `scripts/check-merge-driver-coverage.sh` could prove the merge only touched files covered by a registered `.gitattributes` merge strategy — wrote `.claude/.cr-ok` itself and pushed. `.cr-ok` is the sentinel `.husky/pre-push` checks as proof that `/cr` (this repo's code-review skill) reviewed the push before it goes out. The tool was not skipping the gate outright; it was satisfying the gate's exact proof condition, scoped to a case it believed it could verify. That framing — "the proof is narrow, so self-issuing is safe" — is the trap.

## Root cause

A review gate exists because one party (the reviewer) checks work produced by a different party (the author), and the gate's whole value is that those two parties are not the same. The moment the author can also produce the reviewer's signoff, the gate stops checking anything — it just checks that the author ran the self-signoff code path, which the author always can.

Two things make this worse than it looks at first glance, and both were true here:

1. **The self-issued credential is byte-identical to a real one.** `.husky/pre-push` reads `.claude/.cr-ok` and cannot tell "a human ran `/cr` and it passed" from "the script decided its own proof condition was met and wrote the file." Nothing about the file's shape, location, or the code path that wrote it carries any information about which happened. Anyone auditing later — or the hook itself — has no way to tell the difference.

2. **The "narrow, provable" condition is not actually independent of the thing it's certifying.** The proof here was: does `git check-attr` say every file the merge had to decide between has a registered merge strategy? The first version of `check-merge-driver-coverage.sh` called `git check-attr --stdin merge` with no `--source` flag, which reads `.gitattributes` from whatever is checked out in the current working tree — and that tree, at the point the check runs, is the state *after* the merge already applied (see `scripts/check-merge-driver-coverage.sh:1-11`, comment: "Reading the merged tree would let `<ref-untrusted>` grant itself coverage by adding its own `.gitattributes` entry in the same change"). A PR branch could add a line to `.gitattributes` (say, `sensitive-file merge=union`) in the very same PR that edits `sensitive-file`. By the time the coverage check runs, that attribute is present in the merged tree, so the check reports the file "covered" — even though nobody except the PR's own author ever declared it safe. This was reproduced by hand: a fake attacker branch that grants itself `merge=union` on a file main also touches, containing a planted `BACKDOOR=injected` line, made the old (no-`--source`) code print `sensitive.txt: merge: union` — falsely covered — while a `--source=<trusted-base-ref>` version correctly reported it `unspecified`/uncovered.

The general shape: whenever the "proof" a self-certifying tool relies on is computed from a value the same untrusted input can influence, the proof is not independent of the thing under review. It only looks independent because it is expressed as code instead of a person's judgment.

Two more findings from the same review round out why this fails even when the proof condition is airtight:
- **No fork/cross-repo filtering existed on the PR list.** Before this was added, an external contributor's PR — with a `.gitattributes` and file contents nobody at this project reviewed — could trigger an auto-merge-and-push using the project's own automation credentials.
- **A bad auto-push has no audit trail and can cascade.** `sync-open-prs.sh` is designed to always exit 0 (it runs from a session-start hook and must never block it — see `scripts/sync-open-prs.sh:1-3`), so a wrong self-certified push doesn't even fail loudly; it can go straight onto the default branch via GitHub auto-merge with nothing flagging it for a human to catch.

## The fix

Drop the self-issued sentinel and the auto-push entirely (commit `0457a2e`, "fix(cr-merge-sync): drop self-issue and auto-push post-review"). The script now only diagnoses:

- It reports whether GitHub's `CONFLICTING` status reflects a real content conflict (needs a human to resolve it) or is a false positive (the local merge drivers already resolve it, and a human just needs to run the push).
- It prints the exact commands for a human to run (`scripts/sync-open-prs.sh:112`, `:121`, `:125`) — it never runs `git push` itself.
- The scratch worktree checkout changed from `git worktree add -B "$head" ...` to `git worktree add --detach ...` (`scripts/sync-open-prs.sh:94-97`). `-B` force-resets or creates a local branch named `$head`; if a human had unpushed work on a same-named local branch that wasn't checked out anywhere (so the earlier "checked out elsewhere" guard wouldn't have caught it), `-B` would silently clobber it. `--detach` never touches a named branch ref at all, so this collision risk is gone regardless of what the coverage check decides.

`check-merge-driver-coverage.sh` was hardened independently of the self-issue question, because the coverage proof itself needed fixing regardless of who acts on it:

- **Trust source, not merged state.** `git check-attr --source="$REF_TRUSTED" --stdin merge` (`scripts/check-merge-driver-coverage.sh:48`) resolves `.gitattributes` from the trusted base ref, never from the merged working tree. The function signature itself now documents this: `check-merge-driver-coverage.sh <merge-base> <ref-untrusted> <ref-trusted>` (`scripts/check-merge-driver-coverage.sh:5`), with `<ref-trusted>` explicitly required to be the base/main side (`scripts/check-merge-driver-coverage.sh:7`) — the parameter name makes the trust direction a type, not a convention someone has to remember.
- **Allow-list of strategy names, not "whatever git reports."** Only `union`, `ours`, and `tasks-higher-state` count as covered (`scripts/check-merge-driver-coverage.sh:54-67`). Anything else is uncovered, full stop.
- **Verify custom drivers are actually registered**, not just named in an attribute. For `ours` and `tasks-higher-state`, the script checks `git config --get "merge.${strategy}.driver"` is non-empty before trusting the attribute (`scripts/check-merge-driver-coverage.sh:57-61`) — an attribute naming an unregistered driver is treated as uncovered, because the resolution it claims may never actually run.

See `docs/testing/cr-merge-sync.md` for the full list of confirmed behaviors this produced, and `TASK-TEMPLATE.md`'s post-review addendum (top of file) for the record of what was approved in design versus what actually shipped — they differ on exactly this point.

## Why diagnose-and-report is the correct default

- **A review gate's value comes from separation, not from the quality of any one check.** Once the entity being reviewed can also mint the "reviewed" credential, the check no longer separates anything — it is one program calling into another program it also wrote.
- **"Scoped" and "provably safe" do not fix this.** The scope of a self-certification only matters if the proof it relies on is truly independent of the input under review. Here it looked independent (a `.gitattributes` lookup) but was actually reading state the same input had already influenced. Any self-certification scheme has to answer "where does the proof's data come from, and can the thing being certified change that data?" — and for a merge, the merged tree always can.
- **Diagnosis has no failure mode that reaches production.** A tool that only reports "here is the exact command to run" cannot itself push a bad change; the worst case is a wrong recommendation a human still has to act on. A tool that self-certifies and pushes has a failure mode that lands directly on the default branch with the same audit trail as the false case: none, because both looked like "the gate passed."
- **The narrow exception to this rule is verifiable provenance, not narrow scope.** Self-certification is only safe if the gate can independently verify *who or what* produced the credential — for example, a signed attestation tied to a specific reviewed commit SHA that the gate itself validates, not just checks for the file's existence. `.cr-ok` in this repo carries no such provenance: it's a bare file whose presence alone satisfies `.husky/pre-push`, so anything that can write to the worktree can produce it. Until the credential itself can prove who issued it, the default is: diagnose and report, never self-issue.

## What doesn't work

**Self-issuing the review sentinel, scoped to a "provably safe" condition:**
- Indistinguishable from a real review to the gate that checks it (`.husky/pre-push` cannot tell a self-issued `.claude/.cr-ok` from one a human produced by actually running `/cr`).
- The proof condition itself can be computed from attacker-influenced state if it's read from anything downstream of the input under review (the merged tree) instead of a value fixed before that input was ever considered (the trusted base ref, pinned by `--source`).
- Removes the one thing that makes an auto-push tolerable — a human audit trail — at exactly the moment a bad push needs one most.
- This is a different failure than the rebase-vs-merge question this same script also had to answer. That question — should an automated tool use `git rebase` or `git merge` to sync a branch — is already covered by `docs/solutions/2026-06-24-auto-merge-as-sync-strategy-for-automated-tools.md`, and this design correctly followed that guidance (`git merge` + abort-on-conflict, never rebase) throughout every version of this script, including the first, unsafe one. Getting the sync mechanism right and getting the self-certification question right are independent decisions; this repo's history shows a design can get the first one right on the first try and still get the second one wrong.

**Skipping the hook entirely (`git push --no-verify`):**
- Considered and rejected during design (see `TASK-TEMPLATE.md`'s Open Questions section, option 2). Bypasses every other check the hook runs, not just the one this feature cares about — strictly worse than a scoped self-issue, and was rejected for that reason before the self-issue approach was tried and also rejected.

**Trusting `git check-attr` without specifying `--source`:**
- Defaults to reading `.gitattributes` from the current working tree. Inside a scratch worktree where a merge has already been applied, "current working tree" means "the merged result," which the untrusted side of the merge helped produce. Always pin the source to a ref fixed before the untrusted input is considered.

## Tags

trust-boundary, self-certification, review-gate, sentinel, cr-ok, pre-push, git-check-attr, merge-driver, security-review, automated-tool, audit-trail, provenance, PITFALLS
