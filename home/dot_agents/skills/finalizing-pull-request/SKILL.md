---
name: finalizing-pull-request
description: Use when a Pull Request is ready for its final pre-squash verification and handoff.
---

# Finalizing a Pull Request

## 1. Push local changes

Push the branch. If the PR conflicts with its base, resolve the conflicts and push again. Prefer merging the base into the branch over rebasing: feature branches will be squashed, and a merge avoids resolving the same conflict across multiple commits.

## 2. Rewrite the PR description — only for a PR opened by the current user

Compare the PR author with the authenticated GitHub user. If they differ, skip this step entirely. Do not edit the description or comment on the PR unless the user explicitly asks.

For an owned PR, rewrite the body as a single-pass description of the final branch state, as if submitting the exact final diff for the first time. Do not mention discarded approaches, review rounds, or in-branch history.

- Use natural Markdown wrapping; do not hard-wrap prose like a commit message.
- Make the Test Plan a GitHub task list. Its checkboxes are updated in the next step.
- Remove personal information beyond identities already exposed by Git. This includes absolute local paths, unrelated personal handles, and personal IP addresses or domains. Public services such as GitHub, npm, and public CDNs are fine.

## 3. Run the Test Plan

Execute each task-list item. Use a headless browser for browser-driven checks, using the repository's existing tooling or a one-off headless Chromium. Check an item only after it passes, and fix failures before checking it.

Leave checks that genuinely require an unavailable real device, paid service, external account, or equivalent resource unchecked. Explain every unchecked item in the final handoff.

If step 2 allowed description edits, update its checkboxes. Otherwise, report results locally without editing or commenting on the PR.

## 4. Draft the squash commit message

Write a single-pass narrative of the final feature or fix, not a changelog of the PR's evolution.

- Give the subject one coherent intent. Do not list separate changes as “X + Y” or “X and Y.” If the diff has no honest unifying subject, raise that the PR should be split.
- End the first line with ` (#N)`, where `N` is the PR number.
- Match recent commit-message style on the base branch.
- Hard-wrap the body at approximately 72 columns unless the project consistently uses another width.
- Remove personal information under the same rule as the PR description.

### Attribute only the PR's own human contributions

`Co-Authored-By` represents authorship of content in the final feature diff. It does not represent branch maintenance, integration work, tool operation, or commits that merely became reachable from the branch.

Build the candidate set from the PR-owned delta against the current base, not from every author reachable in branch history:

1. Inspect non-merge commits in `base..head` after the base has been synchronized (for example, `git log --no-merges origin/<base>..HEAD`).
2. For each non-PR-creator human candidate, inspect the commit or applied review suggestion and confirm that their authored content remains in the PR's final feature diff.
3. Add a trailer only when that semantic contribution is confirmed and a valid Git name/email identity is available. Never infer or invent an email.

Include:

- A non-PR-creator human whose PR-specific commit contributes content retained in the final diff.
- A human reviewer whose concrete code or documentation suggestion was applied and retained, when a valid trailer identity is available.

Exclude:

- Authors of commits inherited from the base branch, including commits introduced by merging the base into the PR branch.
- The author or committer of a merge commit created only to synchronize the base or resolve conflicts.
- A Git identity used only by the person or agent operating tools, pushing, formatting, renumbering migrations after a collision, or performing other integration work.
- Bots, `web-flow`, AI identities, and generated commits.
- Anyone whose apparent contribution does not survive in the final PR diff.

Do not use `git log <merge-base>..HEAD` author output alone as proof of co-authorship: after a base merge, that history can include base authors and the integration operator. When uncertain whether a person authored retained feature content, omit the trailer rather than assigning false credit.

Output the message directly in chat as a fenced `text` block. Do not save it to a file or post it as a PR comment.

## 5. Sync the PR title

This step has no ownership gate. The PR title becomes the squash commit subject, so it must match the drafted first line without the trailing ` (#N)`; GitHub appends the PR number on squash.

Use:

```bash
gh pr edit <N> --title "<subject without (#N)>"
```

## 6. Hand off the squash

Report:

- What was pushed.
- Every unchecked Test Plan item and its reason.
- The complete squash commit message again in the same fenced `text` block.
- The updated PR title.

The user performs the squash merge.