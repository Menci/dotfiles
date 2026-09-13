---
name: cleanup
description: Use when finishing a feature branch and wanting a final-state cleanup pass. Inventories every causal comment, function or structure, and defensive fallback as an atomic review unit; assigns one globally informed subagent per unit unless the user explicitly requests a different review granularity; fixes every validated issue caused or exposed by the change; and proves zero-finding convergence without touching unrelated baseline debt.
---

# Cleanup

Clean the final design introduced by a change. The default and essential mechanism is **one atomic review unit per subagent**: one comment, one changed function or declaration, one fallback occurrence, and so on. Each subagent may inspect the entire repository but concentrates all attention on exactly one assigned unit.

## Freeze the causal scope

Resolve the integration base and freeze the original branch diff before editing. If a caller supplies a frozen scope, use it unchanged. Include dirty work only when requested or clearly part of the same task; preserve other dirty work.

Keep these boundaries distinct:

- **Finding roots:** original diff hunks and the symbols, flows, contracts, comments, and decisions they change.
- **Read context:** unrestricted whole-file, caller, test, documentation, and history evidence used to understand one root.
- **Repair closure:** declarations, consumers, tests, docs, config, and protocols that must change to complete an eligible fix.

Reading context does not create roots. Editing repair closure does not make the whole edited file a root. Tests are evidence and repair closure, not independent cleanup roots.

## Lock reviewer granularity

Set `units_per_reviewer = 1` unless the user explicitly requests a different cleanup review granularity.

This is a hard invariant:

- Never infer permission to batch units from urgency, token cost, unit count, similarity, adjacency, file locality, simplicity, available concurrency, or tool limitations.
- Never let a workflow, orchestrator, or subagent combine units as an optimization.
- Never assign one reviewer multiple units because they are generated, repetitive, trivial, or already reviewed elsewhere.
- When concurrency is insufficient, dispatch more waves. Waiting changes scheduling, not granularity.
- When no suitable workflow exists, continue one unit at a time. Missing tooling changes throughput, not granularity.

Only an explicit user instruction may change `units_per_reviewer`. Record the exact override and its requested maximum before dispatch. Apply it only to the current cleanup run unless the user states a broader policy. An instruction to “be faster”, “use fewer agents”, or “keep it lightweight” is not a granularity override unless it explicitly authorizes multiple review units per reviewer.

Without a recorded explicit override, assigning two units to one reviewer invalidates the round.

## Build exhaustive atomic inventories

Build inventories mechanically before dispatch. Give each unit a stable ID, `path:line`, complete logical content, and `scope_origin`. Keep the original inventories frozen; append units introduced by repairs without recomputing roots from the whole latest diff.

Never combine multiple units merely because they are adjacent, similar, or in the same file.

### Comment units

One logical comment block is one unit. Inventory every block that:

- contains an added or modified comment line in an original root or repair;
- directly documents a declaration, value, branch, or flow changed by a root or repair; or
- is unchanged but may have become stale because a root changed its symbol, literal, behavior, or contract.

Include inline comments, doc comments, configuration comments, and test comments. When one line changes, inventory the entire logical block.

From deleted hunk lines, separately inventory changed identifiers, numbers, times, versions, string/config values, paths, named modes, and behaviors. These **deleted referents** are cross-checked against every comment unit.

### Structure units

One changed production function, class, interface, type, constant group, export, module boundary, or cohesive control-flow decision is one unit. Prefer the smallest independently judgeable unit. A multi-function flow may be an additional flow unit, but it never replaces the per-function units.

Record the global callers, consumers, and contracts each unit may need as read context.

### Fallback units

Each in-scope `??`, `?.`, fallback `||`, optional return, default parameter, capability guard, or guard-style `if` is one unit. Exclude boolean `||` and guards that already throw or assert.

## Dispatch atomic reviewers

Dispatch read-only reviewers using the strongest available model. Every prompt must contain:

- the frozen roots and accepted repair hunks;
- the complete assigned unit and stable ID;
- the final-design overview and relevant inventory context;
- permission to read any repository context needed; and
- a rule that findings may concern only the assigned unit or its causal repair closure.

Global context is unlimited; finding focus is atomic. A reviewer may locate a defect in a caller or contract outside the unit when the assigned unit caused or exposed it, but must identify the assigned unit as `scope_origin`.

With the default `units_per_reviewer = 1`:

- **Each comment unit gets two separate subagents:** one for semantic necessity/final-state prose and one for concrete-claim/referent provenance.
- **Each structure unit gets its own structure subagent.**
- **Each fallback unit gets its own fallback subagent.**
- **No subagent receives two inventory IDs.**

Do not cluster contiguous comments, sibling functions, repeated fallbacks, or simple units. If units exceed concurrency, dispatch in waves. If there are many units, use a workflow only when it preserves one isolated reviewer task per unit.

When the user explicitly overrides granularity, a reviewer may receive at most the recorded number of units. The prompt and response must still keep separate IDs and separate coverage records for each unit. Never exceed the recorded maximum.

The primary agent must independently read every comment unit and reconcile its two reviews. Subagents provide isolated attention and evidence; they do not replace primary-agent adjudication.

## Require per-unit coverage evidence

At default granularity, every subagent is assigned exactly one ID and must return exactly one coverage record:

