---
name: finalizing-pull-request
description: Finalize specified Pull Requests only when the user explicitly requests PR finalization or invokes this skill for them. Prefer CI and reusable checks, maintain accurate PR text, draft squash messages, and squash by default unless the user requests no merge. Supports individual PRs and stacks landing directly on main; never activates implicitly.
---

# Finalizing Pull Requests

## Invocation and merge intent

Activate only for an explicit user request to finalize identified PRs, including an invocation of this skill with a specific PR. Merely encountering a PR during implementation, review, or another workflow does not activate it.

An explicit finalization request authorizes the agent to complete this workflow and perform the squash merge by default. Respect instructions to stop before merging, prepare only, or leave the merge to the user. Do not ask who should squash when the user's request already establishes this default. Keep authorization limited to the identified PRs; do not infer permission to merge unrelated PRs, push local main, or bypass repository protections.

## Establish the order and final diff

For one PR, record its intended base. For stacks intended to land on `main`, list the complete stack and process from the PR closest to `main` upward. Finish and verify each squash on `main` before processing the next PR.

After its predecessor lands, change the next PR's base to `main` if necessary and inspect the resulting diff. Ensure only its intended incremental change remains. A squash may leave predecessor commits visible in the next branch; reconcile that history if necessary to obtain the correct incremental diff. Do not replay already-landed changes. This stack-specific reconciliation is separate from routinely updating a branch to the latest base.

Push intended local feature-branch changes and inspect mergeability. Merge the current base into the feature branch only when conflicts require it; resolve and push. Prefer merging over rebasing for conflict resolution. A cleanly mergeable PR does not need the latest base merged into it. Fetching the base for inspection or verification does not imply integrating it. An unknown mergeability result needs another query, not an assumed conflict.

Confirm the intended base and record the exact PR head OID before final verification.

## Maintain accurate PR text

Compare the author with the authenticated GitHub user. Assess the title and complete body against the final diff before editing.

For another person's PR, preserve an accurate, correctly formatted title and body. When the final diff has departed from the original description, rewrite the complete body within the author's existing format, headings, language, and level of detail. Update its verification status in that same format. Change the title only when it no longer describes the final scope or its format conflicts with the project's conventions. Do not impose a new template or retitle merely to match a preferred wording.

For an owned PR, keep accurate text or rewrite it as a coherent description of the final diff, as if submitting it for the first time. Follow the repository template, use natural Markdown wrapping, and use task lists for the Test Plan when appropriate.

For every rewrite, preserve reusable checked results, remove discarded approaches/review history, and remove personal information beyond identities already exposed by Git. Public GitHub/npm/CDN references are fine; machine-specific paths, unrelated handles, personal IPs, and private domains are not. Describe the final problem, behavior, decisions, and relevant validation. Write the whole revised body, not appended correction notes. Use a body file or structured tool argument to preserve its formatting. Do not post PR comments without separate authorization.

## Verify with CI and reuse completed checks

If the project has CI, prefer its results for the verified PR head over running equivalent checks locally. Inspect relevant workflows and check results, wait for pending runs, and fix failures. Use local checks for coverage CI does not provide, diagnosis, or projects without applicable CI. Missing or not-yet-created check runs do not establish success.

Treat already-checked PR items as completed unless a relevant change or contradictory evidence invalidates them. Do not require old logs merely to reuse an explicitly recorded checked result. Relevant changes include tested code, dependencies, configuration, environment, or external behavior covered by that item. Re-evaluate only affected items; unrelated changes do not invalidate the whole Test Plan.

CI evidence must correspond to the final head or demonstrably unchanged tested state. A push or conflict resolution requires inspecting the new runs and determining which other results remain valid. Record the checked head OID and reject a different head at merge time.

For browser checks, use repository headless tooling or an existing/temporary browser installation. Leave checks requiring genuinely unavailable devices, services, or accounts incomplete and explain them. Distinguish optional unavailable checks from merge-blocking requirements; resolve blockers before merging. Update verification status without rewriting accurate prose just to impose a task-list format.

## Draft the squash message

