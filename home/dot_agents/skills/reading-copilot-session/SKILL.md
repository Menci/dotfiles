---
name: reading-copilot-session
description: Use when reading GitHub Copilot CLI sessions by UUID, repository, PR, issue, commit, keyword, or recent activity. Covers indexed history, raw events, checkpoints, rewinds, and subagent evidence.
---

Start with `session_store_sql`. Treat its normalized index as a locator, not a complete transcript or proof that something never happened.

## Find the session

- Start discovery with a 7-day window and selective repository/ref filters; widen only as needed. For an exact UUID, query it directly without an arbitrary date cutoff.
- For recent **activity**, search `turns.timestamp`. Filtering `sessions.created_at` excludes old sessions still in use; even `sessions.updated_at` can lag behind turns and raw events. Verify repository values before using exact equality.
- For PRs/issues/commits, use `session_refs` (`session_id`, `ref_type`, `ref_value`, `created_at`). A PR/issue number is not globally unique: verify the referenced repository in context, which may differ from the session's repository.
- Searching `turns` finds conversation text, not all tool use. To find skill invocations, search cloud `tool_requests` joined to `tool_executions` on **both** `session_id` and `tool_call_id`, bounded by `started_at`; inspect `name` and `arguments_json`. Locally, inspect actual `tool.execution_start` skill calls in candidate raw files, not injected skill text.

Example keyword discovery (cloud/DuckDB):

```sql
SELECT session_id, MAX(timestamp) AS last_seen
FROM turns
WHERE timestamp >= now() - INTERVAL '7 days'
  AND (user_message ILIKE '%<keyword>%'
       OR assistant_response ILIKE '%<keyword>%')
GROUP BY session_id
ORDER BY last_seen DESC
LIMIT 20
```

## Keep sources and queries straight

- Default `source: "cloud"` may supplement cloud results with best-effort local rows. Check warnings and `_query_source`: cloud SQL can fail locally while the overall call succeeds. Explicitly retry with `source: "local"` and SQLite syntax when local coverage matters; empty cloud results are not an exhaustive search.
- Cloud uses DuckDB (`ILIKE`, `now() - INTERVAL '7 days'`). Local uses SQLite (`LIKE`, `substr(timestamp,1,10) >= date('now','-7 days')`); local timestamps mix formats, so do not compare them directly with `datetime('now', ...)`.
- Shared tables: `sessions`, `turns`, `checkpoints`, `session_files`, `session_refs`. Cloud additionally has `tool_executions`, `tool_requests`, `events`, `attachments`, `session_usage`; local has `assistant_usage_events` and FTS5 `search_index`. Local `sessions` lacks `task_id` and agent columns. Usage rows are whole-session totals, not usage within the filter window.
- Keep source provenance. Cloud/local session identities may differ, and even for the same UUID their `turn_index` values and timestamps can differ. Never carry a turn cursor or row pairing between sources. A cloud ID or live agent ID is not automatically a local session-directory UUID; verify the mapping.
- Select needed columns and bounded text previews; use `LIMIT` and deterministic ordering. A row limit does not bound a broad scan. Narrow by session/time before searching large text or joining raw tables.

## Read the latest state first

1. Read metadata, the latest relevant checkpoint, and a small page of newest turns. For a known session, do not impose the discovery window on its conversation.
2. Page backward with `turn_index < <oldest-index>` in the **same source**, then read each page chronologically. `ORDER BY turn_index LIMIT 200` returns the oldest page, not the latest state. Expand previews or saved oversized tool outputs before drawing conclusions from missing text.
3. If expected details are absent, check the other source and raw events. A null `assistant_response` does **not** prove interruption: a completed autopilot reply may exist only in `session.task_complete` / the `task_complete` tool. Indexed turn timestamps may not be the original user-message time.

Example latest page (`source: "local"`; also valid cloud SQL):

```sql
SELECT turn_index, substr(user_message,1,800) AS user_message,
       substr(assistant_response,1,1600) AS assistant_response, timestamp
FROM turns
WHERE session_id = '<uuid>'
ORDER BY turn_index DESC
LIMIT 10
```

## Local evidence

Global index: `~/.copilot/session-store.db`. Per-session files: `~/.copilot/session-state/<local-uuid>/`.

- `workspace.yaml`: identity, cwd, repository, branch, metadata.
- `checkpoints/index.md` and `checkpoints/*.md`: continuation summaries; read the latest relevant one before older events.
- `events.jsonl`: original events, including tool calls/results missing from normalized turns.
- `files/`: persisted artifacts and receipts. `autopilot-objective.json`: objective/completion claims. `session.db`: task-defined operational tables, not the global history index.

If the tool cannot provide the needed local detail, query the index read-only. Without `sqlite3`:

```sh
python3 - <<'PY'
import sqlite3
from pathlib import Path
path = Path.home() / ".copilot/session-store.db"
with sqlite3.connect(f"file:{path}?mode=ro", uri=True) as db:
    for row in db.execute(
        "SELECT turn_index, substr(user_message,1,800), "
        "substr(assistant_response,1,1600), timestamp "
        "FROM turns WHERE session_id = ? ORDER BY turn_index DESC LIMIT 10",
        ("<local-uuid>",),
    ):
        print(row)
PY
```

## Raw events and accepted history

Each JSONL line has `type`, `data`, `id`, `timestamp`, `parentId`. Skim with line number/type and short previews; expand only decisive fields. Avoid dumping whole tool results or transformed messages.

- `user.message`: original `data.content`. `transformedContent` includes injected context, not just user-authored text.
- `assistant.message`: `data.content` and `toolRequests`. Match `tool.execution_start` arguments to `tool.execution_complete` results by `toolCallId`; a request alone proves no execution or success.
- `session.task_complete` / `task_complete`: final-response and completion claims, still requiring corroboration for mutations or external state.
- `session.compaction_complete`: check success; read `data.checkpointPath` when present, otherwise `data.summaryContent`. This is the carried-forward summary, not a replacement for the historical evidence.
- `session.info` with `data.infoType == "rewind"`: earlier events remain; the marker can lack a target or turn count. Do not invent which turns were removed. Rewinds can leave file changes intact. `abort` ends an in-flight turn, not necessarily its already-executed side effects.
- `session.truncation`: context was dropped, not necessarily summarized.
- `subagent.started` / `subagent.completed`: match `toolCallId` with the dispatch result. Read the returned evidence or verified separate session; do not assume an agent ID names a local directory. For a known live agent use `read_agent`.

Later user decisions supersede earlier plans. Distinguish proposed work, actual mutation, validation, merge/deployment, and external closure. Verify decisive claims against tool results, persisted artifacts, or live state; copied handoffs can also be stale. Report source, scope, and unresolved gaps rather than turning a missing index row or completion summary into certainty.
