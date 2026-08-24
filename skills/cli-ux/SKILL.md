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

---

## Guiding principles

These are the "why" behind every concrete rule below.

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

## Command naming & structure

- **Topics are plural nouns; commands are verbs.** In `heroku apps:create`,
  `apps` is the topic and `create` is the command.
- Names are a **single lowercase word**, no spaces/hyphens/underscores. Use
  **colons** for subcommands: `apps:favorites:add`. If you must join words, use
  kebab-case (`pg:credentials:repair-default`).
- **Prefer colons over spaces** for nested commands. Colons avoid the ambiguity of
  "is this argument a subcommand or an argument to the topic command?" and visually
  separate command from arguments.
- **Never create a `*:list` command.** The bare topic (e.g. `heroku config`) already
  lists the nouns.
- **`noun verb` ordering** (e.g. `docker container create`) is more common; be
  consistent across all subcommands. Use the same verbs across object types.
- **No ambiguous/similar names** — avoid `update` vs `upgrade` pairings.
- **No catch-all subcommand.** Don't silently fall through to a default command when
  the first argument isn't a known subcommand; it blocks future subcommand names.
- **No arbitrary abbreviation.** Aliases must be explicit and stable (`ins` → `install`
  only if you commit to it forever).

---

## Help text

Rules for help output:

- **`--help` / `-h` / `help`** must all show full help for the current command, and
  `subcommand --help` / `subcommand -h` for subcommands. Ignore other flags when help
  is requested. Don't overload `-h`.
- **Concise help by default** when a command needs args and is run bare. Include:
  description, 1–2 examples, flag descriptions (if few), and a pointer to `--help`.
  (`jq` is the canonical example.)
- **Lead with examples.** Users reach for examples before prose; show real output too.
  Move exhaustive examples to a cheat-sheet command or web page.
- **Keep example annotations truthful and complete.** Every example's comment must match
  its real behavior, including defaults. A default that applies only when an argument is
  omitted must not be claimed in an example that supplies that argument (e.g. `cmd claude`
  is Claude-only, not "Crush + Claude"). Spell out what a keyword expands to and annotate
  every dimension: `cmd --project=. all` is "all skills -> all tools -> this project",
  not just "all skills -> this project".
- **Sweep examples when the interface changes.** A flag rename, new/removed flag, or
  changed syntax must be updated in every example (help, README, docs) at the same time.
  A stale example that no longer parses (e.g. a removed `--flag VALUE` form) is worse than
  no example.