Write a coherent narrative of the final feature or fix, not the branch's evolution. Give the subject one intent and match recent base-branch commit style. If no honest unifying intent exists, surface the need to split the PR. End the squash subject with ` (#N)`. Wrap its body at approximately 72 columns unless the project consistently uses another width, and apply the PR body's personal-information rule.

Use a preserved, accurate PR title as the subject wording where it meets commit conventions. If commit formatting differs, provide an explicit squash subject without changing an otherwise valid title on another person's PR. The squash command supplies its own subject; title synchronization is not mandatory.

### Retained human contributions

`Co-Authored-By` represents retained semantic authorship, including concrete applied reviewer suggestions, not integration, branch maintenance, or tool operation. Inspect PR-specific non-merge commits and suggestions against the final diff. Include a non-creator human only when their contribution survives and a valid Git name/email identity is available. Never infer an email.

Exclude base authors, merge-only operators, mechanical integration, bots, `web-flow`, AI identities, generated commits, and contributions absent from the final diff. Omit uncertain trailers.

Present the complete squash message in a fenced `text` block, along with verification and any unresolved items. When merging is authorized and blockers are resolved, continue without waiting for another confirmation. If the user requested no merge, deliver the prepared result and stop there.

## Prefer a reviewed wait-and-squash script

For an agent squash, prefer a non-interactive script that waits for CI, merges the reviewed head using the reviewed subject/body, and deletes itself and its temporary message files on exit. Use a uniquely named directory inside the repository worktree, outside Git internals and user configuration. Keep `title.txt`, `body.txt`, and `squash.sh` together.

Use a literal PR number, explicit repository, intended base, and reviewed head OID. Resolve message paths relative to the script. Include the CI wait when applicable; for projects without CI, omit it after completing applicable verification. For example, substitute concrete reviewed values before executing:

```bash
#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cleanup() {
  local operation_status="$?" cleanup_status=0
  trap - EXIT
  rm -- "$script_dir/squash.sh" "$script_dir/title.txt" "$script_dir/body.txt" || cleanup_status="$?"
  rmdir -- "$script_dir" || cleanup_status="$?"
  if (( operation_status != 0 )); then
    exit "$operation_status"
  fi
  exit "$cleanup_status"
}
trap cleanup EXIT

squash_title="$(cat "$script_dir/title.txt")"
squash_body="$(cat "$script_dir/body.txt")"

gh pr checks 123 --repo owner/repository --watch --fail-fast
actual_base="$(gh pr view 123 --repo owner/repository --json baseRefName --jq .baseRefName)"
[[ "$actual_base" == "main" ]]
gh pr merge 123 --repo owner/repository --squash \
  --match-head-commit REVIEWED_HEAD_OID \
  --subject "$squash_title" --body "$squash_body"
```

Wait for the relevant CI checks to appear before relying on watch mode. Choose the CI wait scope from the project's requirements; do not weaken it simply to get a merge through. Keep output streaming and check status while a long-running script executes. Never use `--admin` to bypass blockers.

Read all three files in full as one execution unit and validate `squash.sh` with `bash -n`. Confirm the literal PR/repository/base/head, exact message content, PR reference, attribution, CI wait, and cleanup paths. Review the resolved merge command against the files. Execute the reviewed script without reconstructing the command or modifying the files after review. If review finds an issue, rewrite and review the files again.

The exit trap must clean only this script's temporary files and directory on success or failure while preserving the operation's exit status. Verify that cleanup completed even when the script fails. A changed head, failed CI, conflict, or unmet protection stops the merge; inspect the cause, repair within scope, and prepare a freshly reviewed script and message as needed.

## Verify the squash landed

Query the PR after execution and verify it is merged into the intended base. A queued or auto-merge request is still pending; wait for the actual merge and verify its result. Record the squash commit OID, fetch the intended remote base, and prove reachability, for example:

```bash
git merge-base --is-ancestor "$merge_oid" origin/main
```

For stacks, confirm `baseRefName: main` before every merge and prove each squash OID is reachable from `origin/main` before proceeding. Stop the stack on a verification failure and resolve it before processing the next PR.

Report each PR and verified squash OID, what was pushed or updated, validation, and any incomplete checks with reasons. For a prepare-only request, include the exact prepared message and remaining blockers.
