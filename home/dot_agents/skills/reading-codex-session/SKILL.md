---
name: reading-codex-session
description: Read and reconstruct Codex JSONL session transcripts, including paginated rollout lineage, forks, compactions, rewinds, and subagent threads. Use when locating a session by UUID/project or auditing what happened and what remained on the active branch.
---

Codex sessions may span a graph of rollout files. Resolve the active lineage before interpreting messages. Reading the first filename containing a UUID can select an ancestor or abandoned fork and produce a false history.

## Record shape

Current records usually have `{ timestamp, ordinal, type, payload }`; older records may omit `ordinal`.

Important top-level types include:

- `session_meta` — rollout metadata. It is the first record of each rollout segment, but its ordinal need not be zero.
- `response_item` — messages, reasoning, tool calls/results, and subagent messages.
- `event_msg` — turn/UI events such as `task_started`, `task_complete`, `turn_aborted`, and `item_completed`.
- `compacted` — replacement model context and retained-message metadata.
- `turn_context`, `token_usage_record`, `world_state`, and `inter_agent_communication_metadata` — normally skip unless the request needs them.

Use `sed -n 'Np' file | jq` to expand one physical line. Use `jq`'s `input_line_number` when producing references.

## Locate the active rollout

Sessions live under `~/.codex/sessions/YYYY/MM/DD/`. A filename may be either:

```text
rollout-<timestamp>-<root-thread-id>.jsonl
rollout-<timestamp>-<root-thread-id>_<rollout-segment-id>.jsonl
```

The highest-version `~/.codex/state_*.sqlite` is the forward index. For a pasted root thread UUID, prefer the database row over `find`:

```sh
DB=$(ls -1 ~/.codex/state_*.sqlite | sort -V | tail -1)
sqlite3 -separator $'\t' "$DB" "
  SELECT id, rollout_path, cwd, first_user_message,
         datetime(updated_at_ms/1000,'unixepoch','localtime')
  FROM threads
  WHERE id = '<thread-uuid>';"
```

For project discovery:

```sh
sqlite3 -separator $'\t' "$DB" "
  SELECT datetime(updated_at_ms/1000,'unixepoch','localtime'),
         id, substr(first_user_message,1,60), rollout_path
  FROM threads
  WHERE cwd = '/abs/path' AND archived = 0
  ORDER BY updated_at_ms DESC LIMIT 20;"
```

`threads.rollout_path` identifies the current leaf. Other files containing the same root UUID may be ancestors or sibling forks.

If the database row is absent, enumerate matching files, inspect their first `session_meta`, and build the lineage described below. Do not use `find ... -print -quit` as the final selection rule.

## Reconstruct paginated history and forks

Check the leaf's first record:

```sh
sed -n '1p' "$LEAF" | jq '{ordinal, id:.payload.id, session_id:.payload.session_id,
  history_mode:.payload.history_mode, history_base:.payload.history_base}'
```

With `history_mode: "paginated"`, a resumed or forked segment has:

```json
{
  "history_base": {
    "thread_id": "<parent rollout segment id>",
    "end_ordinal_exclusive": 14524,
    "end_byte_offset": 52181136
  }
}
```

`history_base.thread_id` names the parent rollout segment. Locate the file whose final filename UUID equals that ID:

```sh
find ~/.codex/sessions -type f \
  \( -name "*-${PARENT_ID}.jsonl" -o -name "*_${PARENT_ID}.jsonl" \)
```

Reconstruct recursively:

1. Start from the SQLite-selected leaf.
2. If it has `history_base`, resolve the parent segment first.
3. Include only the first `history_base.end_byte_offset` bytes of that parent.
4. Then include the current segment.
5. Continue until a segment has no `history_base`.

When a segment is itself truncated by a child's cutoff, recursively include its own ancestors and only its first requested byte prefix.

`end_byte_offset` is the authoritative cutoff. `end_ordinal_exclusive` is useful for validation, but ordinals can collide at segment boundaries: a child `session_meta` commonly reuses the cutoff ordinal that belonged to an abandoned parent event. Do not concatenate every matching file, sort all records by timestamp, or deduplicate solely by ordinal.

A fork is another child segment pointing to a parent segment and cutoff. SQLite selects the active leaf. To audit all forks, enumerate rollout segments as graph nodes and treat each `history_base.thread_id` as a child-to-parent edge; keep sibling histories separate.