```json
{
  "coverage": [{
    "id": "comment:C7",
    "location": "path:line",
    "verdict": "keep | rewrite | remove",
    "purpose": "decision | invariant | constraint | evidence | none",
    "claims": [{
      "claim": "literal, symbol, behavior, or causal statement",
      "evidence": "final-tree path:line, current contract, or permalink",
      "status": "current | external | stale"
    }],
    "reason": "clause-level justification"
  }],
  "findings": [{
    "location": "path:line",
    "issue": "...",
    "fix": "concrete change",
    "scope_origin": "the assigned unit",
    "causal_evidence": "why that unit created or exposed the issue"
  }],
  "summary": {
    "reviewed": 1,
    "assigned": 1,
    "missing": [],
    "duplicates": []
  }
}
```

For structure and fallback units, replace comment-specific fields with concise unit evidence.

Without a user override, invalidate responses containing zero or multiple coverage records, another ID, missing verdict/evidence, or multiple review targets. With an override, require exactly one coverage record per assigned ID and `reviewed = assigned <= units_per_reviewer`.

Finding-only responses are invalid. `{"findings":[]}` is never coverage proof.

## Validate causal scope

Accept a finding only when it:

1. was introduced or materially worsened by an original root;
2. concerns unchanged code made dead, inconsistent, redundant, stale, reachable, or invalid by a root; or
3. was introduced by an accepted repair.

Apply the counterfactual test: revert the originating unit mentally. If the same failure mode, severity, reachability, and materially identical repair remain, it is baseline debt and out of scope. Adjacency and shared files are not causal evidence.

Discard ordinary out-of-scope observations without editing or reporting them as skipped findings.

## Audit each comment as final-state prose

Audit every clause independently. A useful clause never excuses a stale, obvious, historical, or unsupported clause in the same block.

For each assigned comment, answer:

1. **Necessity:** What non-obvious decision, invariant, constraint, or evidence disappears if it is removed?
2. **Final-state wording:** Does every clause describe only the current design, without requiring the branch diff or replaced implementation?
3. **Claim verification:** Does every symbol, number, time/frequency, threshold, version, config value, named mode, exact behavior, and causal claim have a current owner or durable permalink?
4. **Durability and locality:** Is every concrete detail necessary here and tied to its authority? Prefer the owning constant/config over duplicated magic literals.
5. **Concision and voice:** Can the same non-obvious value be stated more briefly in author or passive voice?

Presume a referent stale when it occurs only on deleted lines or in pre-change history, names a removed concept, or explains how the branch differs from its base. Keep it only with independent current evidence.

Apply the clean-room test clause by clause:

> Would an author implementing the final design from scratch need this exact statement without seeing the diff or knowing the replaced design?

If not, remove or rewrite it as a positive current invariant, constraint, or decision.

Treat `instead of`, `rather than`, `no longer`, `now`, `from`, `avoids the old`, and exact prior values as history signals. A rejected alternative belongs only when it remains a plausible current choice and the comment records the durable reason it must stay rejected.

Also flag obvious restatement, temporary/uncommitted citations, user or agent voice, and avoidable verbosity.

## Review each structure unit

For each assigned function, declaration, or design unit, use global caller context and flag causal instances of:

- indirection that hurts locality;
- ordering that obscures execution flow;
- thin wrappers, single-implementation interfaces, primitive aliases, or pass-through getters without business meaning;
- optional fields or returns every business path requires;
- production structure created only for tests; or
- patching traces such as divergent sibling paths, obsolete names, unreleased shims, dead flags, re-export shims, and aliases kept just in case.

The reviewer may require edits across the unit's complete repair closure.

## Challenge each defensive fallback

For each assigned fallback, trace actual callers, assignments, and boundary parsing. Types and hypothetical future callers are not evidence.

| Verdict | Evidence | Action |
|---|---|---|
| Necessary | Concrete omitting path and domain-correct default | Keep |
| Should propagate | Absence violates an invariant | Remove fallback or throw/assert |
| Unreachable | Every business caller provides the value | Tighten type and repair closure |
| Wrong default | Absence is real but fallback lies | Propagate, throw, or use correct value |

Normalize external input once at its boundary. Challenge `Map.get`, `.find()`, and optional returns until a concrete valid-absence path is proven.

## Apply and iterate

Apply every validated eligible finding. Repair necessary closure while preserving atomic roots.

After repairs:

- append every repair-created comment, structure, and fallback unit;
- rebuild the full logical block for changed comments;
- re-dispatch fresh reviewers at the recorded granularity for original and repair units causally affected by the repair; and
- never reuse a prior verdict after its unit changes.

## Prove convergence

At default granularity, a round counts as zero-finding only when:

- every inventory ID has its own subagent response;
- every response reports `reviewed = assigned = 1` with the exact ID;
- no response is missing, duplicated, multi-unit, or batched;
- every unit has a verdict and evidence;
- each comment has two independent complete reviews;
- the primary agent reconciles comment-review disagreements; and
- the full round applies no repairs.

With an explicit override, use its recorded maximum and require exact per-ID coverage; all other convergence requirements remain unchanged.

Iterate until one fresh full round satisfies every condition.

## Report

Report the recorded reviewer granularity and any user override, inventory counts by unit type, isolated subagent review count, rounds, fixes/files, verification, demonstrably wrong rejected findings, and excluded dirty work. Omit ordinary baseline debt.

This skill does not commit or run tests unless the caller requests those actions.
