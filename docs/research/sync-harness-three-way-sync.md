<!-- context-meta
owner: tanner
last-reviewed: 2026-06-22
review-frequency: on-merge
expires: 2026-07-22
expiry-note: Expires 30 days from filing, OR when scripts/sync-harness.sh changes its comparison or restore logic, whichever comes first.
-->

# Spike — sha256-manifest three-way sync correctness

**Filed:** 2026-06-22
**Spike pipeline:** /spike (three research passes + synthesis + two verifiers + TDD slice)

---

## The question

Does the harness's sha256-manifest three-way sync mechanic correctly preserve
user-edited files on update across all comparison cases — to decide whether we
can ship the `scripts/sync-harness.sh` update flow as the default upgrade path
without a manual review step?

**The mechanic in plain terms:** at install, the harness saves a sha256
fingerprint of each harness-owned file into a manifest. On update, sync compares
three fingerprints per file — the local file now, the fingerprint saved at
install (the baseline), and the upstream source file. From those three it
decides: file unchanged, safe to update, a user customization to leave alone,
or a real conflict.

---

## Recommendation and confidence

**Recommendation:** The core five-case comparison mechanic is correct and safe to
auto-run. It must NOT ship as the default no-review upgrade path until gap **G1**
(a deleted `deploy-targets.yml` is silently not restored while sync exits 0) is
fixed. The mechanic is sound; one create-once file is wired inconsistently, and
the failure is silent.

**Confidence: Open.** The core mechanic is well-supported (Leaning-grade
evidence: sources converge, the adversarial verifier could not break the
five-case ordering, the baseline-advance and empty-hash guards are confirmed
correct). But the verifiers found a material gap and the TDD slice **failed** on
it, so the recommendation as stated ("ship as default, no manual review") cannot
stand without the fix. A failed slice drops the tier one step, landing at Open.

**Revised question (carry forward to the fix):** Before shipping sync as the
default no-review upgrade path, does adding a `deploy-targets.yml` case to
`template_for()` in `scripts/sync-harness.sh` make the failing test pass with no
regressions across all 31 assertions?

---

## Confirmed assumptions (what the research established)

- **All five canonical three-way comparison cases are present and correctly
  ordered** in `scripts/sync-harness.sh` lines 130-150. The elif order is:
  `local==old` first (all-equal and upstream-only-changed), then
  `local==upstream` (convergent), then `old==upstream` (user-only edit), then
  `else` (real conflict). The adversarial verifier proved no case can be
  shadowed: cases 2 and 3 both require `local != old`, and their predicates
  cannot both be true unless all three shas are equal (already caught earlier).
- **The convergent case is handled correctly** (line 139): when the user
  independently made the same edit as upstream, sync reports up-to-date and
  records the shared sha — no false conflict.
- **The baseline advances only on a clean, conflict-free run** (line 155 guard
  `[ -z "$conflicts" ]`). A conflicted file records the old baseline (line 149)
  and the manifest is not rewritten at all when any conflict exists. This
  matches chezmoi's "advance-only-on-write" design and prevents the
  stale-baseline bug class seen in gsd-build/get-shit-done #2424.
- **The empty-hash risk is closed** by `file_sha()` (lines 39-45): it returns
  exit 1 if neither `sha256sum` nor `shasum` produces a hash, and `set -euo
  pipefail` aborts. Two broken files cannot silently compare as equal.
- **Both prior PITFALLS for this code are fixed:** the user-only-edit branch is
  present (line 142) and now has a dedicated test (`tests/install.test.sh`
  lines 157-163); `mktemp` uses the portable `XXXXXX` template form, not `-p`
  (line 162).
- **Whole-file sha comparison is conservative-but-safe.** Because it compares
  whole-file shas (not line-level merges), any file both the user and upstream
  changed becomes a conflict, even when the edits are in different sections.
  This produces more false-positive conflicts than a line-merge but ZERO
  false-negative silent-wrong-merges. For hook scripts, agent definitions, and
  policy docs, a silently wrong file is far more dangerous than a manual-resolve
  prompt, so this is the correct tradeoff (Pass 2; revctrl.org AccidentalCleanMerge).

