---
name: using-claude-cli
description: Use ONLY when the user explicitly asks for the `claude` CLI — calling it from another runtime, delegating work to Claude Code non-interactively, resuming a Claude session, or capturing Claude output. Never a substitute for a subagent.
---

# Using Claude CLI

## When This Skill Applies

Only when the user explicitly asks for the Claude CLI (`claude`, "Claude CLI", "delegate to Claude Code", or an equivalent explicit request). Without that explicit request, do not invoke the `claude` binary at all.

The Claude CLI is not a subagent mechanism. Never use it to parallelize work, to run research, or to stand in for the Agent/Task tool — use real subagents for that, no matter how convenient a CLI call looks.

## Invocation

Use `command claude -p` for non-interactive delegation. Keep model, tools, settings, and environment-derived defaults unchanged unless the user explicitly asks otherwise.

Always invoke the binary via `command claude`, never bare `claude`. A shell alias or function named `claude` (common in interactive profiles) would otherwise intercept the call and inject its own flags or wrapper behaviour; `command` bypasses that and runs the real executable.

## New Task

```bash
log=$(mktemp)
session_id=$(node -e 'console.log(crypto.randomUUID())')
command claude -p --output-format json \
  --session-id "$session_id" \
  --disallowedTools EnterPlanMode,AskUserQuestion \
  --dangerously-skip-permissions \
  "$PROMPT" </dev/null | tee "$log" >/dev/null
jq -e '.is_error == false' "$log" >/dev/null \
  || { echo "claude: failure (see $log)" >&2; jq -r '.result // .' "$log" >&2; exit 1; }
result=$(jq -r '.result' "$log")
```

Pass `$session_id` to `resume` for follow-up turns.

- `</dev/null` is required. Without it `claude -p` waits 3s for stdin (visible warning "no stdin data received in 3s") before proceeding — a flat 3s/call penalty when invoked from any non-TTY caller (subagents, CI, Bash tools).
- `--session-id <uuid>` pre-assigns the session id, so parallel callers do not have to read the result before they can resume. `node -e 'console.log(crypto.randomUUID())'` works on macOS and Linux; `node` ships with `claude` itself.
- The `jq -e '.is_error == false'` assertion is required. `claude` exits **0 on every failure path tested**: unknown CLI flag (prints `error:` plain text, no JSON), missing prompt, API 404, permission denial. Trusting `$?` will silently treat error messages as the answer. The same assertion also fails when stdout is not JSON, covering CLI usage errors.
- For per-tool visibility (assistant `thinking`/`tool_use`, `user` `tool_result`, etc.) use `--output-format stream-json --verbose` instead; the same `--session-id` and `</dev/null` rules apply.

## Resume

Resume when the next prompt depends on the previous Claude context. Always resume by the captured `$session_id`. **Do not use `-c`** — it picks the most recent conversation in the current directory and will clobber parallel callers in the same cwd.

```bash
log=$(mktemp)
command claude -p --output-format json \
  -r "$SESSION_ID" \
  --disallowedTools EnterPlanMode,AskUserQuestion \
  --dangerously-skip-permissions \
  "$PROMPT" </dev/null | tee "$log" >/dev/null
jq -e '.is_error == false' "$log" >/dev/null \
  || { echo "claude: failure (see $log)" >&2; jq -r '.result // .' "$log" >&2; exit 1; }
result=$(jq -r '.result' "$log")
```

## Prompting Rules

- Give Claude a self-contained task, expected deliverable, cwd, and edit/test boundaries.
- Ask for a concise final answer and changed file list when delegating code changes.
- Do not add `--model`, `--tools`, or other config overrides unless the task specifically requires them.
- Do not use interactive `claude` unless a human is actually driving the TUI.
- Prefer `--output-format json` for automation because it exposes `session_id`, result text, errors, and usage.
