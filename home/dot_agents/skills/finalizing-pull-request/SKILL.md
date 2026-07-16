---
name: finalizing-pull-request
description: Use when a Pull Request is ready for final pre-squash verification, description and title synchronization, squash-message drafting, and an optional user-authorized squash merge.
---

# Finalizing a Pull Request

## 1. Synchronize and push

Push local changes and fetch the current base. If the PR conflicts with its base, merge the base into the feature branch, resolve conflicts, and push again. Prefer merging over rebasing because the PR will be squashed and a merge avoids replaying conflict resolution across feature commits.

## 2. Rewrite the PR description only when owned by the current user

Compare the PR author with the authenticated GitHub user. If they differ, do not edit the description or comment unless the user explicitly asks.

For an owned PR, rewrite the body as a single-pass description of the final diff, as if submitting it for the first time. Do not mention discarded approaches, review rounds, or in-branch history.

- Use natural Markdown wrapping rather than commit-message hard wrapping.
- Express the Test Plan as a GitHub task list.
- Preserve a checked item when its prior result remains reusable under step 3; do not reset all checkboxes mechanically.
- Remove personal information beyond identities already exposed by Git. Public services such as GitHub, npm, and public CDNs are fine; local paths, unrelated handles, personal IPs, and private domains are not.

## 3. Verify the Test Plan

For each task-list item, first decide whether an existing checked result is still valid. Do not rerun an already-checked item when nothing that could affect its result has changed since it was checked. This includes the tested code, relevant dependencies and configuration, synchronized base, runtime environment, and any external service behavior the item is intended to verify.

Reuse a prior result only when its successful output is available and the unchanged state can be established. If relevant state changed or the prior evidence cannot be verified, rerun the item. Use a headless browser for browser-driven checks through the repository's tooling or a one-off headless Chromium. Fix failures before checking an item.

Leave checks that genuinely require an unavailable device, paid service, external account, or equivalent resource unchecked, and explain each one in the final handoff. If step 2 allowed description edits, update the checkboxes; otherwise report results locally without editing or commenting on the PR.

## 4. Draft the squash commit message

Write a single-pass narrative of the final feature or fix, not a changelog of the PR's evolution.

- Give the subject one coherent intent. If the diff has no honest unifying subject, raise that the PR should be split.
- End the first line with ` (#N)`, where `N` is the PR number.
- Match recent commit-message style on the base branch.
- Hard-wrap the body at approximately 72 columns unless the project consistently uses another width.
- Remove personal information under the same rule as the PR description.

### Attribute only retained human contributions

`Co-Authored-By` represents authorship of content retained in the final PR diff, not branch maintenance, integration work, tool operation, or commits that merely became reachable through a base merge.

Build candidates from non-merge commits in the synchronized `base..head` range and applied review suggestions. For every non-creator human, confirm that their semantic contribution survives in the final diff and that a valid Git name/email identity is available. Never infer an email.

Include retained PR-specific work by a non-creator human and retained concrete reviewer suggestions with valid identities. Exclude base authors, merge-only operators, identities used only for mechanical integration, bots, `web-flow`, AI identities, generated commits, and contributions absent from the final diff. When uncertain, omit the trailer.

Output the complete message directly in chat as a fenced `text` block. Do not save it to a file or post it as a PR comment.

## 5. Sync the PR title

The PR title becomes the squash subject, so set it to the drafted first line without the trailing ` (#N)`. This step has no ownership gate.

```bash
gh pr edit <N> --title "<subject without (#N)>"
```

## 6. Report and choose who squashes

Report what was pushed, every unchecked Test Plan item and its reason, the updated PR title, and the complete squash message in the same fenced `text` block.

Ask the user to choose between:

1. The user performs the squash merge.
2. The agent performs the squash merge using the drafted subject and body.

Do not merge without an explicit choice. If the current request already clearly made this choice, do not ask again; follow it after the verification report. When authorized to merge, run the squash merge non-interactively, verify the PR is merged, and report the resulting merge commit.
