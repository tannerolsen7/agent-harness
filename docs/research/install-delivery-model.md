<!-- context-meta
owner: tanner
last-reviewed: 2026-06-22
review-frequency: on-merge
expires: 2026-07-22
expiry-note: Expires 30 days from filing (2026-07-22), OR when GitHub changes its archive-download URL format or publishes an official raw.githubusercontent.com rate-limit number, OR when scripts/install.sh changes how it records the manifest sha — whichever comes first.
-->

# Spike — install delivery model (install without a local clone)

**Filed:** 2026-06-22
**Spike pipeline:** /spike (three research passes + synthesis + two verifiers + TDD slice)

---

## The question

Which delivery model should the harness use so a user can install it WITHOUT a
local clone? The harness is pure shell scripts and markdown (about 140 files),
no compiled artifacts. The install step is `bash scripts/setup.sh /path/to/repo`.
The already-built sync mechanic compares a sha256 fingerprint per file against an
upstream source, so the upstream must be stable and addressable per file.

Three candidate models were compared:
1. **npm package** via `npx agent-harness-install`.
2. **GitHub Releases** tarball curled from the Releases page.
3. **GitHub raw curl** — files curled from `raw.githubusercontent.com` per file.

The decision changes what `scripts/setup.sh` and `scripts/install.sh` point at as
the upstream source. The sync mechanic itself was explicitly out of scope.

---

## Recommendation and confidence

**Recommendation:** Fetch ONE archive tarball pinned to a commit SHA
(`https://github.com/OWNER/REPO/archive/<sha>.tar.gz`, which redirects to
`codeload.github.com` — use `curl -L`), unpack it to a temp directory, point
`HARNESS_SRC` at that directory, and run the existing install/sync scripts against
it. This is a specific variant of the GitHub-download family — it is NOT per-file
raw curl, and it decisively beats both per-file raw curl and npm.

Ranking of the three named options:
1. **GitHub archive tarball at a pinned commit SHA** (best — one request, immutable
   content, the unpacked directory looks just like a local clone).
2. **GitHub Releases tarball** (workable fallback, mainly if the repo goes private
   or you want GitHub's opt-in Immutable Releases guarantee; more upkeep — you must
   publish a release on every version).
3. **npm via npx** (rejected — forces a Node.js install on users of a pure-shell
   tool and buys nothing the tarball approach lacks).

**Ruled out: per-file raw curl.** The harness is about 140 files. After GitHub's
May 2025 change, unauthenticated requests to `raw.githubusercontent.com` are
rate-limited (community-reported at about 60 per hour per IP; GitHub never
published the exact number). Fetching 140 files per install or sync blows that
budget and would return HTTP 429 errors part-way through. A token does not help —
reports say the token is ignored for raw rate-limit accounting. Prior-art tools
(nvm, Oh My Zsh, Homebrew) use raw curl, but each fetches only about 3 files, so
their pattern does not transfer to a 140-file harness.

**Confidence: Leaning.** The ranking is well-supported and survived adversarial
attack — the archive-tarball direction is the right one. But the synthesis claim
that this needs "zero changes to install.sh / sync-harness.sh" is FALSE, and the
TDD slice proved it. The recommendation stands; the implementation has known gaps
that must be closed before it ships.

**Revised question (carry forward to the build):** What is the minimum change so
an archive-based install (1) records the pinned commit SHA in the manifest instead
of `"local"`, and (2) gives `sync-harness.sh` a way to re-fetch and unpack that
pinned archive at sync time? The simplest fix for (1) is a `HARNESS_SHA=<sha>` env
var that `install.sh` uses as a fallback when `HARNESS_SRC` has no `.git`.

---

## Confirmed assumptions (what the research established)

- **The real choice is whole-archive-fetch vs per-file-fetch, not "raw vs Releases
  vs npm" as framed.** A pinned-SHA archive is one request, the content is
  immutable (git content-addresses the commit), and the unpacked directory is
  structurally identical to a local clone. The sync mechanic's per-file requirement
  is then satisfied locally against the unpacked files — the upstream URL only needs
  to be stable per VERSION, which a pinned-SHA archive URL is.
- **Per-file raw curl does not scale to 140 files** under the May 2025
  unauthenticated rate limit. Arithmetic: 140 files / ~60 per hour = ~2.3 hours and
  429 errors mid-install.
