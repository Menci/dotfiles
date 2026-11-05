---
name: finalizing-pull-request
description: Finalize specified Pull Requests only when the user explicitly requests PR finalization or invokes this skill for them. Prefer CI and reusable checks, maintain accurate PR text, draft squash messages, squash by default unless the user requests no merge, then pull the primary base checkout and clean up the PR's child worktree. Supports individual PRs and stacks landing directly on main; never activates implicitly.
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

Compare the author with the authenticated GitHub user. Assess the title and complete body against the final diff before editing. Change the title wording only when its format is incorrect, it states something false, or the task changed and left it behind. Do not replace an accurate, correctly formatted, current title merely because another wording is also valid.

For another person's PR, preserve an accurate, correctly formatted title and body. When the final diff has departed from the original description, rewrite the complete body within the author's existing format, headings, language, and level of detail. Update its verification status in that same format. Change the title only when it no longer describes the final scope or its format conflicts with the project's conventions. Do not impose a new template or retitle merely to match a preferred wording. Unwrapping hard-wrapped paragraphs is a formatting correction, not a new template.

For an owned PR, keep accurate text or rewrite it as a coherent description of the final diff, as if submitting it for the first time. The body is Markdown: keep each paragraph and list item on one unwrapped source line, and unwrap any hard-wrapped paragraph even when the wording is otherwise accurate. Follow the repository template and use task lists for the Test Plan when appropriate.

Establish one canonical title for every PR. The GitHub PR title must equal that canonical title, and the squash subject must use the exact same text followed by ` (#N)`. This synchronization is mandatory even when neither title needs new wording. If either side differs, update the side that does not match the preserved or corrected canonical title before merging.

For every rewrite, preserve reusable checked results, remove discarded approaches/review history, and remove personal information beyond identities already exposed by Git. Public GitHub/npm/CDN references are fine; machine-specific paths, unrelated handles, personal IPs, and private domains are not. Describe the final problem, behavior, decisions, and relevant validation. Write the whole revised body, not appended correction notes. Use a body file or structured tool argument to preserve its formatting. Do not post PR comments without separate authorization.

## Verify with CI and reuse completed checks

If the project has CI, prefer its results for the verified PR head over running equivalent checks locally. Inspect relevant workflows and check results, wait for pending runs, and fix failures. Use local checks for coverage CI does not provide, diagnosis, or projects without applicable CI. Missing or not-yet-created check runs do not establish success.

Treat already-checked PR items as completed unless a relevant change or contradictory evidence invalidates them. Do not require old logs merely to reuse an explicitly recorded checked result. Relevant changes include tested code, dependencies, configuration, environment, or external behavior covered by that item. Re-evaluate only affected items; unrelated changes do not invalidate the whole Test Plan.

CI evidence must correspond to the final head or demonstrably unchanged tested state. A push or conflict resolution requires inspecting the new runs and determining which other results remain valid. Record the checked head OID and reject a different head at merge time.

For browser checks, use repository headless tooling or an existing/temporary browser installation. Leave checks requiring genuinely unavailable devices, services, or accounts incomplete and explain them. Distinguish optional unavailable checks from merge-blocking requirements; resolve blockers before merging. Update verification status without rewriting accurate prose just to impose a task-list format.

## Draft the squash message

Write a coherent narrative of the final feature or fix, not the branch's evolution. Give the subject one intent and match recent base-branch commit style. If no honest unifying intent exists, surface the need to split the PR. End the squash subject with ` (#N)`. Hard-wrap its body at approximately 72 columns unless the project consistently uses another width, and apply the PR body's personal-information rule.

A commit message is plain text, not Markdown, and this wrapping applies to it alone. Keep the body as wrapped prose paragraphs; allow only lightweight inline emphasis such as `**bold**` or backticks, and never headings, bullet lists, numbered lists, tables, fenced blocks, block quotes, or horizontal rules. Structure that needs Markdown belongs in the PR body. Do not carry the PR body's format, wrapping, or length into the commit.

