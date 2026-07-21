---
name: review-and-cleanup
description: Use when the user asks for a combined code-review and cleanup final pass before integration, including per-commit review-and-cleanup. Runs both passes to convergence without expanding beyond issues caused or exposed by the original change.
---

# Review and Cleanup

Loop `superpowers:requesting-code-review` and `cleanup` over one frozen causal scope until a full round applies no fixes.

## Freeze the scope

Before the first round, resolve the integration base and record the original branch diff. Include uncommitted or untracked work only when the user requested it or repository evidence clearly identifies it as part of the same task; preserve other dirty work.

For per-commit mode, freeze the original commit list and review each original commit patch separately. Treat intentionally included dirty work as one final pseudo-commit. Repairs created by this loop never become new per-commit scopes.

Keep three boundaries distinct:

- **Finding roots:** the original diff hunks and the symbols, control flow, contracts, and design decisions they change.
- **Read context:** any whole file, caller graph, test, documentation, or history needed to understand a root.
- **Repair closure:** declarations, call sites, imports, tests, docs, config, and protocol consumers that must change to complete an eligible fix.

Reading a file does not authorize findings anywhere in it. Editing a repair-closure file does not make that file a new finding root.

## Accept only causal findings

A finding is eligible only when it:

1. was introduced or materially worsened by an original finding root;
2. concerns unchanged code that became dead, inconsistent, redundant, stale, reachable, or invalid because of a root; or
3. was introduced by a repair applied during this run.

Use a counterfactual check: revert the originating root mentally. If the same failure mode, reachability, severity, and materially identical repair remain, the issue is pre-existing baseline debt and is out of scope. Mere presence in a changed file, adjacency to changed lines, or discovery while updating a caller is not causal evidence.

Require each finding to identify its origin:

```json
{
  "findings": [{
    "location": "path:line",
    "issue": "...",
    "fix": "concrete change",
    "scope_origin": "original hunk or prior repair",
    "causal_evidence": "why that origin created or exposed the issue"
  }]
}
```

Reject findings without concrete causal evidence. Do not fix or report ordinary baseline debt as a skipped finding.

## Run rounds to convergence

One round is a fresh code-review pass followed by a cleanup pass. Give both stages the frozen finding roots, accepted repair hunks, and the scope contract above.

- Re-review original roots and prior repair hunks for eligible issues and regressions.
- Never recompute roots from every file currently changed on the branch.
- A cleanup edit can expose a review issue and vice versa, so judge convergence across the whole round.
- Converge only when a full round applies zero eligible fixes. Out-of-scope observations do not prevent convergence.

## Apply eligible fixes

Apply every validated, in-scope cleanup finding. Cleanup fixes preserve intended behavior; correctness or product changes belong to the review stage.

Auto-apply code-decidable review findings, including lossless bug fixes, performance improvements, structural refactors, abstraction changes, and public API or protocol changes. Update the complete repair closure regardless of change size, but do not clean independent issues found there.

Route only genuine decision-space findings to the user:

- user-facing behavior, copy, or interaction choices;
- externally observed error contracts whose intended compatibility cannot be established; or
- published or cross-service fallback contracts whose callers cannot be proven from available evidence.

Uncertainty alone is not decision space. Drop findings that conflict with a user-pinned decision.

On Claude Code, prefer the Workflow tool (`ultracode`) for cleanup fan-out; invoking this skill is explicit opt-in.

## Commit and report

Commit each applied fix separately, or as a tight same-category batch. Stage only the repair and its necessary closure; never include pre-existing dirty work.

Summarize applied fixes and verification. Omit ordinary out-of-scope observations. When decisions remain, provide one combined list of at most 10 items in the user's language using `path:line` · issue · options · recommendation.
