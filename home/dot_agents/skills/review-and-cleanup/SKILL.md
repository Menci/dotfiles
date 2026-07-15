---
name: review-and-cleanup
description: Use when the user asks for a combined code-review + cleanup final pass before integration. Typical phrasings — "review + cleanup", "/code-review + /cleanup", "/requesting-code-review + /cleanup", "do review then cleanup", "/requesting-code-review + /cleanup per commit".
---

# Review and Cleanup

Loop (`superpowers:requesting-code-review` + `cleanup`) over the same scope until a full round makes zero modifications.

## Scope

Default: branch diff vs integration base plus uncommitted. If the user asks for per-commit scoping, loop per commit instead.

## Round and convergence

One round = a fresh `superpowers:requesting-code-review` pass, then a `cleanup` pass, both over the same scope.

- Review is always a fresh dispatch; never trust a prior round's "already fixed" verdicts.
- A cleanup edit can re-expose review-fixable issues and vice versa, so convergence is judged on **the whole round**.
- Keep running rounds until one full round auto-applies zero changes across BOTH stages. A round where one stage was idle but the other modified files is NOT converged — run another round.

## Auto-apply rules

**Cleanup stage — apply every finding.** Cleanup is a mechanical / structural pass by construction (redundant comments, agent-voice, stale references, dead code, thin wrappers, single-use helpers, patching traces, optional→required tightening, defensive-fallback removal). Every returned finding is a reasoned defect and gets fixed. Update every call site — public-API renames, cross-package type changes, and behavior-preserving merges are all in scope. Skip a finding only when it is demonstrably wrong (subagent misread the code, the "fix" would break behavior, the evidence chain has a hole); note skips with reasons in the final report. Never skip because a change is small, cosmetic, or "just structural" — structural refactors are the point.

**Review stage — auto-apply the code-decidable findings:**

- Lossless bug fixes (correctness restored)
- Performance improvements (work reduced)
- **Structural refactors, abstraction changes, and public-API / protocol shape changes.** These carry the highest signal about design health; treating them as "too big to auto-apply" defeats the point of review. Change size is never a reason to route to decisions. Update every call site as part of the same fix.

Route to the decisions list **only** when the finding genuinely lives in decision space that code and this repo's evidence cannot settle:

- **UX changes** — user-facing behavior, copy, or interaction that is a product call.
- **Error-semantics / error-message changes with an external observer** — a published contract, log-parsing consumer, or test in another repo that pins the specific shape or wording. Internal error refactors auto-apply.
- **Defensive-fallback removal where the caller graph extends beyond this codebase** — published package, cross-service RPC, plugin API — and the "no caller omits" proof cannot be established from the diff. Within-repo fallback removal auto-applies.

Uncertainty alone is not decision space. When the fix is a code call the reviewer can settle from in-repo evidence, apply it.

On Claude Code, prefer running the cleanup stage through the Workflow tool ("ultracode") — its parallel fan-out across changed files is naturally workflow-shaped, and invoking this skill counts as explicit opt-in.

When the user has explicitly pinned something to preserve (e.g. "keep the options struct, more fields will be added"), drop matching suggestions from both stages.

## Commit policy

Every applied fix lands as one commit on the feature branch — either a single finding, or a tight same-category batch (e.g. "remove 3 dead branches in handler.ts"; "inline single-use helpers in report.ts"). Never mix unrelated fixes in one commit. Commit message summarizes the finding(s). Both review-originated and cleanup-originated fixes follow this rule.

## Final report

If the round produced no decision-space findings, skip the list entirely — just report what was auto-applied. Do not fabricate items to fill a quota.

When there are decisions to surface: single combined list, **≤10 items**, in the user's language. Cluster related items; if genuinely more, keep the top 10 by impact and note "+N lower-priority items omitted".

Each item: `path:line` · issue · options · recommendation.
