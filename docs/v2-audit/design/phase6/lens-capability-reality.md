# Phase 6 Lens — CAPABILITY-REALITY

**Charge:** Attack one failure class across the whole integrated V2 design (Phases 3+4+5): *does the design
assume only capabilities that actually exist?* Re-verify every load-bearing capability claim against
`capability-facts.md` AND disk/official-docs. Flag over-claims; rank by how load-bearing.

**Method:** Read the authoritative corpus (both RECONCILIATION files, the three Phase-3 drafts' conclusions,
distribution.md, compounding-loop.md, MASTER-FINDINGS, capability-facts). Ground-truthed every load-bearing
claim on disk (settings.json, hooks/, .claude/rules absence, .gitignore, ci.yml, the live `vercel 0.43.0`
plugin) AND against the **current official Claude Code docs** (`code.claude.com/docs` — the canonical source
capability-facts cites as "claude-code-guide"). Audit artifacts rot; I re-verified rather than trusting.

**Verdict: CONCERNS.** The design is unusually disciplined on this axis — it pre-flagged its own
load-bearing capability risk (the Stop-hook signal-detection), gated it on an empirical check, and named a
degrade path. Most claims I attacked *survived re-verification on the live platform docs*, several
*strengthened*. But two claims are stated more confidently than the evidence supports, and one
disk-collision the design never mentions. None is fatal; all are fixable in prose before any build.

---

## What I attacked hardest, and what held

