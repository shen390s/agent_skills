---
name: cli-ux
description: Use when designing, building, or reviewing the user experience of a command-line tool or terminal UI — one-shot CLIs and full-screen TUIs (dashboards, pickers, REPLs). Covers naming commands and subcommands, help text, flags and arguments, output streams and formatting, errors, prompts, colors, spinners, tables, terminal lifecycle, accessibility, configuration, and overall interaction design. Apply when creating a new CLI/TUI, adding commands, or judging whether a terminal interface is usable, scriptable, and consistent.
---

# CLI / TUI UX Design

Grounded in three canonical sources:

- **Command Line Interface Guidelines** (cli-guidelines.github.io) — the philosophical
  and practical foundation ("human-first design", "saying just enough").
- **Heroku CLI Style Guide** (devcenter.heroku.com/articles/cli-style-guide) — opinionated,
  concrete rules for topics/commands, flags, output, and color.
- **12 Factor CLI Apps** by Jeff Dickey (jdx.dev/posts/2018-10-08-12-factor-cli-apps/) — the
  12 factors distilled to a checklist.

Extended with full-screen TUI, accessibility, and visual-polish guidance from additional
references (see Sources).

Use this skill to make decisions and produce concrete designs (help text, flag sets,
tables, layouts, error messages, prompts). When in doubt, prefer the CLI Guidelines
document as the authority; the others sharpen specific areas.

## Reference files

This file is the hub. The detailed rules live in reference files — load only what the
task needs, then return here for the Review checklist:

| Need | Reference |
| --- | --- |
| One-shot CLI — naming, help, flags, output, errors, prompts, config, versioning | `references/cli-basics.md` |
| Full-screen TUI — terminal lifecycle, accessibility, layout review | `references/tui.md` |

---

## Guiding principles

These are the "why" behind every concrete rule.

1. **Human-first.** Design for the human typing the command, not for the script
   consuming it. If a command is used primarily by people, its output and errors
   should read like a helpful conversation, not a machine trace.
2. **Composable parts.** Every program becomes part of a larger system. Respect
   stdout/stderr, exit codes, and signals so your tool clicks into pipes and scripts.
3. **Consistency.** Follow existing conventions (flag names, exit codes, output shape)
   so users can guess behavior. Break convention only deliberately.
4. **Say just enough.** Neither hang silently nor drown the user in debug noise.
   Keep the signal-to-noise ratio high.
5. **Discoverable.** Help text, examples, and "what to do next" suggestions turn a
   CLI from a thing you must memorize into a thing you can learn.
6. **Empathy & robustness.** Make it feel solid and immediate; anticipate misuse.

---

## Product shapes

Classify the product before choosing flags, layout, or a framework:

| Shape | Default contract |
| --- | --- |
| **One-shot CLI** | No full-screen UI. Stable stdout for results, stderr for diagnostics, meaningful exit codes. (Most of this skill.) |
| **Summon–choose–exit tool** | Prefer inline when shell context matters; put interactive chrome on stderr or `/dev/tty`, the selected result on stdout. Full-screen only when a large preview needs stable space. |
| **Full-screen session** | Use the alternate screen and a stable spatial model. Terminal restoration, resize, suspend, and redraw are product requirements, not afterthoughts. |

Then name the workflow shape (panels, Miller columns, drill-down, dashboard, panes,
overlay, tabs) and sketch states — initial, loading, empty, partial, success, error,
disconnected, too-small — before writing code.

---

## The 12-factor checklist (run through this for any new CLI)

1. **Help is essential** — `--help`, `-h`, and `help` all work; `-h` means help *only*.
2. **Prefer flags to args** — 1 positional arg is fine, 2 is suspect, 3 is wrong.
3. **Version** — `--version`, `-V`, and (multi-command only) `version`.
4. **Mind the streams** — stdout is output, stderr is messaging.
5. **Handle failure** — error code + title + description + fix + reference URL.
6. **Be fancy, gracefully** — colors/spinners only on a TTY; honor `NO_COLOR`, `TERM=dumb`, `--no-color`.
7. **Prompt if you can** — prompt on a TTY, but never *require* a prompt (always scriptable).
8. **Use tables** — borderless, grep-able, with `--json`/`--csv`/`--columns`.
9. **Be speedy** — target 100–500ms startup; spinner/progress for long tasks.
10. **Encourage contributions** — open source, license, README, contribution guide.
11. **Clear subcommands** — list subcommands when run with no args; prefer colons for nesting.
12. **Follow XDG spec** — config/data/cache in `$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, `~/.cache`.

---

## Review checklist

Before calling a CLI/TUI "done", verify:

- [ ] `--help`, `-h`, `help`, and `subcommand --help` all work.
- [ ] Bare invocation shows concise help (or lists subcommands) — never a surprise action.
- [ ] stdout is output, stderr is messaging; exit codes are correct.
- [ ] `--json` (and/or `--csv`) available; human output is grep-able.
- [ ] Flags have full-length versions; standard names used; secrets not in flags/env.
- [ ] Prompts only on TTY and always bypassable; dangerous actions confirmed.
- [ ] Colors/spinners disabled on non-TTY, `NO_COLOR`, `TERM=dumb`, `--no-color`.
- [ ] Errors follow code/title/description/fix/URL structure; rewritten for humans.
- [ ] Progress shown for long tasks; <100ms first paint; 100–500ms startup.
- [ ] Ctrl-C exits cleanly; config follows XDG spec; version + User-Agent present.
- [ ] Full-screen: alternate screen used; terminal restored on every exit path.
- [ ] Resize, too-small, and suspend/resume behave; single-pane fallback exists.
- [ ] Every action keyboard-reachable; color never the only signal; ASCII/monochrome works.
- [ ] `NO_COLOR`/16-color/non-TTY output correct; no blocking I/O in the render path.
- [ ] Color degrades truecolor→256→16→monochrome; readable in light themes; `--color=always` works.
- [ ] Readable at 40/80/120 columns; CJK/emoji don't break alignment or box drawing.

## Sources

- https://github.com/cli-guidelines/cli-guidelines/blob/main/content/_index.md
- https://devcenter.heroku.com/articles/cli-style-guide
- https://jdx.dev/posts/2018-10-08-12-factor-cli-apps/ (mirror of
  https://jdxcode.medium.com/12-factor-cli-apps-dd3c227a0e46)
- https://github.com/gfargo/tui-design-skill (full-screen TUI patterns, lifecycle,
  accessibility, review reflexes)
- https://github.com/curiositech/windags-skills (color degradation, anti-patterns,
  progress indicators, quality gates)
