---
name: cleanup
description: Use when finishing a feature branch and wanting a final-state cleanup pass — fans out parallel subagents to audit every changed file (comments + structure) and every defensive fallback (??, ?., ||, if (!x)) against simplicity, voice, and no-fake-robustness rules, then fixes every reasonable finding.
---

# /cleanup

Final-state cleanup pass. Treat the diff against main as if it were one squashed commit — feature-branch fixup history is irrelevant, only the end result is reviewed.

## Process

### 1. Establish the squashed diff

Find the integration branch (`main` / `master` / `develop` — check `git remote show origin` or repo convention) and the merge-base. Include uncommitted changes — they are part of the final state.

```bash
BASE=$(git merge-base origin/main HEAD)   # adjust name as needed
git diff --name-only "$BASE"              # changed files incl. working tree
git diff "$BASE" -- <path>                # per-file diff
git show HEAD:<path>                      # final committed content
# if file has uncommitted edits, read working-tree version instead
```

If the working tree is dirty, decide per file: review the working-tree version (final state user intends). Note any unstaged changes in the final report.

### 2. Exclude tests

Drop paths matching `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`, `**/test/**`, `**/tests/**`, plus any project-specific test convention. Tests are not reviewed, but they inform one rule: see [Code-structure review § anti-test-bending].

### 3. Fan out parallel reviews

In a SINGLE assistant message, dispatch every review needed. Three review kinds:

- **Comment review** — one subagent per changed file.
- **Code-structure review** — one subagent per changed file.
- **Defensive-fallback challenge** — one subagent per occurrence of `??`, `?.`, `||`, or `if (!x)` in changed business code (a chained `a?.b?.c` is one occurrence, not three; see clustering rule below).

Use `subagent_type: general-purpose` and the strongest available model. Each prompt is self-contained: it carries the file content, the per-file squashed diff, the relevant rules section verbatim, and (for fallback challenges) the precise occurrence with its surrounding function. Subagents return findings only; they do NOT edit files.

Required return shape (every kind):
```json
{
  "findings": [{"location": "path:line", "issue": "...", "fix": "concrete change"}]
}
```

Defensive-fallback challenges blow past the per-message Agent budget on any non-trivial branch. When the subagent count exceeds ~30, use the Workflow tool — this skill invocation counts as explicit opt-in.

### 4. Apply every finding

Every returned finding is a reasoned defect. Apply the concrete fix for every one via `Edit`, regardless of size — a redundant comment gets removed just like a broken abstraction gets restructured. Size is not a filter; only whether the finding stands up is.

Skip a finding only when it is demonstrably wrong (the subagent misread the code, the "fix" would break behavior, the evidence chain has a hole). When skipping, note it in the final report with the reason. Never skip because the change feels small, cosmetic, or optional.

## Comment review rules

For every comment **added or changed** in the diff, flag it if any of:

- It restates what the code already says (e.g. `// increment counter` above `counter++`, a docstring that just echoes the function name). Comments are strictly opt-in — when in doubt, remove.
- It mentions a file, function, or feature that no longer exists in the final state.
- It references uncommitted documents — reports, specs, design notes, AI-conversation transcripts.
- It references in-branch history: "previously we", "originally this used X", "after the refactor", "renamed from", "removed Y".
- It uses agent/user voice: "the user asked us to", "Claude implemented this", "per request". Required voice: author voice (`I` / `we`) or passive — as if a human committer wrote it.
- It is a multi-line block where one line would do, or a verbose docstring on an internal helper.

**Keep** comments that record non-obvious decisions, evidence chains with permalink URLs, hidden constraints, subtle invariants, or surprising behavior.

For each flagged comment the finding names the concrete fix: delete, rewrite to author/passive voice, trim to one line, replace with a version that carries only the real information.

## Code-structure review rules

Review the final-state file ignoring all test code. Distinguish business code from tests by path and by content (`describe(`, `it(`, `test(`, `expect(`, fixture files, mock factories).

Flag if any of:

- A helper function / constant / type is referenced from exactly one site, and inlining it would not hurt readability. Locality beats DRY when DRY = 1. Helpers used only inside one function belong inside that function (or inlined).
- Reading order forces jumping: helpers defined before their single caller for no reason, callbacks declared ahead of the function that uses them, related logic spread across the file. Code should read top-to-bottom in execution order where possible.
- **Thin / unnecessary encapsulation**: one-line wrappers that add no semantic value, single-implementation interfaces with no mock-injection justification (and per anti-test-bending, mock injection alone is not justification), classes wrapping a single function, types that just rename a primitive at one site, getters that return a private field unchanged.
- A field / parameter / return value is typed optional (`?`, `| undefined`, nullable, `Option<T>`) but every business code path either sets it or asserts it non-null. If business-required, it must be required in the type. (Defensive-fallback review attacks the same problem from the operator side; both passes reach the same conclusion.)
- **Anti-test-bending**: any split, interface, dependency-injection, or exposed internal that exists solely to make testing easier. Pretend the test file does not exist — if removing the test would let you collapse the structure, the structure is wrong. Business serves business; tests adapt to business, never the reverse.
- **Patching traces**: anything that reads as "added later" rather than "designed once":
  - Sibling code paths that differ only because they were written at different times.
  - Names like `fooNew`, `fooV2`, `processData2`, `handleClickFinal` when the old version is gone.
  - Backwards-compat shims for a feature that has no released version.
  - Dead flags / branches never flipped within this branch.
  - Re-export shims or alias types kept "just in case".

