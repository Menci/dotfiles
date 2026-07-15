---
name: reading-claude-session
description: Use when reading Claude Code .jsonl session transcripts — covers locating files, filtering rewinds and compactions, focused skimming, and subagent transcripts.
---

Session files are JSONL. Every line is independent JSON — `sed -n Np file | jq` expands any line on demand.

## Locate the file

Sessions live under `~/.claude/projects/<encoded-cwd>/<session-uuid>.jsonl`, where `<encoded-cwd>` is the absolute path with `/` replaced by `-` (e.g. `/Users/foo/bar` → `-Users-foo-bar`). Easiest: `ls ~/.claude/projects/ | grep <project-name>`.

## Pick the right session

`grep -l "<keyword>" ~/.claude/projects/<dir>/*.jsonl`. Sort by `mtime` if the user says "recent".

## Filter rewounds

`/rewind` branches the `parentUuid` tree; dead branches stay in the file. To get the live conversation:

1. Take the **last** `last-prompt` entry with non-null `leafUuid` — that's the live leaf.
2. Walk `parentUuid` back from it through `user` / `assistant` / `system` / `attachment` nodes.
3. Anything not on that path is rewound — ignore unless the user explicitly asks about discarded branches.

Typically 50–80% of message nodes in a long session are rewound; reading the file linearly without filtering will mislead you.

## Compaction

A `system` entry with `subtype:"compact_boundary"` has `parentUuid:null` (chain intentionally broken) and `logicalParentUuid` pointing to the pre-compact leaf. The next `user` entry has `isCompactSummary:true` — that's the summary the model continued from.

- To read what the model currently sees: stop walking back at the latest `compact_boundary`.
- To read full history across compactions: bridge via `logicalParentUuid` and continue (still apply rewind filter on each segment).

## What to read closely vs skim

- **Read closely**: `user` text and `assistant` text content. These carry intent, decisions, corrections.
- **Skim**: `tool_use.input` and `tool_result.content`. Truncate to ~80 char preview with `{line, json-path}` ref, expand a specific line only if the surrounding discussion points to it.
- **Treat any unfamiliar entry type or content block as a tool call** — both Claude Code and user-installed MCP servers add their own tool types (web search, computer use, etc.). Skim by default; expand only if it matters.
- Ignore unless asked: `permission-mode`, `worktree-state`, `file-history-snapshot`, `queue-operation`, hook attachments, task-reminder attachments.

## Long sessions drift

Plans, file names, and decisions change mid-conversation. Don't trust early statements as still-true — follow the user/assistant exchange forward, and let later turns override earlier ones. When the user asks "what did we decide about X", scan from the **end** backward.

## Subagent transcripts

When a subagent is dispatched, its full transcript is a separate JSONL at:

```
~/.claude/projects/<encoded-cwd>/<parent-session-uuid>/subagents/agent-<taskid>.jsonl
```

`<taskid>` shows up in the parent session as `queue-operation` content (`<task-id>...</task-id>`) and as the `id` returned in the dispatching tool_result. Same format, same filtering rules; subagents can dispatch their own subagents — recurse identically.