- **Most common flags/commands first** (like `git`'s grouped "common commands").
- **Enumerate managed entities.** If the tool manages named resources (skills, plugins,
  apps, configs), list them in help and provide a `--list`-style command so users never
  have to guess valid names.
- **Use formatting** (bold headings) but terminal-independent — no raw escape codes
  when piped through a pager.
- **Link to web docs** and provide a **support/feedback path** (GitHub/issues link).
- **Suggest corrections** when input looks like a typo: `Did you mean ps? [y/n]` —
  but don't silently run the corrected command. State-changing assumptions are dangerous.
- If the command expects **stdin from a pipe but stdin is a TTY**, show help (or a
  stderr message) and exit instead of hanging like `cat`.

---

## Documentation

- Help text = immediate, brief. Documentation = full detail. Provide **both**:
  - **Web docs** (searchable, linkable).
  - **Terminal docs** (`help` subcommand; consider man pages but don't rely on them —
    they don't work on Windows and few check them).

---

## Flags vs. arguments

Terminology: *arguments* are positional; *flags* are named (`-r`, `--recursive`, with
optional `=value`).

- **Prefer flags to args.** More typing, but clearer, order-independent, and easier to
  add input later without breaking ambiguity.
- **Keep options orthogonal.** Each option controls one independent dimension, and any
  combination should be valid: no two options overlap in effect, and each input has
  exactly one way to be expressed. Overlapping flags (e.g. two flags that both skip one
  prompt) and two syntaxes for one input are non-orthogonal and should be consolidated.
- **One positional arg is fine** (`rm file`); **two types is suspect**; **three is never
  good**. Variable-length args of the *same* type are fine (`rm f1 f2 f3`).
- **Full-length versions for every flag** (`-h` and `--help`); reserve single-letter
  flags for common flags to avoid polluting the short namespace.
- **Use standard flag names** when a standard exists:

| Flag | Meaning |
| --- | --- |
| `-a`, `--all` | all |
| `-d`, `--debug` | debug output |
| `-f`, `--force` | force destructive/confirmed action |
| `--json` | JSON output |
| `-h`, `--help` | help (only) |
| `-n`, `--dry-run` | describe, don't execute |
| `--no-input` | disable prompts |
| `-o`, `--output` | output file |
| `-p`, `--port` | port |
| `-q`, `--quiet` | less output |
| `-u`, `--user` | user |
| `--version` | version |
| `-v` | verbose *or* version — pick one; use `-d` for verbose if ambiguous |

- **Make the default the right thing** for most users (`ls -lhF` today).
- **Support `-` for stdin/stdout** when a flag takes a file (`tar xvf -`).
- **Optional flag values** should use a special word like `none` (`ssh -F none`),
  never a blank.
- **Beware optional-value flags.** Don't let a flag with an optional value greedily
  consume the next token — a following tool name or flag gets misread. Prefer
  `--flag=VALUE` for explicit values and a bare `--flag` for the default; never
  `--flag VALUE` when VALUE is optional. An explicitly empty value (`--flag=`) should
  mean the same as the bare flag, not fall through to a different branch.
- **One flag, one meaning.** Don't ship two flags that do the same thing (e.g.
  `--force` and `--yes` both skipping one prompt) — they drift apart. If two are
  genuine aliases, document them as aliases, or drop one.
- **Accept each input the same way.** Don't let one concept be supplied both
  positionally and by flag while a parallel concept is flag-only. Pick one style per
  concept and apply it consistently.
- **Order-independent** args/flags/subcommands where possible — users append flags to
  the previous command via up-arrow.
- **Never read secrets from flags.** Use `--password-file` or stdin instead. Flag values
  leak via `ps` and shell history. (Env vars are likewise insecure — see Configuration.)

---

## Output

### Streams

- **stdout = output; stderr = messaging.** Primary and machine-readable output goes to
  stdout; logs, errors, warnings, and "out-of-band" progress go to stderr. This keeps
  piped/redirected output clean.

### Human vs. machine readable

- **Human-readable output is paramount.** Detect TTY and adapt (no animations/colors
  when stdout isn't a TTY).
- **Provide `--json`** (and `--csv`) for structured output; pairs with `jq`. Keep it
  stable for scripts.
- **Provide `--plain`** when human formatting (wrapped cells, multi-line rows) would
  break line-based parsing; `--plain` outputs one record per line.
- **grep-parseable but not necessarily awk-parseable.** Human output should survive
  `grep`, not require `awk`.

### Formatting

- **Use tables, borderless.** Each row is one record; no borders (noise). Support
  `--columns` (comma list), `--filter`, `--sort` (with inverse/multi), `--no-headers`,
  `--no-truncate`, plus `--json`/`--csv`. Truncate overflow by default.
- **Say what you changed.** `git push` and `git status` are the models — show the new
  state and hints for the next command.
- **`--dry-run` must describe the real effect.** Show what would change — create vs
  overwrite vs delete — not just echo the invocation back.
- **Suggest next commands** in output to teach workflows (`use "git add <file>"...`).
- **Increase density with ASCII art** (`ls -l` permission column) — scannable, learnable.
- **Use symbols/emoji where it clarifies** structure or draws attention; don't overdo it.
- **Don't output developer-only info by default** — no `ERR`/`WARN` log labels on stderr
  except in verbose mode.
- **Use a pager** for lots of text (`less -FIRX`), only when stdin/stdout is a TTY.

### Color & fancy output

- **Use color with intention**: highlight important text, red for errors, but sparingly.
  A couple of colors plus dim/bold is usually enough; yellow/red reserved for
  errors/warnings. Cap the palette: ~3 semantic colors (success/error/info) + 1 accent;
  grayscale does hierarchy. More than ~5 colors on one screen is "rainbow vomit".
- **Stay readable in light themes.** Prefer semantic ANSI codes (31 red, 32 green) over
  hardcoded dark-theme bright colors, and test both light and dark terminals.
- **Degrade gracefully.** Step down truecolor → 256 → 16 → monochrome (via `COLORTERM`/
  `TERM`) rather than emitting codes the terminal can't render.
- **Disable color/fancy output when** any of:
  - stdout/stderr is **not a TTY** (check each stream separately),
  - `NO_COLOR` is set and non-empty,
  - `TERM=dumb`,
  - `--no-color` passed (also consider `MYAPP_NO_COLOR`),
  - (Heroku also honors `COLOR=false`).
  Provide a `--color=always|auto|never` override so scripts can force color when piped.
- **No animations/progress bars when stdout isn't a TTY** (avoid Christmas trees in CI).

---

## Accessibility

- **Never use color alone.** Pair it with text, shape, position, or symbols; provide an
  ASCII fallback when Unicode support is uncertain.
- **Keep meaning in monochrome.** `NO_COLOR`/16-color must not erase the signal.
- **Every action is keyboard-reachable.** Mouse may accelerate but must not gate.
- **Offer a plain `--no-tui` (or equivalent) mode** for automation and accessibility, so
  the tool still works when a full-screen UI is unavailable or unusable.

---

## Errors

A good error message is documentation.

### Structure

```
Error: EPERM - Invalid permissions on myfile.out
Cannot write to myfile.out, file does not have write permissions.
Fix with: chmod +w myfile.out
https://github.com/you/myapp
```

1. **Error code** (e.g. `EPERM`)
2. **Error title**
3. **Description** (optional)
4. **How to fix it**
5. **Reference URL**

### Rules

- **Rewrite errors for humans.** Catch expected errors and translate ("Can't write to
  file.txt. Run `chmod +w file.txt`.").
- **Signal-to-noise ratio.** Group similar errors under one header. Put the most
  important info at the **end** of the output.
- **Unexpected errors:** provide debug/traceback info and bug-report instructions, but
  write the full log to a file, not the terminal. Make bug reports effortless
  (pre-filled URL).
- **Exit codes:** 0 on success, non-zero on failure, mapped to major failure modes.

---

## Prompting & interactivity

- **Only prompt if stdin is a TTY.** If not, skip prompting and require the flag/arg
  (error telling the user which flag to pass).
- **Never require a prompt.** Always allow flags/args to bypass, so the command is
  scriptable.
- **On a non-TTY, fail fast on a needed confirmation.** If an overwrite/confirmation
  would be required and stdin isn't a TTY, exit with an error that names the bypass
  flag (e.g. `re-run with -f or -y`) instead of hanging or silently skipping.
- **`--no-input`** disables all prompts; fail with instructions if input is required.
- **Hide passwords** while typing (disable terminal echo).
- **Confirm dangerous actions** — scale with severity:
  - Mild (delete one file): optional prompt.
  - Moderate (delete dir / remote resource / bulk edit): prompt, offer `--dry-run`.
  - Severe (delete app/server): require typing a non-trivial string (e.g. the name),
    or a `--confirm="name"` flag for scripting.
- **Let the user escape** — Ctrl-C always works; document escape sequences for wrappers
  (SSH `~`).

---

## Robustness & responsiveness

- **Validate input early** and bail with an understandable error. Validate raw tokens
  *before* applying shortcuts like `all` or defaults, so invalid input is never
  silently swallowed by an expansion.
- **Responsive > fast.** Print something in <100ms. Print before network requests so
  it never looks hung.
- **Show progress** (spinner/progress bar) for long tasks; show ETA or animation so it
  doesn't look stuck. Hide logs behind progress bars but surface them on error. Delay
  spinners ~150ms (skip for sub-second work), cap redraws at ~60fps, and show ETA for
  tasks longer than ~30s.
- **Parallelize** where useful, but keep progress output un-interleaved; use a library
  (tqdm, schollz/progressbar, node-progress).
- **Time out** network calls with sensible, configurable defaults.
- **Recoverable** — up-arrow + enter should resume after a transient failure.
- **Crash-only** — avoid cleanup or defer it so the program can exit immediately.
- **Performance target: 100–500ms** startup. `time mycli` to benchmark. Lazy-load only
  the invoked command.

---

## Terminal lifecycle (full-screen TUIs)

- **Use the alternate screen** for full-screen sessions; keep bounded, one-shot
  workflows inline.
- **Prefer framework-managed cleanup.** Restore raw mode, screen buffer, cursor, and
  input modes on every exit path (normal, error, panic, interrupt). Don't hand-roll
  signal handling the framework already owns.
- **Re-layout from the current size on resize.** Coalesce bursts only when layout work
  is expensive.
- **Suspend/resume is a boundary.** For an editor/shell handoff, use the framework's
  suspend API: pause input, restore the terminal, wait, re-enter modes, reload changed
  data, force a full redraw. Redrawing repaints the model; it doesn't refresh data.
- **Keep logs off the TUI screen.** Use a file, framework console, or a separate stream.

---

## Signals

- **Ctrl-C (INT):** exit ASAP; print something before cleanup; add a timeout to cleanup.
- **Ctrl-C during long cleanup:** skip it, tell the user what a second Ctrl-C will do
  (`Gracefully stopping... press Ctrl+C again to force`).

---

## Configuration & environment variables

Choose the mechanism by specificity/stability:

| Type | Examples | Mechanism |
| --- | --- | --- |
| Varies per invocation | debug level, dry-run | flags |
| Stable per user/machine, varies per project | paths, color, proxy | flags + env vars |
| Stable per project, shared | Makefile, package.json | version-controlled file |

- **Precedence (high→low):** flags → env vars → project config (`.env`) → user config →
  system config.
- **Follow the XDG spec:**
  - config → `$XDG_CONFIG_HOME` (`~/.config/myapp`)
  - data → `$XDG_DATA_HOME` (`~/.local/share/myapp`)
  - cache → `~/.cache/myapp` (macOS `~/Library/Caches/myapp`, Windows `%LOCALAPPDATA%\myapp`)
- **Env var names:** uppercase letters, numbers, underscores only; don't start with a number.
- **Respect standard env vars:** `NO_COLOR`, `DEBUG`, `EDITOR`, `HTTP(S)_PROXY`/`NO_PROXY`,
  `SHELL`, `TERM`, `TMPDIR`, `HOME`, `PAGER`, `LINES`/`COLUMNS`.
- **Read `.env`** for per-project env vars, but don't use it as a real config file
  (no history, strings only, poorly organized, often holds secrets).
- **Never read secrets from env vars.** Use credential files, pipes, `AF_UNIX` sockets,
  or a secret manager.
- **Don't modify other programs' config without consent**; prefer a new file
  (`/etc/cron.d/myapp`) over appending.

---

## Version

- Support `--version`, `-V`, and (multi-command) `version`. For single-command CLIs,
  `-v` may mean version if not used for verbose.
- Version command is a good place for extra debug info (platform, runtime version).
- Send the version string as the **User-Agent** on API calls.

---

## Future-proofing

- Interfaces (subcommands, flags, args, config, env vars) are commitments — keep them stable.
- **Keep changes additive**; warn before non-additive (deprecation) changes, with a
  migration path.
- **Human output may change freely** — that's how you iterate. Steer scripts to
  `--json`/`--plain`.
- **No catch-all subcommands, no arbitrary abbreviations** (see Naming).
- **No time bombs** — don't depend on a server/endpoint that won't exist in 20 years.

---

## Review reflexes

Apply these to every layout or review, even when the question is about something else.

- **Clutter audit — make "busy" countable.** Count border-nesting depth (more than one
  border between the edge and content is usually too much), how many signals encode the
  same state (`[PASS]` + green + checkmark + row marker = four), markers repeated on
  every row (which therefore mark nothing), and the share of cells spent on chrome vs
  data. Name the exact elements to remove; don't stop at "simplify it".
- **Pressure-test the floor.** State what happens at 80×24 and in a 60-column split:
  which pane wins, what hides/truncates, what becomes drill-down, and when the honest
  "too small" state appears. Every multi-column design needs a single-pane fallback.

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

---

## Sources

- https://github.com/cli-guidelines/cli-guidelines/blob/main/content/_index.md
- https://devcenter.heroku.com/articles/cli-style-guide
- https://jdx.dev/posts/2018-10-08-12-factor-cli-apps/ (mirror of
  https://jdxcode.medium.com/12-factor-cli-apps-dd3c227a0e46)
- https://github.com/gfargo/tui-design-skill (full-screen TUI patterns, lifecycle,
  accessibility, review reflexes)
- https://github.com/curiositech/windags-skills (color degradation, anti-patterns,
  progress indicators, quality gates)