End state must look like one sitting by one author who knew the final design from the start.

Every flagged issue produces a concrete fix — inline the helper, reorder the definitions, collapse the wrapper, tighten the type, rename the symbol, restructure the file, merge the sibling paths. Public-API renames, cross-package type changes, and behavior-affecting merges are all in scope. Update every call site as part of the same fix; do not stop at the declaration.

## Defensive-fallback review rules

Every `??`, `?.`, `||` (used as fallback, not boolean OR), and `if (!x)` (used as guard, not as a domain condition) in changed business code is **suspect by default**. The base position is: errors should propagate, not be swallowed; missing data should throw at the access site, not be silently substituted. Each occurrence must earn its keep.

The subagent answers one question, with concrete `path:line` evidence from across the repo (callers, assignment sites, boundary parsers — not just the file under review):

> Does business code actually pass `undefined` / `null` / a falsy value here, AND does it actually need to?

Both halves matter. "It might in the future" is not a yes. "The type allows it" is not a yes — the type itself may be defensive. When the value originates at an external boundary (HTTP body, env, file, FFI, third-party SDK), the right move is almost always normalize-at-the-boundary (parse / validate / assert once), not fallback-at-the-use-site forever.

### Verdicts

| Verdict | Meaning | Evidence required | Fix |
|---|---|---|---|
| **Necessary** | Real domain case where absence happens, AND the fallback semantic is correct (not a swallowed error). | A concrete `path:line` where a caller / assignment omits the value, plus a one-line domain reason the default is correct. | Keep — no finding. |
| **Should propagate** | Absence is a bug or invariant violation, not a domain case. | Inbound trace shows every caller passes the value; absence would mean a broken upstream. | Remove the defensive form: direct access (let it throw at use), explicit `if (!x) throw` / `assert` / `invariant`, or delete the `?.` / `??`. |
| **Unreachable** | No caller omits the value; the type is optional defensively. | Inbound trace shows every caller passes the value; the optional type has no real domain case. | Tighten the type to required and remove the fallback. Update every consumer of the type in the same edit, including across package boundaries. |
| **Wrong default** | Absence is real, but the default value misrepresents the domain. | A concrete omitting site exists, but the chosen default produces a downstream lie (`count ?? 0` collapses an averaging bug into silent zero). | Replace with the correct behavior: throw at the access site, propagate the optional, or use the domain-correct default. Pick based on which one preserves truth downstream. |

### Out of scope (the subagent confirms and returns no finding)

- `||` whose operands are clearly boolean (`isAdmin || isOwner`, `loading || error`). Only `||` used as a fallback for a non-boolean is in scope.
- `?.` on values the type system genuinely admits as absent from a real domain case the subagent confirms (DOM `querySelector`, `Map.get`, `.find()`, optional config keys). The challenge still runs; the verdict is **Necessary**.
- `if (!x) throw …` / `if (!x) { invariant(…) }` / `x ?? (() => { throw … })()` — these already propagate. Confirm and move on.
- The `?` in TypeScript optional parameters / fields that DO have callers omitting them, when the omission is part of the documented domain.

### Clustering

Per-occurrence is the default. The single permitted cluster is **same defended root, same function, contiguous reads**: `config?.a`, `config?.b`, `config?.c` inside one function, all defending `config`, may be handled by one subagent. Anything beyond that — different roots, different functions, non-contiguous — gets its own subagent.

## Final report

```
## Cleanup complete

Fixed N items across M files:
- src/a.ts: removed 3 redundant comments, inlined helper `formatX` (single caller)
- src/b.ts: rewrote agent-voice on lines 12 and 47, dropped `// removed Y` placeholder
- src/c.ts: tightened `userTag` from optional to required (no caller omits), updated 4 consumers
- src/d.ts: removed 4 unjustified `??` fallbacks (no caller omits), converted `if (!user) return` to `if (!user) throw new Error("user required")`, collapsed `req.body?.payload?.id` to `req.body.payload.id` (boundary parse already guarantees shape)
- src/e.ts: replaced `count ?? 0` in `averageOf` with a throw — 0 was silently masking upstream bugs

Skipped 0 findings.
```

If any finding was skipped because it was demonstrably wrong, list each under a `Skipped` section with the reason. If the working tree was dirty when cleanup started, list any unstaged files at the end so the user knows what to stage / discard before committing.

## What this skill does NOT do

- Does not commit. The user reviews and commits.
- Does not run tests. Cleanup is a structural pass; the user runs the test suite separately if desired.
- Does not touch test files. Test cleanup is a separate concern.
