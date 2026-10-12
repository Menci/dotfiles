---
name: cleanup
description: Run one explicitly requested cleanup cycle over a change through separate comment, structure, and defensive-design reviews, without increasing complexity or touching unrelated baseline debt.
---

# Cleanup

Run this skill only when the user explicitly invokes `$cleanup`. One invocation performs exactly one cleanup cycle over the current frozen scope. Edits made during the cycle do not invoke this skill again and do not start another cycle automatically.

Clean the final design introduced by a change. Review three categories separately: **comments**, **structure**, and **defensive design**. Prefer file-sized batches; split large files into cohesive portions that a reviewer can examine thoroughly. Batch size controls scheduling, not coverage or causal scope.

## Freeze the causal scope

Resolve the integration base and freeze the original branch diff before editing. Use a caller-supplied frozen scope unchanged. Include dirty work only when requested or clearly part of the same task; preserve other dirty work.

Keep these boundaries distinct:

- **Finding roots:** original diff hunks and the symbols, flows, contracts, comments, and decisions they change.
- **Read context:** unrestricted whole-file, caller, test, documentation, and history evidence needed to understand a root.
- **Repair closure:** declarations, consumers, tests, docs, config, and protocols that must change to complete an eligible fix.

Reading context does not create roots. Editing repair closure does not make the whole edited file a root. Tests are evidence and repair closure, not independent cleanup roots.

## Inventory units and form batches

Build exhaustive inventories before dispatch. Give each unit a stable ID, `path:line`, complete logical content, and `scope_origin`. Keep original roots frozen and add repair-created units without deriving new roots from the whole latest diff.

### Comments

One logical comment block is one unit. Inventory every block that contains an added or modified line, directly documents a changed declaration or flow, or may have become stale because a root changed its referent or contract. Include inline, doc, configuration, and test comments; inventory the entire logical block when one line changes.

From deleted hunk lines, record changed identifiers, numbers, times, versions, string/config values, paths, named modes, and behaviors. Cross-check these deleted referents against the comment inventory.

### Structure

Inventory changed production functions, classes, interfaces, types, constant groups, exports, module boundaries, and cohesive control-flow decisions. Keep independently judgeable units distinguishable within a batch. Add multi-function flow units when needed without replacing function coverage. Record relevant callers, consumers, and contracts.

### Defensive design

Inventory in-scope defenses, including:

- `??`, `?.`, fallback `||`, default parameters, optional fields and returns;
- guard-style branches, capability checks, repeated validation, assertions, and error conversion;
- catches that swallow errors, empty/default success responses, retries, and recovery paths;
- compatibility shims, speculative handling of impossible states, and duplicated boundary normalization.

Exclude ordinary boolean expressions and business branches that do not defend against absence, invalidity, failure, or unavailable capabilities. Throwing guards and assertions remain reviewable defenses: their necessity and placement still need evidence.

### Batching

Group units of the same category by file. For large files, use logical sections or cohesive declaration groups, keeping complete comment blocks and functions together. Choose smaller batches when density or complexity would compromise attention. Record each batch's category, file/section, and exact unit IDs; no fixed maximum unit count or user override is required.

## Dispatch separate category reviews

Use read-only subagents with the current agent's model unless applicable instructions specify otherwise. Every prompt must include the frozen roots, accepted repair hunks, assigned batch and IDs, final-design overview, relevant inventory context, unrestricted read-context permission, and the causal-scope rule. State whether further delegation is allowed and its maximum recursion depth.

Keep category assessments separate:

- **Comments:** two independent reviews per batch, one for semantic necessity/final-state prose and one for concrete claims and referent provenance.
- **Structure:** a dedicated structure review for each batch.
- **Defensive design:** a dedicated defensive-design review for each batch.

A reviewer may examine callers or contracts outside its batch when needed, but every finding must identify an assigned unit as `scope_origin`. File batching never authorizes unrelated findings in that file. Dispatch in waves when concurrency is limited.

The primary agent independently reads every comment block and reconciles its two reviews.

## Require per-unit coverage

Require one coverage record per assigned ID, even when a reviewer handles many units. Each record needs location, verdict, and concrete evidence. Comment records also need purpose, clause-level reasoning, and provenance for concrete claims. Structure and defensive-design records need relevant caller/contract evidence; defensive-design records must explain the defended state and intended failure behavior.

Each finding needs `location`, `issue`, a concrete `fix`, `scope_origin`, and `causal_evidence`. Require an exact coverage summary: `reviewed = assigned`, with no missing, duplicated, or unassigned IDs. Finding-only responses, including an empty findings list, do not prove coverage. Repair incomplete responses before counting a round.

