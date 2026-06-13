# Traceability — 37signals-dhh (pass3 → V2 design)

Pass-3 file: `passes/37signals-dhh/pass3-apply.md`. Its core is §(b) "REAL gaps" (3 gaps), plus the
load-bearing §(d) verdict ("synthesize, don't re-research") and the §(c) caveats that shape design.
Each gap classified against the V2 design corpus (grepped, not assumed).

## Per-gap classification

| # | Gap / insight (pass3 cite) | Classification | Where it lands / why (corpus cite) |
|---|---|---|---|
| 1 | **§b1 — No accessibility-tier MAP of the agent's own operations exists.** Classify every agent op CLI / API / UI-required / not-possible, as a diagnostic for which steps in an *unattended* loop still fall back to UI/human. A *confirmed absence* in the as-is map; low-cost, diagnostic-only (a map, not a mandate to build CLIs). | **DROPPED** | No operation-by-accessibility classification appears anywhere in the design. Grep across `MASTER-FINDINGS.md`, both `RECONCILIATION.md`, `REVEWER-CONSOLIDATION.md`, `V1-TO-V2-CARRYFORWARD.md`, `target-file-tree.md`, `distribution.md`, `compounding-loop.md` returns no "accessibility-tier" / "UI-required-op map" artifact. The phrase "accessibility gap" survives only in pre-synthesis `cluster-findings-4.md:171-176` — and that is the *visual/debugging* accessibility point (playwright-mcp), a different idea. Not in §C (deferred), not §D (smaller gaps), not §F (rejected). It is the harness's center-of-gravity case (unattended `/queue` + Tier-0 firewall exist *because* unattended runs happen, yet nothing maps which unattended steps still need a browser/human) — and it was never carried, cut, or registered. **A real miss.** |
| 2 | **§b2 — pace/commitment-friction stopping signal is unencoded; `session-end.sh` is the home, and it's absent.** The article's single best contribution: a *second rationale* for `session-end.sh` beyond memory-capture — an explicit stopping / pace-discipline signal (DHH burnout, pass1 §5). | **APPLIED (mechanism) / DROPPED (the pace-signal nuance)** | The mechanism is fully carried: `session-end-capture.sh` is MOVE 1 (`MASTER-FINDINGS.md:34-47`), in `target-file-tree.md:95,116,370-372` (+2 hooks), `V1-TO-V2-CARRYFORWARD.md:74`, and the whole compounding-loop write-back leg (`phase45/compounding-loop.md §1`). The pace-signal *payload* is named once in the synthesis — `MASTER-FINDINGS.md:39` lists "(e) explicit stop/pace signal [C1-G1]" as one of the Stop-hook surface's payloads. **But it stops at the list.** Every downstream concrete design describes `session-end-capture.sh` *only* as the memory write-back emitter (append a `signature`-matched row to S3 / never block). The pace/commitment-stopping rationale — the article's actual contribution, the "second reason to exist" — is not scoped, built, or carried into RECONCILIATION D2/D4, the file-tree hook description, or the compounding loop. The DHH burnout/pace nuance is the DROPPED slice: the hook is built for memory-capture, but the explicit-stop/pace-discipline payload the article added is absent from the built surface. |
| 3 | **§b3 — CLI surface is invisible to the per-tool permission gate; pushing CLI-first *widens* the ungated surface unless paired with a `block-dangerous-bash.sh`.** A CLI hides inside one allowed `bash` pattern; `permissions.allow` does not see individual CLI subcommands. The article's own CLI-evangelism strengthens the case for building the absent bash guard. | **APPLIED** | The fix is the most-cited single gap in the design. `block-dangerous-bash.sh` is built in MOVE 2 (`MASTER-FINDINGS.md:54`), specified concretely in `enforcement-sort.md` resolution (a) (`:42-59`, build item 1 `:293-297`), and it explicitly gates the bash-observable danger surface a wider CLI would open: `curl`/`wget`/`fetch` to non-allowlisted hosts (egress), destructive SQL, `rm -rf`, deploy commands, boundary writes to `.git`/`.husky`/`.claude` (`enforcement-sort.md:46-55`). This directly mechanizes "the ungated CLI subcommand surface." The article's *generative* concern (CLI hides inside one `bash` pattern, invisible to `permissions.allow`) is exactly the gap the bash guard closes by inspecting the command string rather than the tool name. |

## Article headline + "already do" items (pass3 §a, §c, §d — context, not gaps)

These are not §(b) gaps but are load-bearing pass-3 conclusions; recorded for completeness.

| Item | Classification | Cite |
|---|---|---|
| §a — "build CLIs / read house-skills" headline is **already done or low-yield** (CLI tooling + ~26-skill corpus already exist) | n/a (article's own non-gap) | CLI scripts inventory `target-file-tree.md §9`/scripts; skills corpus `target-file-tree.md:148-187`; anti-phantom posture `MASTER-FINDINGS.md §E` |
| §c / §d — "CLI-first-for-everything" as a *mandate* (the article's universalized thesis, MCP-blind) | **CUT (rejected-as-literal)** | `MASTER-FINDINGS.md:189` rejects "CLI-first-for-everything" explicitly, "rejected with reason in the cluster files." Reason: prices CLIs at zero for a solo dev + ignores MCP (the per-call-permissioned alternative the harness already uses). The portable *diagnostic* (gap 1) was kept-as-idea; the *mandate* was cut. |
| §d — CLI-vs-MCP external lookup | **CUT (deferred WITH reason)** | Pass3 §d itself defers it: "trigger external lookup only on a live CLI-vs-MCP build decision." Consistent with the design proposing no tool-surface expansion; no live decision exists, so correctly not researched. |

## Summary

- **Gap 1 (accessibility-tier op map): DROPPED.** The one clean, low-cost, harness-relevant deliverable the
  article actually warranted — and it is nowhere in the synthesis or design. Most acute because the harness's
  entire direction is unattended operation, yet nothing maps which unattended steps still require a
  human/browser. The Tier-0 firewall and `worktree-create.sh` exist for exactly the unattended path this
  audit would diagnose. **Belongs as a small registered deliverable** (MASTER-FINDINGS §C deferred, or §D
  smaller-gaps) — a one-time internal audit, no external research, attachable to the UNATTENDED-mode
  watch-items already noted in `cluster-findings-2.md:120`.
- **Gap 2 (session-end mechanism): APPLIED; the pace/commitment-signal nuance: DROPPED.** The hook is built,
  but only for memory write-back. The article's *actual* contribution — `session-end` as the home for an
  explicit pace/stopping signal, a second reason to exist beyond memory-capture — is listed once
  (`MASTER-FINDINGS.md:39`) then never carried into any concrete design.
- **Gap 3 (ungated CLI surface → bash guard): APPLIED.** Cleanly mechanized by `block-dangerous-bash.sh`,
  the most-cited single gap, which gates the egress/destructive bash surface a wider CLI would open.
- The article's CLI-first *mandate* and the CLI-vs-MCP lookup are legitimately CUT (rejected / deferred with
  stated reasons).