- **A moving ref (branch like `main`) breaks reproducibility.** Two users who
  install at different times would get different content, and the sha256 comparison
  would thrash. The pin must be a commit SHA, not a branch.
- **npm is the wrong tool for a pure-shell harness.** Nothing in the harness needs
  Node.js at runtime; npm adds a Node prerequisite plus a publish pipeline.
- **`github.com/.../archive/<sha>.tar.gz` redirects (302) to codeload.github.com.**
  `curl` without `-L` feeds the redirect body to `tar` and produces a corrupt,
  empty extract with no clear error. The fetch command MUST use `curl -L`.
- **The unpacked directory name uses the ABBREVIATED (7-char) SHA**, e.g.
  `OWNER-REPO-abc1234/`, even when the URL used the full 40-char SHA. setup.sh
  cannot blindly build `HARNESS_SRC` from the full SHA it passed to the URL — it
  must discover the actual extracted directory name.

## Failed assumptions (what the research disproved)

- **DISPROVED: "zero changes to install.sh because HARNESS_SRC is already an env
  var."** `install.sh` lines 121-126 compute the manifest `sha` field only when
  `git -C "$HARNESS_SRC" rev-parse` succeeds. An unpacked tarball has no `.git`, so
  the check fails and the manifest records `"sha": "local"` instead of the pinned
  commit SHA. The TDD slice confirmed this: with a non-git source dir, the manifest
  `.sha` came back `"local"`. The "pin to the manifest commit SHA" reproducibility
  story is defeated unless install.sh learns the SHA another way.
- **DISPROVED: "sync just works after a tarball install."** `sync-harness.sh`
  resolves `HARNESS_SRC` at sync time (line 25), but the install-time temp dir is
  deleted after install. The manifest `source` field records a path that no longer
  exists. When the user runs sync later, either it exits "HARNESS_SRC not found" or
  it defaults to the script's own directory (the already-installed copies) and
  compares files against themselves, falsely reporting everything up-to-date. Sync
  must itself re-fetch and unpack the pinned archive — that is more than "zero
  change."

## Open risks surfaced by verifiers (not yet disproved, worth tracking)

- **The ~60/hr raw rate-limit number is unofficial.** It is borrowed from the REST
  API limit and community reports; GitHub never published a raw-specific number. The
  ruling against per-file raw is directionally sound (raw is more aggressively
  limited post-May-2025 than archive downloads), but the exact number is unverified.
- **codeload.github.com rate-limit behavior is undocumented.** It is unknown whether
  archive downloads share the raw bucket. Low risk because an install is ONE request
  — but a corporate NAT where many engineers share one IP could still hit a shared
  per-IP window. This threatens the archive approach too, not just per-file raw.
- **GitHub's archive byte-stability is a time-bounded commitment, not a permanent
  guarantee**, and can be broken without notice for security fixes (the Jan 2023
  incident broke Homebrew/Bazel/vcpkg checksums). Low probability, worth noting.
- **Silent empty install is the highest-stakes user failure.** If `HARNESS_SRC`
  points at a wrong/empty dir, install.sh's `[ -f "$srcf" ] || return 0` skips every
  missing file, writes a manifest with an empty `files` block, and exits 0. The user
  sees "success" but no safety gates are installed and never fire. (Note: a wrong
  dir NAME instead trips the `[ -d "$HARNESS_SRC" ]` guard at line 42 and fails
  loudly — but the empty-source path is silent.) For a tool whose job is installing
  safety gates, a silent no-op is worse than a loud failure.
- **Private-repo / corporate-proxy users are not covered** by the tokenless
  assumption. They need a `GITHUB_TOKEN` path and may be blocked by a proxy.

## The slice result

**Test:** `/tmp/test-tarball-sha.sh` (standalone diagnostic, not committed). It
copies the harness files into a non-git temp dir (a faithful simulation of an
unpacked archive), runs `HARNESS_SRC=<no-git-dir> bash scripts/install.sh
<target>`, and asserts on the manifest's top-level `.sha`.

**Result: the slice FAILS the "drop-in" claim** — `.sha` came back `"local"`, not a
40-char commit SHA. This is the assumption-killing result: it proves a tarball
install loses the pinned SHA with no code change. The slice itself ran cleanly on
the first attempt; it is the synthesis's "zero changes" claim that it disproved.