## Validate causal scope

Accept a finding only when it was introduced or materially worsened by an original root, concerns unchanged code made dead/inconsistent/redundant/stale/reachable/invalid by a root, or was introduced by an accepted repair.

Apply the counterfactual test: mentally revert the originating unit. If the same failure mode, severity, reachability, and materially identical repair remain, the issue is baseline debt. Adjacency and shared files are not causal evidence. Discard ordinary out-of-scope observations without editing or reporting them as skipped findings.

## Audit comments as final-state prose

Audit every clause independently:

1. **Necessity:** What non-obvious decision, invariant, constraint, or evidence disappears if it is removed?
2. **Final-state wording:** Does it describe the current design without needing the diff or replaced implementation?
3. **Claim verification:** Does every symbol, literal, threshold, version, named mode, behavior, and causal claim have a current owner or durable permalink?
4. **Durability and locality:** Is each concrete detail necessary here and tied to its authority? Prefer owning constants/config over duplicated literals.
5. **Concision and voice:** Can the value be stated more briefly in author or passive voice?

Presume a referent stale when it appears only in deleted lines/history or names a removed concept; retain it only with independent current evidence. Apply the clean-room test: would an author implementing the final design from scratch need this exact clause?

Remove obvious restatements, unsupported claims, temporary/uncommitted citations, user/agent voice, and unnecessary historical prose. Wording such as `instead of`, `rather than`, `no longer`, `now`, and exact prior values signals history requiring scrutiny. A rejected alternative belongs only when it remains a plausible current choice and its rejection records a durable decision.

## Review structure

Use global caller context to challenge indirection that hurts locality, confusing execution order, thin wrappers, single-implementation interfaces, primitive aliases, pass-through getters without business meaning, required business data modeled as optional, and production structure created only for tests.

Remove causal patching traces: divergent sibling paths, obsolete names, unreleased shims, dead flags, re-export shims, and aliases retained just in case. Judge the coherent final architecture and complete repair closure, not the number of changed lines.

## Challenge defensive design

Trace actual callers, assignments, parsing boundaries, and error contracts. Types and hypothetical future callers alone do not prove a defense necessary.

| Verdict | Evidence | Action |
|---|---|---|
| Necessary | A concrete valid absence/failure path with domain-correct handling | Keep at the appropriate boundary |
| Should propagate | Absence/failure violates an invariant or recovery hides the error | Remove masking; propagate, throw, or assert |
| Unreachable or redundant | Actual callers guarantee the value/state or an owning boundary already validates it | Tighten the contract and remove duplicate handling |
| Wrong recovery | Failure is real but the default, retry, or conversion misrepresents it | Use domain-correct handling or propagate |
| Speculative | No supported input, caller, or current requirement needs it | Remove the defense and its unnecessary machinery |

Normalize external input once at its owning boundary. Challenge `Map.get`, `.find()`, optional returns, and catches until concrete valid absence/recovery semantics are established. Preserve the original error or its cause chain. Retain top-level error handling and domain defaults when their semantics genuinely require them. Do not add compatibility handling for old data without an explicit requirement.

## Repair without increasing complexity

A cleanup fix must not introduce higher complexity. Assess the full repair closure: control-flow branches and states, indirection, abstraction layers, dependencies, duplicated contracts, and the reasoning required to follow the behavior. Fewer lines alone do not prove simpler design.

Prefer removing unnecessary machinery, tightening contracts, consolidating boundary ownership, and simplifying flows. Do not replace a small defect with a new framework, generic wrapper, configuration mode, fallback chain, or speculative abstraction. If a proposed fix increases complexity, redesign it into a simpler or equally simple solution before applying it. A genuine correctness/product requirement needing more complexity belongs to separately authorized work; report that decision without applying it as cleanup or claiming zero-finding convergence while it remains unresolved.

Apply every validated eligible cleanup fix with its necessary closure. Verify the resulting diff and repair closure, but do not inventory the repairs as a new cleanup scope or begin another review cycle. A later cycle requires another explicit `$cleanup` invocation from the user.

## Complete and report the cycle

Complete the cycle after the original inventory has exact per-ID coverage, separate category reviews, two complete comment reviews per batch, primary-agent reconciliation, applied eligible fixes, and verification that every accepted repair preserved or reduced complexity.

Report batch granularity, counts by category, reviewer count, fixes/files, verification, demonstrably wrong rejected findings, and excluded dirty work. Omit ordinary baseline debt.

This skill does not commit or run tests unless the caller requests those actions.