## Failed assumptions (what the research disproved)

- **DISPROVED: "every deleted create-once file is restored from its template."**
  `install.sh` records `deploy-targets.yml` as create-once (line 67), but
  `template_for()` in `sync-harness.sh` (lines 65-73) has no case for it. A
  deleted `deploy-targets.yml` is silently not restored; sync prints "skipped
  (create-once, no template)" and exits 0. A deleted `CLAUDE.md` IS restored.
  This is **gap G1**, confirmed false by the TDD slice. The template file
  `docs/templates/deploy-targets.yml` exists, so the fix is a one-line
  `template_for()` case plus the regression test the slice added.
- **DISPROVED: "exit non-zero on conflict makes auto-sync safe with no manual
  review."** There are exit-0 paths that silently skip needed work: G1 above,
  and the "source gone" skip (lines 121-124) which silently keeps an old file
  forever and never self-heals. The "exit non-zero" net only protects users who
  wire sync into CI — not the engineer who runs sync by hand and reads only the
  last line ("sync: complete").

## Open risks surfaced by verifiers (not yet disproved, worth tracking)

- **Empty-sha-in-manifest risk (adversarial, significant).** `record_sha "$rel"
  "$(file_sha "$srcf")"` (line 77 pattern): under bash, `set -e` does not
  reliably propagate through a command substitution used as a function argument.
  If `file_sha` returns 1, `record_sha` could write `""` as the sha. On the next
  run, an empty baseline sha produces a spurious permanent conflict for that
  file. Not reproduced by the slice; flagged for the fix to harden.
- **G2 — one conflict blocks the manifest advance for ALL files in the run**
  (line 155 guard). Correct (no data loss) but undocumented and confusing on
  re-run. A one-line comment closes it.
- **Path-traversal guard bypass for a bare `..` entry** (line 87 pattern
  requires a slash after `..`). Low probability (needs a crafted manifest), no
  data loss, but a guard hole.
- **`json_escape` does not escape newlines/tabs** (line 46). Low probability,
  would corrupt the rewritten manifest rather than lose data (the next run's
  jq-corruption check catches it).

---

## The slice result

**Test added:** `tests/install.test.sh`, block
`── sync: re-creates a deleted create-once deploy-targets.yml ──` (final `ck`).
It installs into a fresh target, deletes `deploy-targets.yml`, runs sync, and
asserts the file exists again (the same invariant the `CLAUDE.md` re-create test
asserts).

**Result: FAILS.**
```
── sync: re-creates a deleted create-once deploy-targets.yml ──
  MISS: deleted create-once deploy-targets.yml re-created from template on sync
install: 30 passed, 1 failed
```

A failing test here is the proof that G1 is real. PASS would have confirmed the
restore covers `deploy-targets.yml`; FAIL confirms it does not and sync exits 0
anyway. All 30 prior assertions still pass, so the test isolates exactly this gap.

**Next step:** `/debug` with the failing test, or apply the one-line
`template_for()` fix under `/feature` and let the new test gate it.

---

## User stakes (from the user verifier)

The "user" is an engineer who installed the harness into their own repo. Ranked
by user-felt pain:

1. **G1 (worst):** the engineer fills in `deploy-targets.yml` with real deploy
   steps, it gets deleted (bad merge, accidental `rm`), they run sync expecting
   the scaffold back, and get exit 0 with no warning and no file. Per CONTEXT.md,
   a missing manifest makes the deploy-drift gate pass silently — so the engineer
   loses a CI safety gate and does not know it.
2. **G2:** confusing-but-safe re-runs after a conflict; wastes time, erodes trust,
   no data loss.
3. **G3:** stale PITFALLS doc note; minor.

---

## Full citation list

