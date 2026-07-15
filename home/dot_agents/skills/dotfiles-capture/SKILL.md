---
name: dotfiles-capture
description: Capture intentional changes made directly to chezmoi targets back into all applicable modify_ source entries. Use when application-managed or manually edited dotfiles should be synchronized into the dotfiles repository for review without applying changes to the live home directory.
---

# Dotfiles Capture

1. Locate the active chezmoi source and destination, inspect the working tree, and preserve unrelated changes.
2. Recursively enumerate every `modify_*` source entry and map each one to its target. Do not rely on a hard-coded list.
3. Copy the live targets into an isolated destination and run chezmoi apply there for only those targets, excluding scripts. Also apply them to an empty isolated destination to expose content that the modifiers currently only pass through. Never apply to the live destination.
4. Compare the live files, the applied copies, and the empty baseline. Read each modifier and distinguish intentional portable configuration from fixed bootstrap markers, generated state, machine-specific values, and secrets.
5. Update every applicable modifier or its source data so intentional changes are managed. Make reasonable decisions and complete all updates without pausing for confirmation; never replace a partially managed target with its complete live contents.
6. Recreate the isolated destinations from the live files and apply again. Verify that managed values reach a fixed point, pass-through content remains unchanged, templates render successfully, and no installer or run script executes.
7. Review the repository diff for secrets and machine-specific paths. Leave the changes uncommitted, then briefly summarize what was captured, what was deliberately excluded, and ask the user to review the diff.
