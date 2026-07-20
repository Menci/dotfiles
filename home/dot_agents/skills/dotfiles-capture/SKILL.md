---
name: dotfiles-capture
description: Capture intentional changes made directly to chezmoi targets back into the dotfiles source — modifier templates and directly managed files alike. Use when application-managed or manually edited dotfiles should be synchronized into the dotfiles repository for review without applying changes to the live home directory.
---

# Dotfiles Capture

Capture intentional edits made directly to chezmoi targets back into the source repository for review, without ever writing to the live home directory.

## Survey every drifted target

1. Locate the active chezmoi source and destination, inspect the working tree, and preserve unrelated changes.
2. Run `chezmoi status` and `chezmoi diff` to enumerate every managed entry whose live target drifted from source. Do not rely on a hard-coded list, and do not restrict the survey to `modify_*` entries — classify each drifted entry by how chezmoi manages it: plain file, symlink, template (`*.tmpl`), or `modify_*` template.
3. Read each diff to determine the drift direction: whether the live target is ahead (an intentional in-place edit, which is a capture candidate) or the source is ahead (a pending forward apply that has not reached this machine — leave it untouched, never capture it). Only live-ahead changes are captured.

## Plain files and symlinks

4. Capture a live-ahead plain file or symlink with `chezmoi re-add <target>`, which rewrites only the source and never touches live. Never re-add when the source is ahead. Never re-add a `*.tmpl`: re-add would overwrite the template with its rendered output — instead hand-edit the template or its data, and only for changes that are genuinely intentional and portable; otherwise leave the drift as a pending apply.

## modify_ templates

Modifier templates cannot be captured with re-add, and they pass most of their target through untouched, so their narrow managed slice must be isolated from pass-through content, secrets, and machine-specific values.

5. Recursively map every `modify_*` source entry to its target. Copy the live targets into an isolated destination and run chezmoi apply there for only those targets, excluding scripts. Also apply them to an empty isolated destination to expose content that the modifiers currently only pass through. Never apply to the live destination.
6. Compare the live files, the applied copies, and the empty baseline. Read each modifier and distinguish intentional portable configuration from fixed bootstrap markers, generated state, machine-specific values, and secrets. Update every applicable modifier or its source data so intentional changes are managed; never replace a partially managed target with its complete live contents.
7. Recreate the isolated destinations from the live files and apply again. Verify that managed values reach a fixed point, pass-through content remains unchanged, templates render successfully, and no installer or run script executes.

## Finish

8. Make reasonable decisions and complete all captures without pausing for confirmation. Review the repository diff for secrets and machine-specific paths, leave the changes uncommitted, then briefly summarize what was captured, what was deliberately excluded, and ask the user to review the diff.