External (Pass 1 / Pass 2):
- Debian Policy Manual — Configuration file handling (conffiles). https://www.debian.org/doc/debian-policy/ap-pkg-conffiles.html
- Debian Wiki — DpkgConffileHandling. https://wiki.debian.org/DpkgConffileHandling
- Hertzog, Raphaël — "Everything you need to know about conffiles," 2010. https://raphaelhertzog.com/2010/09/21/debian-conffile-configuration-file-managed-by-dpkg/
- Debian Wiki — Teams/Dpkg/Spec/ConffileDatabase. https://wiki.debian.org/Teams/Dpkg/Spec/ConffileDatabase
- RPM %config and %config(noreplace) — Cambridge (J. W. Thum). https://www.cl.cam.ac.uk/~jw35/docs/rpm_config.html
- Maximum RPM, Chapter 4 — Using RPM to Upgrade Packages. https://book.huihoo.com/maximum-rpm/ch-rpm-upgrade.html
- chezmoi — Architecture. https://www.chezmoi.io/developer-guide/architecture/
- chezmoi — apply reference. https://www.chezmoi.io/reference/commands/apply/
- chezmoi issue #1066 (baseline / "all files modified"). https://github.com/twpayne/chezmoi/issues/1066
- copier — Updating a project. https://copier.readthedocs.io/en/stable/updating/
- copier issue #1735 (deleted files no longer update). https://github.com/copier-org/copier/issues/1735
- copier issue #943 (.rej file inverted). https://github.com/copier-org/copier/issues/943
- Yeoman — Working With The File System. https://yeoman.io/authoring/file-system
- yeoman/generator issue #966 (conflict resolution default). https://github.com/yeoman/generator/issues/966
- Homebrew — Formula Cookbook. https://docs.brew.sh/Formula-Cookbook
- Red Hat Developer — "What is an image mode 3-way merge?", 2025-08-25. https://developers.redhat.com/articles/2025/08/25/what-image-mode-3-way-merge
- Wikipedia — Merge (version control). https://en.wikipedia.org/wiki/Merge_(version_control)
- Coglan, James — "Merging with diff3," 2017. https://blog.jcoglan.com/2017/05/08/merging-with-diff3/
- revctrl.org — ThreeWayMerge. https://tonyg.github.io/revctrl.org/ThreeWayMerge.html
- revctrl.org — AccidentalCleanMerge. https://tonyg.github.io/revctrl.org/AccidentalCleanMerge.html
- Sink, Eric — "Chapter 3: File Merge." https://ericsink.com/scm/scm_file_merge.html
- gsd-build/get-shit-done issue #2424 (stale baseline → false conflicts). https://github.com/gsd-build/get-shit-done/issues/2424
- anthropics/claude-code issue #27941 (stale-write proceeded → overwrote edits). https://github.com/anthropics/claude-code/issues/27941
- "On the Methodology of Three-Way Structured Merge," Virginia Tech (JSA 2023). https://people.cs.vt.edu/~nm8247/publications/jsa23.pdf
- "When Git merge goes quietly wrong" — dev.to. (merge-base staleness / silent data loss)

Internal (Pass 3 / slice — file:line):
- `scripts/sync-harness.sh` — comparison block lines 130-150; convergent line 139; user-only line 142; baseline-advance guard line 155; conflicted-file sha line 149; `file_sha` empty-hash guard lines 39-45; `template_for` lines 65-73; portable mktemp line 162; `json_escape` line 46; path guard line 87; `record_sha` line 77.
- `scripts/install.sh` — `deploy-targets.yml` as create-once line 67; manifest mktemp line 131.
- `tests/install.test.sh` — user-only-edit test lines 157-163; CLAUDE.md re-create test ~lines 118-123; NEW failing deploy-targets.yml re-create test (block `── sync: re-creates a deleted create-once deploy-targets.yml ──`).
- `docs/templates/deploy-targets.yml` — the missing template target exists (34 lines).
- `PITFALLS.md` — five-cases-not-four entry (lines 290-304); mktemp -p entry (lines 273-287); stale "tested implicitly" note (lines 300-303).
