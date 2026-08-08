---
name: finalizing-pull-request
description: Finalize one or more Pull Requests through pre-squash verification, description and title synchronization, squash-message drafting, and an optional user-authorized squash merge. Use for individual PRs and stacked PRs that must each land directly on main.
---

# Finalizing Pull Requests

## 1. Establish the merge order

For one PR, use its current base as the synchronization target.

For stacked PRs that will land on `main`, list the complete stack and process it from the PR closest to `main` to the topmost PR. Complete every step for one PR, including verifying its squash commit on `main`, before processing the next PR. Do not merge the stack as a batch.

After the preceding PR has landed, change the next PR's base to `main` if necessary. Fetch `main`, synchronize it into the feature branch, and inspect the resulting diff to ensure that the PR contains only its intended incremental change. Confirm immediately before every squash that the PR's `baseRefName` is `main`.

## 2. Synchronize and push

Push local changes and fetch the current base. If the PR conflicts with its base, merge the base into the feature branch, resolve conflicts, and push again. Prefer merging over rebasing because the PR will be squashed and a merge avoids replaying conflict resolution across feature commits.

## 3. Rewrite the PR description only when owned by the current user

Compare the PR author with the authenticated GitHub user. If they differ, do not edit the description or comment unless the user explicitly asks.

For an owned PR, rewrite the body as a single-pass description of the final diff, as if submitting it for the first time. Do not mention discarded approaches, review rounds, or in-branch history.

- Use natural Markdown wrapping rather than commit-message hard wrapping.
- Express the Test Plan as a GitHub task list.
- Preserve a checked item when its prior result remains reusable under step 4; do not reset all checkboxes mechanically.
- Remove personal information beyond identities already exposed by Git. Public services such as GitHub, npm, and public CDNs are fine; local paths, unrelated handles, personal IPs, and private domains are not.

## 4. Verify the Test Plan

For each task-list item, first decide whether an existing checked result is still valid. Do not rerun an already-checked item when nothing that could affect its result has changed since it was checked. This includes the tested code, relevant dependencies and configuration, synchronized base, runtime environment, and any external service behavior the item is intended to verify.

Reuse a prior result only when its successful output is available and the unchanged state can be established. If relevant state changed or the prior evidence cannot be verified, rerun the item. Use a headless browser for browser-driven checks through the repository's tooling or a one-off headless Chromium. Fix failures before checking an item.

Leave checks that genuinely require an unavailable device, paid service, external account, or equivalent resource unchecked, and explain each one in the final handoff. If step 3 allowed description edits, update the checkboxes; otherwise report results locally without editing or commenting on the PR.

## 5. Draft the squash commit message

Write a single-pass narrative of the final feature or fix, not a changelog of the PR's evolution.

- Give the subject one coherent intent. If the diff has no honest unifying subject, raise that the PR should be split.
- End the subject with ` (#N)`, where `N` is the PR number.
- Match recent commit-message style on the base branch.
- Hard-wrap the body at approximately 72 columns unless the project consistently uses another width.
- Remove personal information under the same rule as the PR description.

### Attribute only retained human contributions

`Co-Authored-By` represents authorship of content retained in the final PR diff, not branch maintenance, integration work, tool operation, or commits that merely became reachable through a base merge.

Build candidates from non-merge commits in the synchronized `base..head` range and applied review suggestions. For every non-creator human, confirm that their semantic contribution survives in the final diff and that a valid Git name/email identity is available. Never infer an email.

Include retained PR-specific work by a non-creator human and retained concrete reviewer suggestions with valid identities. Exclude base authors, merge-only operators, identities used only for mechanical integration, bots, `web-flow`, AI identities, generated commits, and contributions absent from the final diff. When uncertain, omit the trailer.

Output the complete message directly in chat as a fenced `text` block. Do not post it as a PR comment.

## 6. Sync the PR title

The PR title becomes GitHub's default squash subject, so set it to the drafted subject without the trailing ` (#N)`. This step has no ownership gate.

```bash
gh pr edit <N> --title "<subject without (#N)>"
```

## 7. Report and choose who squashes

Report what was pushed, every unchecked Test Plan item and its reason, the updated PR title, and the complete squash message in the same fenced `text` block.

Ask the user to choose between:

1. The user performs the squash merge.
2. The agent performs the squash merge using the drafted subject and body.

Do not merge without an explicit choice. If the current request already clearly made this choice, do not ask again; continue after the verification report.

## 8. Perform an agent-authorized squash from reviewed files

When the user authorizes the agent to squash, create a uniquely named temporary directory inside the repository worktree. Create these three files in it:

- `title.txt` containing the exact squash subject, including ` (#N)`.
- `body.txt` containing the exact squash body.
- `squash.sh` containing the complete non-interactive squash command and reading its subject and body from the adjacent text files.

Do not place these files in Git internals or a user-level configuration directory. Put the literal PR number in `squash.sh`; do not obtain it from an unreviewed environment variable or positional argument. Resolve the text-file paths relative to the script so its behavior does not depend on the caller's working directory. A suitable structure is:

```bash
#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
squash_title="$(cat "$script_dir/title.txt")"
squash_body="$(cat "$script_dir/body.txt")"

gh pr merge "<N>" --squash --subject "$squash_title" --body "$squash_body"
```

Read `squash.sh`, `title.txt`, and `body.txt` together in full and review them as one execution unit. Validate the script syntax and confirm that:

- `squash.sh` contains the correct literal PR number, only the intended `gh pr merge` operation, the `--squash`, `--subject`, and `--body` flags, and exact paths to the adjacent reviewed files.
- `title.txt` contains exactly one nonempty line, matches the synchronized PR title apart from ` (#N)`, and ends with the correct PR reference.
- `body.txt` is the complete reviewed narrative with the intended wrapping and only valid trailers.
- None of the files contains shell quoting artifacts, placeholders, personal information, or text from another PR.

After reading the three files, restate the fully resolved command that will run, including the PR number, every flag, the exact subject, and the complete body. Compare that restatement against all three files and explicitly confirm it is correct. If anything is wrong, rewrite the affected file, then reread and review all three files and restate the resolved command again.

Execute the reviewed `squash.sh` without reconstructing or retyping its merge command. Do not modify any of the three files between the successful review and execution.

As soon as `squash.sh` returns, delete `squash.sh`, `title.txt`, and `body.txt`, then remove their now-empty temporary directory. Perform this cleanup before merge verification, including when the script fails, while preserving its exit status for reporting.

## 9. Verify the squash landed on the intended branch

Query the PR after the command and verify that it is merged. Record its resulting squash commit OID.

For every stacked PR, also verify that the PR reported `baseRefName: main` at merge time. Fetch `origin/main` after each squash and prove that the recorded OID is reachable from it, for example with:

```bash
git merge-base --is-ancestor "$merge_oid" origin/main
```

Treat a PR as complete only when this command succeeds. Stop the stack if verification fails; do not proceed to the next PR until the current PR's squash commit is on `main`. Report each PR number and verified commit OID in the final handoff.
