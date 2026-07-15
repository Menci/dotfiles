---
name: using-codex-cli
description: Use when an agent needs to call the `codex` CLI from another runtime, delegate work to Codex non-interactively, resume a Codex CLI session, capture Codex output, or coordinate cross-runtime agent handoffs.
---

# Using Codex CLI

Use `command codex exec` for non-interactive delegation. Preserve the caller's environment defaults unless the user explicitly asks for different model/configuration.

Always invoke the binary via `command codex`, never bare `codex`. A shell alias or function named `codex` (common in interactive profiles) would otherwise intercept the call and inject its own flags or wrapper behaviour; `command` bypasses that and runs the real executable.

## New Task

```bash
set -o pipefail
log=$(mktemp)
last=$(mktemp)
command codex --sandbox danger-full-access --dangerously-bypass-approvals-and-sandbox \
  exec --json -o "$last" -C "$PWD" "$PROMPT" </dev/null \
  | jq -cR --unbuffered 'fromjson? | {ts: (now|strflocaltime("%Y-%m-%d %H:%M:%S"))} + .' \
  | tee "$log"
session_id=$(jq -r 'select(.type == "thread.started") | .thread_id' "$log" | head -n 1)
test -n "$session_id" || { echo "codex: failed to acquire session id from $log" >&2; exit 1; }
```

Read the final assistant text from `$last`. Pass `$session_id` to `resume` for follow-up turns.

- `</dev/null` is required. Without it `codex exec` prints `Reading additional input from stdin...` and, if stdin is actually piped, appends piped data as a `<stdin>` block into the prompt.
- `set -o pipefail` is required. Without it `tee` masks codex's exit code and a failed delegation looks successful.
- The `jq` stage prepends a local-time `ts` to each event (codex's JSONL has no timestamps) and silently drops any non-JSON noise via `fromjson?`. `--unbuffered` is required, otherwise jq batches lines and timestamps cluster. `-o "$last"` is unaffected — only `$log` carries `ts`.
- The explicit `test -n` surfaces real errors (auth failure, network, etc.) instead of silently passing an empty `$session_id` to `resume`.
- If running outside a git repository, add `--skip-git-repo-check` after `exec`.

## Resume

Resume when the next prompt depends on the previous Codex context. Always resume by the captured `$session_id`. **Do not use `--last`** — it picks the newest session across all of `$CODEX_HOME`, not the one you started, so parallel callers and other projects will clobber each other.

```bash
set -o pipefail
log=$(mktemp)
last=$(mktemp)
command codex --sandbox danger-full-access --dangerously-bypass-approvals-and-sandbox \
  exec resume --json -o "$last" "$SESSION_ID" "$PROMPT" </dev/null \
  | jq -cR --unbuffered 'fromjson? | {ts: (now|strflocaltime("%Y-%m-%d %H:%M:%S"))} + .' \
  | tee "$log"
```

- Put `exec resume` options (`--json`, `-o`, `--skip-git-repo-check`) before the session id.
- `--sandbox` is rejected at the `exec resume` position; keep it as a top-level option before `exec`, as shown.
- `exec resume` does not accept `-C/--cd` or `--sandbox`. The thread keeps the cwd and sandbox of the original `exec`.

## Prompting Rules

- Give Codex a self-contained task, expected deliverable, cwd, and edit/test boundaries.
- Ask for a concise final answer and changed file list when delegating code changes.
- Do not use interactive `codex` unless a human is actually driving the TUI.
- Prefer `--json` for automation because it exposes `thread_id`, tool events, failures, and usage.