**Next step:** `/feature` to implement the archive-fetch path with the SHA fix
(a `HARNESS_SHA` env-var fallback in install.sh, plus a sync-time re-fetch of the
pinned archive), gated by the new failing assertion. Or `/debug` with the failing
test at `/tmp/test-tarball-sha.sh` if treating the SHA gap as a standalone bug.

## User stakes (from the user verifier)

The user is a consumer engineer who types one command and trusts the result. Ranked
by user-felt pain:
1. **Silent empty install (worst):** install reports success but writes no gates;
   the user's safety checks never fire and they cannot tell. For a safety-gate tool,
   this is the worst possible failure — strictly worse than the loud 429 failure the
   ruled-out raw option would have produced.
2. **Sync pulls a different version than installed** because the pin was not truly
   recorded (the `"local"` bug) — drift the user cannot see.
3. **Private-repo / proxy user** hits a network error or a corrupt archive with no
   clear message.

---

## Full citation list

External:
- GitHub Changelog — Updated rate limits for unauthenticated requests (2025-05-08). https://github.blog/changelog/2025-05-08-updated-rate-limits-for-unauthenticated-requests/
- GitHub Docs — Rate limits for the REST API. https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
- GitHub Docs — Downloading source code archives (commit-SHA archive immutable; branch archive mutable). https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives
- GitHub Docs — REST API endpoints for release assets. https://docs.github.com/en/rest/releases/assets
- GitHub Docs — REST API endpoints for repository contents (per-file, authenticated, 5000/hr). https://docs.github.com/en/rest/repos/contents
- GitHub Docs — Immutable releases (GA 2025-10-28). https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases
- GitHub Community Discussion #160828 — raw rate limit ~60/hr; token ignored for raw rate-limit. https://github.com/orgs/community/discussions/160828
- GitHub Community Discussion #46691 — raw cache TTL (branch URLs max-age=300; 24h stale incident). https://github.com/orgs/community/discussions/46691
- GitHub Community Discussion #46034 — archive hash stability (time-bounded commitment). https://github.com/orgs/community/discussions/46034
- GitHub Community Discussion #45830 — archive checksum mismatches. https://github.com/orgs/community/discussions/45830
- GitHub Community Discussion #47453 — private release asset two-step download flow. https://github.com/orgs/community/discussions/47453
- GitHub Community Discussion #159123 — 429 accessing repo files without login. https://github.com/orgs/community/discussions/159123
- GitHub Community Discussion #167943 — actions/checkout tarball 429 under load. https://github.com/orgs/community/discussions/167943
- opentofu/opentofu Issue #2802 — release asset CDN reportedly not in the raw bucket. https://github.com/opentofu/opentofu/issues/2802
- Bazel blog — GitHub archive checksum outage (2023-02-15). https://blog.bazel.build/2023/02/15/github-archive-checksum.html
- Hacker News — thread on the May 2025 rate limit change. https://news.ycombinator.com/item?id=43936992
- nvm install.sh (raw single-file delivery prior art). https://github.com/nvm-sh/nvm/blob/master/install.sh
- Homebrew Installation (raw delivery prior art). https://docs.brew.sh/Installation
- unpkg (npm per-file CDN, public only). https://unpkg.com/
- jsDelivr (npm per-file CDN, public only). https://www.jsdelivr.com/

Internal (file:line):
- `scripts/install.sh` lines 121-126 — manifest sha computed only via `git -C HARNESS_SRC rev-parse`; falls back to `"local"` on a non-git source (the disproved assumption).
- `scripts/install.sh` line 42 — `[ -d "$HARNESS_SRC" ]` guard (wrong dir NAME fails loudly here).
- `scripts/install.sh` line 77 — `[ -f "$srcf" ] || return 0` (empty-source path is silent).
- `scripts/install.sh` lines 91-97 — `find`-based file walk over COPY_DIRS.
- `scripts/install.sh` line 136 — manifest `source` field records the HARNESS_SRC path (the temp dir that is later deleted).
- `scripts/sync-harness.sh` line 25 — `HARNESS_SRC` env var resolution (sync needs a live source at sync time).
- `scripts/sync-harness.sh` lines 110-113 — the `cp` loop that runs against HARNESS_SRC.
- `/tmp/test-tarball-sha.sh` — the diagnostic slice (not committed); proved `.sha == "local"` on a non-git source.
