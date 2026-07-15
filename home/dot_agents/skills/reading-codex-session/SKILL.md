---
name: reading-codex-session
description: Use when reading Codex .jsonl session transcripts — covers locating files (incl. by UUID or project), filtering rewinds and compactions, focused skimming, and subagent transcripts.
---

Every line is `{timestamp, type, payload}`. Use `sed -n Np file | jq` to expand a specific line.

## Locate the file

Sessions live under `~/.codex/sessions/YYYY/MM/DD/rollout-<ISO-ts>-<uuid>.jsonl`. The filename contains the session UUID.

- **By UUID** (user pastes one): `find ~/.codex/sessions -name "*<uuid>*"`.
- **By project (forward index)**: codex maintains a sqlite index at `~/.codex/state_*.sqlite` (the `N` in `state_N.sqlite` is the schema version — always pick the highest-numbered file). The `threads` table has `cwd`, `rollout_path`, `first_user_message`, `updated_at_ms`, `archived`, etc., with a covering index on `(archived, cwd, updated_at_ms)`:

  ```sh
  DB=$(ls -1 ~/.codex/state_*.sqlite | sort -V | tail -1)
  sqlite3 -separator $'\t' "$DB" "
    SELECT datetime(updated_at_ms/1000,'unixepoch','localtime'),
           id, substr(first_user_message,1,60), rollout_path
    FROM threads
    WHERE cwd = '/abs/path' AND archived = 0
    ORDER BY updated_at_ms DESC LIMIT 20;"
  ```

  `first_user_message` is denormalized into the row, so you get a label without opening any jsonl. (`~/.codex/session_index.jsonl` is unrelated — it's an id↔name log for `codex resume <name>`, no cwd.)
- **By keyword**: just `grep -l "<keyword>"` across all jsonl files.

Fallback when sqlite is absent: scan `head -1` of each jsonl and filter on `payload.cwd`.

## Entry types you care about

- `response_item.message` — user/assistant text. `payload.content[].text` is what was said.
- `response_item.function_call` — tool call. `payload.{name, arguments, call_id}`.
- `response_item.function_call_output` — tool result string. Match by `call_id`.
- `response_item.reasoning` — model reasoning. `summary` often empty, `encrypted_content` is opaque. Usually skip.
- `event_msg.task_started` / `task_complete` / `turn_aborted` — turn boundaries.
- `event_msg.thread_rolled_back { num_turns: N }` — rewind, see below.
- `compacted { message, replacement_history }` and `event_msg.context_compacted` — compaction, see below.
- `session_meta` (line 1) — `cwd`, `id`, `model_provider`, `originator` (`codex-tui` = interactive, `codex_exec` = subagent), `thread_source`.

Ignore unless asked: `event_msg.token_count`, `turn_context`.

## Filter rollbacks

`/undo` (or backspace-rewind) writes an `event_msg` with `payload.type == "thread_rolled_back"` and `num_turns: N`. The N most recent **turns before this event are abandoned but stay in the file**.

A turn is bounded by `task_started` and one of `task_complete` / `turn_aborted`. To get the live conversation: walk forward, group `response_item` / `event_msg` into turns by `task_started`, and when you see `thread_rolled_back num_turns=N`, drop the last N grouped turns. Then continue.

## Compaction

When the context is summarized, two entries are written close together:

- `compacted` (top-level type) — `payload.message` is the summary text, `payload.replacement_history` is the array of `{type:"message", role, content}` items that replace **all prior items** in the model's view from this point on.
- `event_msg.context_compacted` — UI notification only, no payload data.

- To read what the model sees after a compaction: latest `compacted.payload.message` + `replacement_history` is the entire pre-compact context, **prior items in the file are no longer visible to the model**.
- To read the full human-visible history: iterate the file in line order; the pre-compact items are still there.

## What to read closely vs skim

- **Read closely**: `response_item.message` (user/assistant text).
- **Skim**: `function_call.arguments` and `function_call_output.output`. Truncate to ~80-char preview with `{line, json-path}` ref, expand a specific line only when surrounding discussion points to it. Some tool inputs (e.g. patch bodies, file writes) can be huge — skim unless the content matters.
- **Treat any unfamiliar `type` / `payload.type` as a tool call** — built-in or MCP tools (web search, computer use, etc.) introduce shapes not listed above. Skim by default; expand only if it matters.
- **Skip**: `reasoning.encrypted_content`, `token_count`, `turn_context`.

## Long sessions drift

Plans, file names, and decisions change mid-conversation. Don't trust early statements as still-true — follow the user/assistant exchange forward, and let later turns override earlier ones. When the user asks "what did we decide about X", scan from the **end** backward.

## Subagent transcripts

Subagents (if any are dispatched) run as separate session files in the same date tree. Their `session_meta.originator` is `codex_exec` (vs `codex-tui` for interactive sessions), and `thread_source: subagent` marks nested ones.

The dispatching tool call's `function_call_output` typically returns the subagent's UUID (`{"agent_id":"<uuid>", ...}`). The subagent's session file is:

```
~/.codex/sessions/YYYY/MM/DD/rollout-<ts>-<agent_id>.jsonl
```

Easiest lookup: `find ~/.codex/sessions -name "*<agent_id>*.jsonl"`. Same format and filtering rules; subagents can dispatch further subagents — recurse identically.
