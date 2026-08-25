---
name: weekly-report
description: Generate a dated work-status report for a completed week from repository evidence — git history, spec/task progress, bug log, and session notes — and save it as a Markdown file. Use when the user asks for a weekly report, weekly summary, week-in-review, or a status writeup for a past week.
---

# Weekly Report

Produce a work-status report for a completed week from repository evidence (git
history, spec progress, bug log, session notes) and save it as
`<output-dir>/<mmmDD>-<mmmDD>-<YYYY>.md` (e.g. `jun29-jul04-2026.md`).

## Configuration

Resolve these before the first run (environment variables or project conventions —
adjust to your project). Prompt the user for any that are missing rather than
guessing.

| What | Env var | Example |
| --- | --- | --- |
| Specs directory | `WEEKLY_REPORT_SPECS_DIR` | `.kiro/specs/` (or `specs/`) |
| Notes/bookkeeping dir | `WEEKLY_REPORT_NOTES_DIR` | `.wolf/` |
| Buglog file | `WEEKLY_REPORT_BUGLOG` | `.wolf/buglog.json` |
| Session notes | `WEEKLY_REPORT_MEMORY` | `.wolf/memory.md` |
| Output directory | `WEEKLY_REPORT_OUT_DIR` | `docs/reports/` (or `.wolf/reports/`) |

## Invocation

```
/weekly-report <output-dir>            # last complete week
/weekly-report <output-dir> --week 2   # two weeks back
/weekly-report <output-dir> --days mon-sun
/weekly-report <output-dir> --author <name|email>
```

### Arguments

| Arg | Default | Meaning |
| --- | --- | --- |
| `<output-dir>` | `WEEKLY_REPORT_OUT_DIR` | Where the report is written. Created if missing. Announce it when the default is used. |
| `--week N` | `1` | Weeks back. `1` = last complete week, `0` = the current (partial) week. |
| `--days` | `mon-sat` | Work-week span: `mon-sat` or `mon-sun`. |
| `--author` | *(all)* | Restrict git history to one author. |

## Procedure

### Step 1 — Resolve the reporting window and filename

Use `python3`, **not** `date -d` — some environments put BusyBox `date` first on
PATH, which silently rejects relative expressions and yields empty variables.

```bash
WEEK_OFFSET=1            # from --week: 1 = last complete week, 0 = current
SPAN_DAYS=5              # 5 => Mon..Sat (mon-sat), 6 => Mon..Sun (mon-sun)

eval "$(python3 - "$WEEK_OFFSET" "$SPAN_DAYS" <<'PY'
import sys, datetime
off, span = int(sys.argv[1]), int(sys.argv[2])
t = datetime.date.today()
start = t - datetime.timedelta(days=t.weekday()) - datetime.timedelta(weeks=off)
end = start + datetime.timedelta(days=span)
f = lambda d: d.strftime('%b%d').lower()
print(f'START={start}\nEND={end}\nSLUG={f(start)}-{f(end)}-{end.year}')
PY
)"
echo "window: $START .. $END  ->  ${SLUG}.md"
```

Filename rules: lowercase 3-letter month + zero-padded day, both endpoints, then
the **end date's** year. Sanity-check that `$START` is a Monday and both dates are
non-empty — empty means the date math failed; stop rather than running git with an
unbounded `--since`.

### Step 1b — Continuity check: report the GAP, not the calendar default

Do this before gathering evidence. The naive "last complete ISO week" is often wrong
when reports are written on demand rather than on a fixed cadence.

```bash
ls -1 "$OUT_DIR"/*.md 2>/dev/null | sort
```

Parse the **end date of the most recent report** (from its filename, or its heading
when they disagree). Then:

- If the last report's end is **≥ your computed `$END`**, the default window is
  covered — shift to `last_end + 1 day` .. the most recent completed day.
- If there is a **gap** between the last report's end and your `$START`, the gap is
  the real reporting window.
- Fall through to the ISO default only when no prior report exists.

Announce the adjustment and why. Continuity beats calendar tidiness.

### Step 2 — Gather git activity

`--all` walks every local branch, so sibling worktrees are covered by one query.
Add `--author="$AUTHOR"` when `--author` was passed.

