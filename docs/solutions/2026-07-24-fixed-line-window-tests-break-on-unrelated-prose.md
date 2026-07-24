# Problem: tests that grep a fixed-line window around a heading break when unrelated prose grows

**Problem class:** A test asserts on markdown/prose content by grabbing a fixed number of
lines after a heading and grepping inside that window. The window is really a snapshot of
the document's length at the moment the test was written, not a boundary tied to the
document's structure — so any unrelated edit that adds lines above the target section
silently pushes the target content out of the window and fails the test with zero actual
regression in the thing being tested.

## When this bites you

You write a test for a skill/agent prompt file (`.claude/skills/*/SKILL.md`,
`.claude/agents/*.md`) that needs to check specific phrases exist inside one section of a
long markdown file. The natural first instinct is `grep -A N` or `grep -B M -A N` anchored
on the section's heading:

```bash
grep -B2 -A15 "^### Pass 6" "$CR_SKILL" | grep -q "Test contradiction check"
```

This passes today. Then something unrelated happens — a routine `git merge origin/main`,
another PR that adds a paragraph earlier in the same file, a doc reorg that inserts a new
subsection above yours — and the section you're checking moves further down the file. The
fixed `-A15` window now ends before it reaches your content, or `-B2` starts capturing the
wrong heading's tail. The assertion fails. Nothing about the behavior you're testing
changed; the file just got longer somewhere else.

This is not hypothetical — it happened mid-session while building the `/cr` Pass 6 test
contradiction check (`tests/cr-test-contradiction-pass.test.sh`). `/cr`'s pre-flight
merge-readiness check required syncing the feature branch with `origin/main` (21 commits,
merge commit `ef077eb`). That merge added unrelated prose above the target section in
`.claude/skills/cr/SKILL.md`. The test, at that point still using a fixed-line-window
`grep -A`/`-B`, went from green to one assertion red — with the actual Pass 6 instruction
text completely intact and correct.

## Root cause

`grep -A N` / `-B M` counts lines, not structure. The number `N` is implicitly "how long I
expect this section to be, based on what it looks like right now." That number is coupled
to everything above and inside the section at the time you wrote the test — including
content that has nothing to do with what you're checking. Any of the following can silently
invalidate the window without changing the section itself:

- A merge or rebase that adds content earlier in the file.
- Another contributor inserting a new subsection above yours.
- Someone reflowing a paragraph in your own section to be longer, pushing the closing
  boundary past `N`.

The test file's own comment (before the fix) is the tell: if you find yourself writing "how
many lines does this section run for," you've hard-coded a snapshot instead of a boundary.

## The fix

Extract the section by its actual structural boundary — the next heading at the same or
higher level — using `awk`, not a fixed line count:

```bash
# Before — fixed-line window, breaks when content above the heading grows:
grep -B2 -A15 "^### Pass 6" "$CR_SKILL" | grep -q "Test contradiction check"
grep -B2 -A40 "^## Phase 3" "$BC_SKILL" | grep -qi "Pass 6"

# After — structural boundary, tracks the document regardless of what's above it:
PASS_6_BLOCK=$(awk '/^### Pass 6 /{p=1} /^### Pass 7 /{p=0} p' "$CR_SKILL")
PHASE_3_BLOCK=$(awk '/^## Phase 3 /{p=1} /^## Phase 4 /{p=0} p' "$BC_SKILL")

[ -n "$PASS_6_BLOCK" ]   # fails loudly if the heading itself ever gets renamed/moved
[ -n "$PHASE_3_BLOCK" ]

echo "$PASS_6_BLOCK" | grep -q "Test contradiction check"
echo "$PHASE_3_BLOCK" | grep -qi "Pass 6"
```

The `awk` pattern turns a print flag on at the start heading and off at the next heading of
the same level (`p=1` / `p=0`), printing every line in between (`p`). It has no opinion
about how long the section is — it only cares where the section starts and ends. Content
added anywhere else in the file, above or below, cannot affect the extracted block.

Two details that matter when applying this:

- Anchor on the *next* heading at the same level, not just "the next heading." If Pass 6
  contains subheadings (`####`), stopping at the first `#### `-anything would truncate the
  section. Match the level you actually want the boundary at (`### Pass 7` for a `###`
  section, `## Phase 4` for a `##` section).
- Assert the extracted block is non-empty (`[ -n "$BLOCK" ]`) before grepping inside it. If
  the heading text itself ever changes (renamed, reordered, removed), an empty block would
  otherwise make every subsequent `grep -q` on it silently fail for the wrong reason — you
  want the test to say "couldn't find the section" instead of "phrase missing."

## When to reuse this

Any test that asserts on a specific section of a markdown or prose file — skill prompts,
agent definitions, docs — instead of on executable behavior. This repo has at least three:
`tests/harness-smoke.test.sh`, `tests/queue-design-gate.test.sh`, and
`tests/cr-test-contradiction-pass.test.sh`. Any new test in this shape should extract by
heading-to-next-heading boundary from the start, not `grep -A`/`-B` with a guessed line
count — don't wait to hit the same failure to learn it.

The same principle generalizes past `awk`/bash: any assertion that locates content by "N
lines/tokens/chars from an anchor" instead of "from this boundary to that boundary" has the
same failure mode. If the file the test reads is one a human or another agent is likely to
edit above your target section — which is true of almost every shared markdown file in an
actively developed repo — prefer the structural boundary every time, even if the fixed
window would be a couple of lines shorter to write.

## Related: don't let a doc's cross-reference claim wider scope than the code

A secondary issue surfaced in the same PR, worth flagging because it's a different failure
mode with the same root shape (a claim that isn't actually checked against the thing it
describes). The first draft of the `/behavior-change` Phase 3 cross-reference claimed `/cr`
Pass 6 runs "this same contradiction check" as Phase 3. An adversarial review (four parallel
lenses — cascade, abuse, composition, assumption — see `.claude/agents/reviewer.md`)
independently converged on the same finding: Pass 6 only scans files/shards a diff already
touches, while Phase 3 sweeps the whole test suite via a callsite search. Those are
different scopes, not the same check running twice.

The fix was to narrow the doc's claim ("partial backstop, narrower coverage") rather than
widen Pass 6 to match Phase 3's sweep — a separate devil's-advocate review pass had already
endorsed Pass 6's bounded scope as the right cost/thoroughness tradeoff for a check that
runs on every push. When one skill or doc describes another as covering "the same" ground,
verify the actual scope matches before shipping the claim — an overclaimed backstop is worse
than no backstop, because it teaches readers to skip the wider check.

## Files changed

- `tests/cr-test-contradiction-pass.test.sh` — `awk` section extraction (`PASS_6_BLOCK`,
  `PHASE_3_BLOCK`) instead of `grep -A`/`-B`
- `.claude/skills/cr/SKILL.md` — Pass 6 "Test contradiction check" item
- `.claude/skills/behavior-change/SKILL.md` — Phase 3 cross-reference to the Pass 6 backstop,
  scoped correctly after review
- `docs/testing/cr-test-contradiction-pass.md` — confirmed-behavior shard for both checks

**Tags:** testing, markdown-assertions, grep, awk, fixed-line-window, structural-boundary,
false-positive, merge-induced-breakage, scope-overclaim, adversarial-review
