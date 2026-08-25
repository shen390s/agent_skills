---
name: gitea-sync
description: Use when syncing local specs, tasks, or bug logs to Gitea issues and milestones — creating or updating milestones, phase-tracking issues, and bug issues from local files that act as the source of truth, with idempotent sync state stored back in the files. Apply when mirroring local project state into a Gitea (or Gitea-compatible) issue tracker.
---

# Gitea Sync

Mirror local project state (specs and bug logs) into a Gitea issue tracker. Local
files are the **source of truth**; Gitea is a read-only mirror. Sync state (issue
and milestone numbers) is written back into the local files so the sync is
idempotent.

## MCP server

This skill drives Gitea through the official [Gitea MCP server](https://gitea.com/gitea/gitea-mcp),
which exposes the `mcp__gitea__*` tools used below. Install it (binary, Docker, or
`go run gitea.com/gitea/gitea-mcp@latest`), then register it as an MCP server named
`gitea` pointing at your instance:

| Setting | Env var | Flag |
| --- | --- | --- |
| Instance URL | `GITEA_HOST` | `--host` |
| Access token (PAT) | `GITEA_ACCESS_TOKEN` | `--token` |

Crush (`crushrc`):

```bash
mcp add gitea \
  --type stdio \
  --command gitea-mcp \
  --args -t --args stdio \
  --args --host --args "https://gitea.example.com" \
  --env GITEA_ACCESS_TOKEN "${GITEA_ACCESS_TOKEN:?set GITEA_ACCESS_TOKEN}"
```

Generic JSON (Claude Code `.mcp.json`, Cursor, etc.):

```json
{
  "mcpServers": {
    "gitea": {
      "command": "gitea-mcp",
      "args": ["-t", "stdio", "--host", "https://gitea.example.com"],
      "env": { "GITEA_ACCESS_TOKEN": "<your-personal-access-token>" }
    }
  }
}
```

Create a PAT in Gitea under Settings → Applications. Optionally restrict the server
to the scopes this skill needs with `--scope issue,label,milestone`.

If the MCP server isn't registered, or its host/token are missing, prompt the user
for the instance URL and a PAT (and help configure them) before continuing.

## Configuration

Resolve these before the first run (via environment variables or project
conventions — adjust to your project):

| What | Env var | Example |
| --- | --- | --- |
| Repo | `GITEA_REPO` | `nexa/xce` |
| Specs directory | `GITEA_SYNC_SPECS_DIR` | `.kiro/specs/` (or `specs/`) |
| Buglog file | `GITEA_SYNC_BUGLOG` | `.wolf/buglog.json` (or `buglog.json`) |

Resolve each value in order:

1. Environment variable, if set.
2. A discovered project convention (look for the paths in the repo).
3. **Prompt the user** — never guess and never proceed with a missing value.

Each spec is a directory containing a manifest (e.g. `spec.json`) plus phase
documents (e.g. `requirements.md`, `tasks.md`). The manifest holds the sync
mapping (`gitea.milestone_id`, `gitea.issues.<phase>`) once synced.

## Invocation

```
/gitea-sync                           # sync all specs + all bugs
/gitea-sync --spec <name>             # sync one spec
/gitea-sync --bugs --since <date>     # sync recent bugs only
/gitea-sync --dry-run                 # preview without writing
```

## Procedure

### 0. Parse arguments

- `--dry-run`: only report what would change; don't call write tools.
- `--spec <name>`: sync only one spec directory.
- `--bugs`: sync bugs only (skip specs).
- `--since <YYYY-MM-DD>`: only bugs whose last-seen date is >= this value.

### 1. Ensure labels exist

List existing labels, then create any missing ones. Use label IDs (not names) in
subsequent create/update calls. Define a small, consistent label scheme, e.g.:

| Label | Meaning |
| --- | --- |
| `spec` | spec-tracked issue |
| `bug` | bug-tracked issue |
| `bug:fixed` | resolved bug |
| `phase:<name>` | one label per spec phase |
| `blocked` | blocked on a dependency |

### 2. Sync specs

For each spec directory (or just `--spec <name>`):

1. Read the manifest. If it already holds a milestone id and issue numbers for
   every phase, skip creation and only reconcile issue open/closed state (2d).
2. If not synced:
   a. **Create a milestone** titled with the spec name; description = one-line
      summary + current phase + blockers.
   b. **Create one issue per phase** under the milestone. Example phase set:
      | Phase | Title | Initial state |
      | --- | --- | --- |
      | `requirements_design` | `[<spec>] Requirements & Design` | closed if both approved, else open |
      | `implementation` | `[<spec>] Implementation` | open |
      | `validation` | `[<spec>] Validation & Closure` | open |
      Build each body from the phase documents (status, checklists `- [ ]`/`- [x]`,
      blockers, links to files).
   c. **Write sync state** back into the manifest, e.g.
      `"gitea": { "milestone_id": <id>, "issues": { "<phase>": <number>, ... } }`.
   d. **Reconcile state** (already-synced specs): close phase issues when their
      phase is complete; close the milestone when all phases are done.

### 3. Sync bugs

Read the buglog. For each entry:

1. **Skip** if it already has a synced-issue id and no state change is needed
   (e.g. already fixed when synced), or if `--since` excludes it.
2. **Create an issue** for entries without a synced id:
   - **Title**: `[<bug-id>] <first sentence of the error>` (truncate ~120 chars).
   - **Body**: error, root cause, fix, affected files, tags, related bugs, and a
     footer noting it was synced from the buglog.
   - **Labels**: `bug`, plus `bug:fixed` when a fix exists; map known tags to
     labels (e.g. crash tags → `bug:crash`, race tags → `bug:race`).
   - **State**: closed if a fix is present, otherwise open.
   - **Milestone**: none (bugs usually span specs).
3. **Close fixed bugs**: for entries with a synced id whose fix is now populated,
   update the issue to closed.
4. **Write the synced id back** into the buglog entry for idempotency.

### 4. Report

Print a summary: "Specs: N synced, M skipped | Bugs: X created, Y closed, Z skipped".

## Important rules

- **Files are ground truth.** Never read Gitea state to update local files; the
  stored ids only record the sync mapping.
- **Idempotent.** Entries with an existing sync id are skipped unless their state
  changed.
- **Labels**: check existing labels before creating; pass label IDs (not names) to
  create/update calls.
- **Rate limiting**: create issues sequentially (a few per turn) to stay within
  API limits.
- **Large buglogs**: always use `--since` for practical runs; without it you sync
  everything.
- **Auth**: a private repo needs a Gitea MCP connection with access.

## Gitea MCP tool reference

| Action | Tool | Method |
| --- | --- | --- |
| List labels | `mcp__gitea__label_read` | `list_repo_labels` |
| Create label | `mcp__gitea__label_write` | `create_repo_label` |
| List milestones | `mcp__gitea__milestone_read` | `list` |
| Create milestone | `mcp__gitea__milestone_write` | `create` |
| List issues | `mcp__gitea__issue_read` | `get` (single) or list |
| Create issue | `mcp__gitea__issue_write` | `create` |
| Update issue | `mcp__gitea__issue_write` | `update` |

Note: issue `state: "closed"` may not apply on `create` — if it comes back open,
update it immediately with `method: "update"` + `state: "closed"`.