Use the canonical PR title as the squash subject wording and append ` (#N)`. The title file holds the canonical title alone; appending the reference exactly once is the merge script's job, so no message file ever stores the suffix. If the title does not meet commit conventions, correct the canonical title and update the PR title before merging. Do not independently rewrite an already accurate, correctly formatted, current title or squash subject; synchronization requires identical wording, not unnecessary rewording.

### Retained human contributions

`Co-Authored-By` represents retained semantic authorship, including concrete applied reviewer suggestions, not integration, branch maintenance, or tool operation. Inspect PR-specific non-merge commits and suggestions against the final diff. Include a non-creator human only when their contribution survives and a valid Git name/email identity is available. Never infer an email.

Exclude base authors, merge-only operators, mechanical integration, bots, `web-flow`, AI identities, generated commits, and contributions absent from the final diff. Omit uncertain trailers.

Present the complete squash message in a fenced `text` block, subject line and ` (#N)` suffix included, along with verification and any unresolved items. When merging is authorized and blockers are resolved, continue without waiting for another confirmation. If the user requested no merge, deliver the prepared result and stop there.

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

pr=123
repo=owner/repository
base=main
head=REVIEWED_HEAD_OID

title="$(cat "$script_dir/title.txt")"
body="$(cat "$script_dir/body.txt")"