```bash
# Commit list
git log --all --no-merges --since="$START 00:00:00" --until="$END 23:59:59" \
  --date=format:'%a %m-%d' --pretty=format:'%h%x09%ad%x09%an%x09%s'

# Volume — headline figure EXCLUDES the notes/bookkeeping dir, which otherwise dominates
git log --all --no-merges --since="$START 00:00:00" --until="$END 23:59:59" \
  --pretty=tformat: --numstat -- . ":(exclude)$NOTES_DIR/*" |
  awk '{a+=$1; d+=$2; n++} END {printf "%d file-changes, +%d / -%d (non-notes)\n", n, a, d}'

# Real vs bookkeeping commit split (adjust the grep to your bookkeeping prefixes)
tot=$(git log --all --no-merges --since="$START 00:00:00" --until="$END 23:59:59" --pretty=format:'%s' | wc -l)
real=$(git log --all --no-merges --since="$START 00:00:00" --until="$END 23:59:59" --pretty=format:'%s' \
  | grep -vc '^chore(.*bookkeep.*)\|^save \|^commit ')
echo "$tot commits total, $real real, $((tot-real)) bookkeeping"

# Where the work landed (component buckets)
git log --all --no-merges --since="$START 00:00:00" --until="$END 23:59:59" \
  --name-only --pretty=format: | grep -v '^$' | sort -u |
  awk -F/ '{print ($1=="src" ? "src/"$2 : $1)}' | sort | uniq -c | sort -rn

# Conventional-commit scopes
git log --all --no-merges --since="$START 00:00:00" --until="$END 23:59:59" \
  --pretty=format:'%s' | sed -n 's/^[a-z]*(\([^)]*\)).*/\1/p' | sort | uniq -c | sort -rn
```

Read commit bodies (`git show -s --format=%B <sha>`) only for commits whose subject
is too terse to classify — don't dump every body into context.

### Step 3 — Gather spec progress

Find specs touched in the window, then compute task completion:

```bash
git log --all --no-merges --since="$START 00:00:00" --until="$END 23:59:59" \
  --name-only --pretty=format: | grep "^$SPECS_DIR/" | cut -d/ -f3 | sort -u
```

For each spec, read its manifest for phase/blockers and count done vs total tasks
from its task file. To attribute *which* tasks were completed in the window, diff
the task file across the window boundary rather than reading the current file alone.

### Step 4 — Gather bug activity

Read the buglog; select entries whose opened or last-seen date falls in the window;
report opened-vs-fixed counts and call out anything still open at window end
(carry-over risk). Adapt the field names to your buglog schema.

Watch for **duplicate IDs** (counter restarts): separate genuinely-new IDs from
collisions and report the collision count as an integrity finding. Re-check every
bug the previous report listed as open and state its status now — that
closing-the-loop line is the series' main continuity value.

### Step 5 — Gather session notes (optional enrichment)

If session notes are large, extract only headers inside the window first, and read
row detail only where git history is thin on explanation. An optional memory/timeline
MCP (if available) can add narrative context — never block the report on it.

### Step 6 — Compose the report

Write to `$OUT_DIR/$SLUG.md`. Match the established format of the series — read the
most recent existing report first and mirror its section order. A stable baseline:

```markdown
# <Project> Status — <Mon DD> – <Mon DD>, <YYYY>

## TL;DR
<3-5 sentences: the window's theme, what shipped, what regressed.>

## Commits by day
### <Mon DD> (<Day>) — <theme for that day>
- **`<sha>`** — <what it did and why it matters>

## Bugs opened/fixed this window
- **N new bugs**, **M fixed**, **K still open**
- Carry-over status: which of the prior report's open bugs are now closed
- ⚠️ Any integrity/regression concern about the bug log itself

## Spec status changes
- **<spec>** — <phase transition, task count, any metadata/reality mismatch>

## Stats
- **N commits** — split feature/fix/docs vs bookkeeping
- **N files changed**, **+A / −D** — quote the non-notes figure as the headline
- Busiest areas, specs completed, sessions logged

## Open threads / to-do heading into next session
1. <numbered, actionable, enough detail to resume cold>
```

Report-writing rules:
- **Evidence-backed only.** Every claim traces to a commit, spec file, or bug entry.
- **Cite short SHAs inline** so the reader can jump to the diff.
- **Day sections get a theme**, not a commit dump.
- **Close the loop on the prior report's open threads.**
- **Quote non-notes line counts as the headline** (bookkeeping churn dwarfs real code).
- **Separate bookkeeping commits from real ones** in the count.
- **Language:** English unless the project's convention says otherwise.
- Numbered open threads carry forward; write them so a cold session can act on them.

### Step 7 — Save and confirm

```bash
mkdir -p "$OUT_DIR"
```

Write the file, then report back in one or two sentences: the path written, the
window covered, and the headline counts (commits / specs advanced / bugs fixed).

## Safety & Fallback

- **Not a git repository** — report that git evidence is unavailable and build from
  the buglog, session notes, and specs alone; note the limitation in the header.
- **Empty window** — don't fabricate content; write a short "no recorded activity"
  report and ask whether the window was intended (a wrong `--week` is the usual cause).
- **Missing notes/specs dirs** — skip those sections silently; git history alone is a
  valid basis.
- **Existing report file** — ask before overwriting (see Step 1).

## After running

Per your project's protocol, record the report generation (e.g. append a line to the
session notes) and register the new report wherever the series is indexed.
