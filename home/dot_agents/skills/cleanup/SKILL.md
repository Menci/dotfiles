---
name: cleanup
description: Use when finishing a feature branch and wanting a final-state cleanup pass. Audits changed comments, structures, and defensive fallbacks with parallel subagents, fixes every validated finding caused or exposed by the change, and leaves unrelated baseline debt untouched.
---

# Cleanup

Clean the final design introduced by a change. Treat the branch diff as one squashed result, but never treat every pre-existing line in a changed file as cleanup scope.

## Freeze the causal scope

Resolve the integration base and freeze the original branch diff before editing. If a caller supplies a frozen scope, use it unchanged. Include uncommitted or untracked work only when the user requested it or repository evidence clearly identifies it as part of the same task; preserve and report other dirty work.

Keep three boundaries distinct:

- **Finding roots:** original diff hunks and the symbols, flows, contracts, and design decisions they change.
- **Read context:** unrestricted whole-file and repository evidence used to understand roots.
- **Repair closure:** unchanged declarations, consumers, tests, docs, config, or protocols that must be edited to complete an eligible fix.

Full files may be read as context. Neither presence in a changed file nor an edit made for repair closure creates a new finding root.

Tests are not independent cleanup roots. They may be read as evidence and updated as repair closure.

## Dispatch focused reviews

Fan out reviews in one assistant message using the strongest available model. Subagents return findings and do not edit files. Give each reviewer the relevant original diff, final content, scope contract, and applicable rules.

- **Comment review:** review comments added or changed by a root, plus unchanged comments made stale by a root or repair.
- **Code-structure review:** review each changed file or cohesive changed concept, restricted to roots and unchanged artifacts causally affected by them.
- **Defensive-fallback challenge:** review each in-scope `??`, `?.`, fallback `||`, or guard-style `if (!x)`. A pre-existing occurrence is in scope only when a root or repair made it redundant, wrong, newly reachable, or invalid.

When fan-out would require roughly more than 30 subagents, use the available workflow mechanism. A zero-finding response is valid when the change is already clean.

Require this return shape:

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

## Validate scope before applying

Accept a finding only when it:

1. was introduced or materially worsened by an original finding root;
2. concerns unchanged code made dead, inconsistent, redundant, stale, reachable, or invalid by a root; or
3. was introduced by an accepted repair.

Use a counterfactual check: revert the originating root mentally. If the same failure mode, reachability, severity, and materially identical repair remain, the issue is baseline debt and is out of scope. Adjacency, the same enclosing file, and discovery through a call-site update are not causal evidence.

Discard ordinary out-of-scope observations without editing or reporting them as skipped findings.

## Comment rules

Flag in-scope comments that:

- restate obvious code;
- mention symbols, behavior, or invariants removed or invalidated by the change;
- cite uncommitted reports, specs, plans, or transcripts;
- narrate branch history such as "previously", "after the refactor", or "renamed from";
- use user or agent voice instead of author voice or passive voice; or
- use a verbose block where a concise comment preserves all non-obvious information.

Keep comments that record non-obvious decisions, invariants, constraints, surprising behavior, or evidence chains with permalink URLs.

## Structure rules

Review the final implementation of changed concepts, using surrounding code only as context. Flag causal instances of:

- single-use helpers, constants, or types whose indirection hurts locality;
- definitions ordered so execution flow is needlessly hard to follow;
- thin wrappers, single-implementation interfaces, primitive aliases, or pass-through getters without business meaning;
- optional fields, parameters, or returns that every business path requires;
- production structure created solely to accommodate tests; or
- patching traces such as divergent sibling paths, obsolete versioned names, unreleased compatibility shims, dead flags, re-export shims, or alias types kept "just in case".

The changed design should read as one coherent implementation. Update the necessary repair closure for an eligible refactor, but do not clean independent pre-existing issues in closure files.

## Defensive-fallback rules

For each in-scope occurrence, trace callers, assignments, and boundary parsing. Ask:

> Does business code actually provide an absent or falsy value here, and is the fallback meaning correct for that real domain case?

Types and hypothetical future callers are not evidence. Normalize external input once at its boundary instead of scattering use-site fallbacks.

| Verdict | Evidence | Action |
|---|---|---|
| Necessary | A concrete omitting path and domain reason for the default | Keep |
| Should propagate | Absence violates an invariant | Remove the fallback or throw/assert explicitly |
| Unreachable | Every business caller provides the value | Tighten the type and update its repair closure |
| Wrong default | Absence is real but the default lies downstream | Throw, propagate absence, or use the domain-correct value |

Exclude before dispatch only boolean `||` and guards that already throw or assert. Challenge optional-return APIs such as `Map.get` and `.find()`; classify them as Necessary only after concrete domain evidence confirms that absence is valid. Cluster only contiguous reads of the same defended root within one function.

## Apply and iterate

Apply every validated, eligible finding regardless of cosmetic size. A repair may edit any necessary closure file, but later passes review only the generated repair hunks and causally affected artifacts there, not the whole file.

Skip an eligible finding only when its analysis is demonstrably wrong or its proposed fix would break intended behavior; report the reason. Do not label baseline debt as a skipped finding.

Iterate until a fresh cleanup pass applies zero eligible repairs.

## Report

Report the number of fixes and files, concise per-file changes, verification performed, demonstrably wrong skipped findings, and excluded dirty work.

This skill does not commit. It does not run tests unless the caller requests verification. It does not independently clean test code or baseline debt.