# title.txt holds the canonical title alone. Appending the reference here is
# the only place it is written, so the suffix cannot be stated twice.
if [[ "$title" =~ \(#[0-9]+\)$ ]]; then
  printf 'title.txt must not carry a PR reference: %s\n' "$title" >&2
  exit 1
fi
subject="$title (#$pr)"

gh pr checks "$pr" --repo "$repo" --watch --fail-fast
actual_base="$(gh pr view "$pr" --repo "$repo" --json baseRefName --jq .baseRefName)"
[[ "$actual_base" == "$base" ]]
gh pr merge "$pr" --repo "$repo" --squash \
  --match-head-commit "$head" \
  --subject "$subject" --body "$body"
```

Wait for the relevant CI checks to appear before relying on watch mode. Choose the CI wait scope from the project's requirements; do not weaken it simply to get a merge through. Keep output streaming and check status while a long-running script executes. Never use `--admin` to bypass blockers.

Read all three files in full as one execution unit and validate `squash.sh` with `bash -n`. Confirm the literal PR/repository/base/head, exact message content, attribution, CI wait, and cleanup paths. Confirm `body.txt` is hard-wrapped prose with no block-level Markdown, then compare the PR body separately to confirm it is unwrapped Markdown and was not given the commit's wrapping. Review the resolved merge command against the files. Execute the reviewed script without reconstructing the command or modifying the files after review. If review finds an issue, rewrite and review the files again.

Confirm the subject the script will send rather than trusting that a title file implies it. `title.txt` must hold the canonical title with no reference; the script's `subject` assignment supplies ` (#N)`. Check both mechanically before merging, and compare the result with how the base branch actually names its commits:

```bash
# The title file carries the canonical title alone: no output expected.
grep -En '\(#[0-9]+\)$' .tmp/<script-dir>/title.txt || true

# Every recent base commit ends in a reference, so the reviewed subject must
# too. Only commits predating the convention may appear here.
git log --format=%s -20 origin/main | grep -v '(#[0-9]*)$'
```

The second command should list nothing but commits predating the convention. An entry naming the subject about to be merged means the reviewed message is malformed.

The exit trap must clean only this script's temporary files and directory on success or failure while preserving the operation's exit status. Verify that cleanup completed even when the script fails. A changed head, failed CI, conflict, or unmet protection stops the merge; inspect the cause, repair within scope, and prepare a freshly reviewed script and message as needed.

## Verify the squash landed

Query the PR after execution and verify it is merged into the intended base. A queued or auto-merge request is still pending; wait for the actual merge and verify its result. Record the squash commit OID, fetch the intended remote base, and prove reachability, for example:

```bash
git merge-base --is-ancestor "$merge_oid" origin/main
```

Also read back the landed subject and compare it with the reviewed one. The earlier checks keep the sent string correct; this one catches a merge that named the commit differently from the reviewed message, while the difference is still visible rather than discovered later in the log:

```bash
git log -1 --format=%s "$merge_oid"
[[ "$(git log -1 --format=%s "$merge_oid")" == "CANONICAL_TITLE (#N)" ]]
```

For stacks, confirm `baseRefName: main` before every merge and prove each squash OID is reachable from `origin/main` before proceeding. Stop the stack on a verification failure and resolve it before processing the next PR.

## Synchronize local state after the squash

Once the squash commit is reachable from the remote base, bring local checkouts in line with it. These steps change local state only; the merged PR is already final.

### Update the primary base checkout

Read `git worktree list --porcelain`, whose first record is the primary worktree. When that record's branch is the intended base branch, update it in place:

```bash
git -C <primary-worktree> pull --rebase --autostash <remote> <base-branch>
```

Naming the remote and branch keeps the pull independent of the checkout's upstream configuration. The rebase keeps base history linear, and the autostash carries uncommitted modifications across the update. Resolve conflicts against the landed squash and the local base commits, then finish the operation:

- A conflict while replaying local base commits leaves an interrupted rebase. Resolve the files, run `git -C <primary-worktree> rebase --continue`, and repeat until the rebase ends. `git rebase --abort` returns to the pre-pull state.
- A conflict while restoring the autostash is reported after the rebase has already succeeded, with unmerged paths in the index. Resolve the files, then discard the stash with `git stash drop`. When those edits cannot be resolved now, `git reset --hard` returns to the updated base while the autostash entry survives in `git stash list`, so the edits stay recoverable with `git stash pop`; report that entry instead of dropping it.

Never resolve either case by dropping or rewriting the squash commit. When no resolution preserves the landed squash together with the local work, abort the rebase or leave the stash in place, restore the pre-pull state, and report the blocker. Finish by proving the squash is in the checkout: `git -C <primary-worktree> merge-base --is-ancestor "$merge_oid" <base-branch>`.

When the primary worktree is checked out on another branch, its checkout stays as it is; the fetched remote base already proves the merge.

### Remove the PR's child worktree

When the PR head was developed in a linked worktree, that worktree and its local branch are this PR's scratch space once the squash lands. Take the path and branch from `git worktree list --porcelain`; never remove the primary worktree.

Before deleting anything, confirm the linked worktree's HEAD equals the reviewed head OID. A different HEAD carries commits the squash never landed; reconcile them so they either land or are explicitly declared disposable, and otherwise leave the worktree in place and report the discrepancy.

Preserve what the user identified as valuable by moving those files into the primary worktree's working tree once its checkout is current, keeping them uncommitted at the same relative paths unless the user named a destination. They are files to keep, not changes to record, so they take no commit and no branch. Never overwrite a path that already exists in the primary worktree; pick a distinct name and report it. The same holds for tracked modifications the squash did not absorb and that no one claimed: they belong to the working tree as uncommitted changes rather than to a commit. Untracked and ignored files that no one claimed — build outputs, dependency directories, logs — are disposable working traces.

Run the removal through the primary worktree:

```bash
git -C <primary-worktree> worktree remove --force <worktree-path>
git -C <primary-worktree> branch -D <head-branch>
```

`--force` covers modified tracked files, untracked files, and submodules; a locked worktree needs `--force` twice, and a lock left by this PR's tooling can be cleared first. If the directory is already gone, `git worktree prune` clears the stale record.

Then delete this PR's scratch state outside Git: temporary patch and export files, message files, and the reviewed squash-script directory. Verify that the worktree path and local branch are gone, that `git worktree list` no longer names the path, and that no temporary files remain.

When no linked worktree holds the PR head, skip the worktree removal and still clear this PR's scratch files. For a stack, remove a worktree once the last PR checked out in it has landed and been verified.

## Report the result

Report each PR and verified squash OID, what was pushed or updated, validation, and any incomplete checks with reasons. Include the base pull outcome and any conflicts resolved, each removed worktree and branch, every path carried over to the primary worktree, the working traces the cleanup discarded, and the post-cleanup verification. For a prepare-only request, include the exact prepared message and remaining blockers.