I spent the most effort trying to break **claim (c): `.claude/rules/` + `paths:` native lazy-load** — because
it is the single mechanism the *entire memory-model read-path* hangs on (S1 delivery, the PITFALLS-shard
split, MOVE 3, MOVE 6's read leg). If `paths:` lazy-load were a phantom, the memory model collapses to "a
custom loader we have to build," and budget (2) balloons.

**It held — authoritatively, and the design is *more* right than its own draft.** The current official
memory doc (`code.claude.com/docs/en/memory`) documents `.claude/rules/` with the `paths:` frontmatter field
verbatim, including:
- glob patterns (`src/api/**/*.ts`, brace expansion `{ts,tsx}`),
- "Rules without a `paths` field are loaded unconditionally and apply to all files" — **exactly** the
  RECONCILIATION §B.3 correction ("path-less shards load always; a shard with no glob doesn't auto-scope"),
- "Path-scoped rules trigger when Claude reads files matching the pattern, not on every tool use,"
- recursive `.md` discovery, symlink support, user-level `~/.claude/rules/`.

The §B.3 correction (shard only where a clean glob exists; path-less constraints go in always-load
`00-safety`) is **precisely** the platform's own guidance. This is the cleanest claim in the design. I could
not break it.

A secondary hard target — **claim (b): a plugin's `hooks.json` can wire hooks (incl. the Stop emitter)
without touching the project guard `settings.json`** — also held and **strengthened**. Ground-truth on the
live `vercel 0.43.0` plugin (re-located at `~/.claude/plugins/cache/claude-plugins-official/vercel/0.43.0/`):
- its `.claude/settings.json` is **27 bytes**: `{"enabledPlugins":{}}` — carries NO `agent`, NO
  `subagentStatusLine`, NO permissions block (Phase-4 C2 confirmed to the byte);
- it wires hooks via top-level `hooks/hooks.json` using `${CLAUDE_PLUGIN_ROOT}`;
- registers agents/commands via `.claude-plugin/plugin.json`.
- The official plugins-reference confirms a plugin `hooks.json` may declare **`Stop`** (line 131) and
  **`SubagentStop`** (line 128) as lifecycle events — so the design's Stop-emitter CAN ship as a plugin hook
  with zero edits to the downstream guard file. Phase 4's "the seam is forced" argument is correct.

---

## FINDINGS (ranked by how load-bearing)

### MUST-FIX

**MF-1 — The Stop-hook "see the corrected-mistake signal" risk is correctly flagged, but the capability
description in `capability-facts.md` and the memory model is imprecise in a way that hides the *real* work.**
*(compounding-loop.md §1; memory-model.md §6; capability-facts.md "Hooks" bullet 2; the design's #1
self-named load-bearing risk — RECONCILIATION-phase3 D2.)*

The design says the emitter needs only "append-and-allow-stop" (non-controversial) and gates "seeing the
signal" on a one-session empirical check. Both halves need sharpening against what the platform *actually*
hands a Stop hook, which I verified on the live docs:

- A Stop/SubagentStop hook receives **`transcript_path` — a path to the conversation JSON, NOT the content.**
  The hook gets `session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name`. To "see the
  turn's corrected-mistake signal" the hook must **(1) read and parse the transcript JSON file itself, then
  (2) run a detection heuristic over it.** capability-facts.md's "Stop hooks CAN run shell commands" is true
  but elides that *the signal is not handed to the hook* — it must be mined from a file the hook opens. The
  one-session empirical check is therefore not "can the hook see the signal" (it can always read the
  transcript) but **"can a deterministic script reliably detect 'a mistake was corrected this turn' from the
  transcript JSON without an LLM?"** That is the actual open question, and it is *harder* than the design
  frames it: a corrected-mistake signal is semantic, and a regex/keyword scan of a transcript is exactly the
  kind of forgeable, low-precision heuristic the harness elsewhere rejects. If detection needs an LLM pass,
  the "deterministic out-of-band writer" claim (Phase 5 §C's clean distinction between the deterministic
  Stop-hook writer and the model-executed `/cr` 3b writer) **partially collapses** — the Stop writer becomes
  "deterministic trigger + probabilistic detection."
- **Fix:** restate the load-bearing risk as I have it above (transcript is a path; detection is the hard
  part; detection may be non-deterministic). Keep the degrade path (`/cr` 3b + manual append). And narrow the
  one-session check's success criterion to: *"a script can read `transcript_path` and flag a correction with
  acceptable precision using only string/structural signals."* If it can't, the Stop writer is not the clean
  deterministic emitter Phase-5 §C claims — say so. This does not block the build (the degrade path is real
  and still better than today); it corrects an over-precise "deterministic writer" claim.

**MF-2 — The design never accounts for the EXISTING `Stop` hook on disk; the new emitter is described as if
the Stop slot is empty.** *(memory-model.md §6 / (ii) diagram; compounding-loop.md §1; disk:
`.claude/settings.json` `hooks.Stop`.)*

Ground-truth: `settings.json` **already wires a `Stop` hook today** — the Glass.aiff/`printf '\a'` sound
notification. The design's emitter (`session-end-capture.sh`) is a *second* Stop hook. Neither
compounding-loop.md nor memory-model.md mentions this (grep for `Glass.aiff`/`afplay`/`existing Stop` returns
nothing). Multiple Stop hooks *can* coexist (Claude Code runs all matching hooks for an event), so this is
not a blocker — but **the design has not verified the coexistence, and the distribution split makes it
load-bearing**: under Phase 4 the emitter ships as a *plugin* `hooks.json` Stop entry while the sound stays a
*project* settings.json Stop entry. The design must confirm (a) both fire, and (b) ordering/exit-code
interaction is benign (a non-zero exit from the sound hook must not suppress the capture hook, and the
capture hook must `exit 0` / never `decision:block` so it can't strand a turn). **Fix:** add one line to the
memory-model §6 mechanism and the distribution split table acknowledging the pre-existing project Stop hook
and asserting the new emitter is additive, exit-0-only, append-only.

### SHOULD-FIX

**SF-1 — `disable-model-invocation` "removes from context" (the `/cr-eval` budget-(1) fix) is a docs claim
with ZERO on-disk corroboration; the budget-(1)=0 result rests entirely on it.** *(phase45/RECONCILIATION §A
[REQUIRED]; capability-facts.md skill-frontmatter bullet; the lever that makes Phase-5 budget-(1)=0.)*

The field is real and documented: the official setup-skill reference
(`~/.claude/plugins/marketplaces/claude-plugins-official/.../skills-reference.md`) lists
`disable-model-invocation: true` → "Only user can invoke (for side effects)" and capability-facts tags it ✅.
**But:** I found **zero skills anywhere on disk** that actually use it — not in the 23 project skills, not in
the vercel plugin's skills, not in the official setup plugin's own skills. The specific claim load-bearing for
Phase 5's "budget-(1) = 0" is the stronger one — that `disable-model-invocation: true` **removes the skill's
`description` line from the always-loaded skill index** (not merely "model can't invoke it"). "User-only
invocation" and "absent from the model's context/skill-index" are **two different properties**, and the
on-disk reference documents only the former explicitly ("Only user can invoke"). capability-facts asserts the
latter ("removed from context") but I could not corroborate *that the description is dropped from the index*
on disk or in the official memory/skills docs I fetched. **This is the entire basis for "budget-(1)=0 holds"
in Phase 5.** If `disable-model-invocation` keeps the description in the skill index (just blocks
auto-routing), then `/cr-eval` adds +1 to budget (1) after all — which Phase 5 §A itself flags as the
fallback. **Fix:** demote the budget-(1)=0 claim to *conditional* ("budget-(1)=0 **iff**
`disable-model-invocation` drops the description from the skill index — verify on the target CC version;
otherwise +1"). This is a one-line precision fix, and Phase 5 already wrote the fallback, so it costs nothing
but honesty.

**SF-2 — The `.cr-ok` → CI "re-runs the deterministic /cr subset" claim is sound, but what is *mechanizable*
is narrower than "a subset of /cr" implies.** *(phase3/RECONCILIATION §C.5; compounding-loop.md §3.4; disk:
`.claude/skills/cr/SKILL.md` Step 7; `.github/workflows/ci.yml`; `.gitignore:57-58`.)*

Re-verified: `.cr-ok` is **model-written prose** — `/cr` Step 7 does `printf "branch:sha" > .cr-ok` (or the
Write tool). It is gitignored (confirmed `.gitignore:57-58`), so it never reaches CI. There is no
deterministic check anywhere that `/cr` *ran* or that MUST-FIX=0 — the certificate is exactly as forgeable as
the design says. The §C.5 resolution — (a) CI re-runs the deterministic subset so the model never writes the
trusted record + (b) judgment passes accepted as coverage-bounded trust — is the right call. **The honest
sharpening:** the "deterministic subset of `/cr`" that CI can re-run is **precisely what `ci.yml` already runs**
(`tsc --noEmit`, `eslint .`, `test:unit`) — i.e. it is not a *subset of /cr* re-executed, it is *the CI lane
that already exists, re-asserted on the sentinel SHA via branch protection*. The /cr passes that map to
deterministic tools (P-lint, P-tsc, P-test, `it.only` scan) are mechanizable; **every judgment/lens pass
(P1-P9 + 4 adversarial lenses) is genuinely NOT** — and the design says so. So claim (f) is **not an
over-claim**, but the phrasing "CI re-runs the deterministic subset of /cr" should be "CI's existing
deterministic checks (tsc/eslint/test) are made the *required* gate on the sentinel SHA via branch
protection; the judgment passes remain coverage-bounded trust." The unforgeable half is real; the
mechanizable surface is the pre-existing CI lane, not a re-execution of /cr. **Fix:** restate to avoid
implying CI re-invokes `/cr`'s judgment machinery.

### CONSIDER

**C-1 — The eval scorer (claim g) is genuinely deterministic, but its determinism depends on `/cr`'s output
being reliably machine-parseable into tagged MUST-FIX findings — an unstated precondition.** *(compounding-
loop.md §3.4, §3.5.)* The scorer is correctly designed as a string/tag match in `scripts/score-cr-eval.sh`
("deterministic, no model"; "diffed against that frozen label — a mechanical comparison, not a judgment") —
this is a sound anti-authority-laundering design and NOT an LLM-judge. The residual: the tag-match assumes
`/cr` emits findings tagged with a stable `defect_class` the scorer can grep. `/cr` today emits prose tiers
(MUST-FIX / NEEDS-HUMAN / SUGGESTION), not machine `defect_class` tags. For the deterministic scorer to work,
`/cr` output must carry a parseable per-finding class — a small `/cr` output-format requirement the design
should name as a precondition (otherwise the "deterministic comparison" quietly needs an LLM to map prose
findings to defect classes, reintroducing the laundering the design forbids). Cheap to fix: require `/cr` to
tag each finding with a `defect_class` token in the eval run.

**C-2 — `metadata.pathPatterns` (the live-ecosystem convention) vs native `paths:` (the design's mechanism)
— confirm the chosen field is the one the platform auto-loads on.** *(memory-model.md §7; observed on disk.)*
The live `vercel 0.43.0` plugin scopes its skills with `metadata.pathPatterns` (60 occurrences across
installed plugins) — a **custom convention the model reads from frontmatter**, NOT the native `paths:`
lazy-load the memory model uses for `.claude/rules/`. These are different mechanisms: `paths:` on a
`.claude/rules/*.md` file is platform-native auto-load (confirmed in the memory doc); `metadata.pathPatterns`
on a `skills/*/SKILL.md` is a plugin-author convention the skill description leans on for relevance routing.
The design correctly uses `paths:` for rules (right), but should note the distinction so no one "harmonizes"
the two — a rules shard must use bare `paths:`, not `metadata.pathPatterns`, or it won't native-auto-load.
Low-risk because the design already specifies `paths:`; flagging only to prevent a future conflation.

**C-3 — `additionalDirectories` correction (Phase-4 C4a) confirmed on disk — no action, recorded for the
ledger.** Disk `settings.json` top-level keys are exactly `env / autoMode / permissions / hooks`. There is
**no** `additionalDirectories` top-level key (the memory referencing it as a settings key is wrong; Phase-4
C4a already caught this). The capability-reality ledger is clean here.

---

## Cross-cutting capability verdict

| Claim | Load-bearing? | Verdict | Evidence |
|---|---|---|---|
| (a) Stop hook sees corrected-mistake signal + append-and-allow-stop | **HIGHEST** | CONCERNS — transcript is a *path*; detection is the hard, possibly-non-deterministic part (MF-1) | live hooks doc: `transcript_path` = path not content; `decision:block` works but emitter doesn't need it |
| (b) plugin settings.json carries only agent+subagentStatusLine; hooks.json wires without guard-file edit | HIGH | **CLEAN — strengthened** | vercel 0.43.0 = 27-byte settings; hooks.json supports Stop/SubagentStop |
| (c) `.claude/rules/` + `paths:` native lazy-load; path-less shards don't auto-scope | **HIGHEST** | **CLEAN — authoritatively confirmed** | official memory doc documents `paths:`, globs, "no-paths = load always" |
| (d) `disable-model-invocation` removes skill from context | HIGH (Phase-5 budget-1=0) | CONCERNS — "user-only" documented; "drops from index" not corroborated on disk (SF-1) | field real in official skills-reference; 0 on-disk users; "removed from context" unverified |
| (e) autoMode not read from committed project settings | MEDIUM | **CLEAN — authoritatively confirmed** | official settings doc: "Not read from shared project settings" verbatim |
| (f) `.cr-ok`→CI unforgeability via deterministic subset re-run | HIGH | CLEAN-with-rephrase — sound, but mechanizable surface = existing CI lane, not /cr re-exec (SF-2) | sentinel is model-written prose; ci.yml already runs tsc/eslint/test; judgment passes honestly un-mechanizable |
| (g) eval scorer is not an LLM-judge | MEDIUM | CLEAN-with-precondition — deterministic tag-match, needs parseable /cr output (C-1) | §3.4 "deterministic, no model"; design forbids self-grading correctly |

**Anti-phantom check (my axis):** nothing in the integrated design proposes building a capability that
already exists OR rebuilds a §F reject. The Stop-emitter, `block-dangerous-bash`, `.claude/rules/`,
`session-end-capture`, the eval corpus, the harness-manifest are all confirmed-absent on disk
(re-verified: `.claude/rules` absent, no `session-end*.sh`, no `block-dangerous-bash.sh`, no eval store). The
design does NOT re-propose `@benchmark-runner` (explicitly designs the real thing instead), does NOT
symlink-live install, does NOT paste autoMode by agent. Clean on anti-phantom.

**The single thing that would most change the build if wrong:** MF-1. Everything else is prose precision. If a
deterministic script *cannot* reliably detect a corrected-mistake from the transcript JSON, the "fully
automatic write-back" leg degrades to `/cr` 3b + manual append — which the design already names as the
fallback, so even the worst case is bounded. That bounded-worst-case is why this is CONCERNS, not
SERIOUS-CONCERNS: the design's own degrade-path discipline absorbs the one capability it can't yet confirm.