Legacy sessions without paginated `history_base` can be read as single files, subject to rollback filtering below.

## Messages and tools

Read these closely:

- `response_item` with `payload.type == "message"`. Roles can include `user`, `assistant`, and `developer`. Text is normally in `payload.content[]`, whose block types include `input_text` and `output_text`. Assistant messages may have `payload.phase` such as `commentary` or `final_answer`.
- `response_item.agent_message`. This carries messages/final answers between agents and can contain important findings absent from the root assistant messages.

Skim tool traffic first, then expand calls relevant to a decision:

- Legacy: `response_item.function_call` and `function_call_output`, matched by `call_id`.
- Current: `response_item.custom_tool_call` uses `payload.name` and usually a string `payload.input`; `custom_tool_call_output` may store an array of text/content blocks in `payload.output`.

Feature-detect the payload shape. Do not assume tool output is always a string. Do not classify every unfamiliar response item as a tool call; inspect `payload.type` and keys first.

Usually skip encrypted reasoning, token accounting, verbose `event_msg.item_completed`, and large command bodies unless they matter to the question.

## Turns and abandoned work

Within the reconstructed active lineage, `event_msg.task_started` begins a turn and `task_complete` or `turn_aborted` ends it. Prefer these events over developer message text such as `<turn_aborted>`.

Old sessions may contain:

```json
{"type":"event_msg","payload":{"type":"thread_rolled_back","num_turns":2}}
```

For those, group completed/aborted turns while walking forward; on a rollback, remove the most recent `N` turns and continue. The abandoned records remain physically present.

Paginated forks often express abandonment by choosing a parent byte cutoff in `history_base`, without a `thread_rolled_back` event. Resolve lineage first, then apply any rollback events that remain in that logical stream.

## Compaction

Current `compacted.payload` can contain:

- `replacement_history` — the context replacing earlier model-visible items. Items carry content blocks plus IDs and internal metadata; they are not necessarily simple `{ role, content }` objects.
- `replacement_history_metadata` — retained-source revisions, ordering, attribution, and completeness metadata.
- `retained_context` — structured retained user/assistant messages and completeness flags.
- `window_number`, `window_id`, `previous_window_id`, and `resume_metadata` — window lineage/state.
- `message` — may exist but be an empty string; do not use non-emptiness as the compaction detector.

Do not require a neighboring `event_msg.context_compacted`; current rollouts may contain only the top-level `compacted` record.

To understand what the model saw after compaction, inspect the latest active-lineage `compacted.payload.replacement_history`, plus its retained metadata/context when message provenance or completeness matters. To recover the human-visible conversation, read the reconstructed logical history; pre-compaction records remain in ancestor/current rollout bytes even though they were replaced in the model context.

## Subagents

Do not identify subagents from `originator` alone. Current interactive and subagent sessions may both use `originator: "codex-tui"`.

Reliable indicators in child `session_meta` are:

```text
payload.thread_source == "subagent"
payload.source.subagent.thread_spawn.parent_thread_id
payload.source.subagent.thread_spawn.agent_path
payload.source.subagent.thread_spawn.depth
```

The child `payload.id` is its thread ID; `payload.session_id` may still be the root parent's session ID.

Prefer the SQLite graph when available:

```sh
sqlite3 -separator $'\t' "$DB" "
  SELECT e.parent_thread_id, e.child_thread_id, e.status,
         t.rollout_path, t.agent_nickname, t.agent_role
  FROM thread_spawn_edges e
  JOIN threads t ON t.id = e.child_thread_id
  WHERE e.parent_thread_id = '<parent-thread-id>';"
```

Parent rollouts may also contain `response_item.agent_message` records with subagent updates and final answers. Open the child rollout when its detailed evidence, tool work, or nested children matter. Recurse through `thread_spawn_edges` for nested agents.

## Reading strategy

- First resolve the active lineage; only then scan messages or infer the ending.
- For “what was decided”, scan active-lineage user/assistant/agent messages from the end backward. Later corrections override earlier plans.
- Distinguish the full human-visible logical history from the model-visible context after the latest compaction.
- Keep physical references as `{ file, line, JSON path }`; logical ordinals alone are ambiguous across rollout boundaries.
- If conclusions depend on whether a branch continued, verify the SQLite leaf and every `history_base` edge before saying the session ended.
