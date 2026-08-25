# Full-screen TUI design

Rules for full-screen terminal sessions: lifecycle, accessibility, and layout review.
Load this for dashboards, pickers, editors, REPLs, and ncurses-style tools.

## Terminal lifecycle

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
- **Provide an escape hatch.** Exit immediately on Ctrl-C or `q` without corrupting the
  terminal layout.
- **Map vim keys by default.** For list navigation or scrolling, bind `j`/`k` (up/down)
  and `h`/`l` (left/right) alongside the arrow keys.
- **Handle the "too small" state.** When the terminal is smaller than the layout
  requires, show a clean non-crashing message (e.g. "Terminal too small (requires
  80x24)") instead of garbling.

## Accessibility

- **Never use color alone.** Pair it with text, shape, position, or symbols; provide an
  ASCII fallback when Unicode support is uncertain.
- **Keep meaning in monochrome.** `NO_COLOR`/16-color must not erase the signal.
- **Every action is keyboard-reachable.** Mouse may accelerate but must not gate.
- **Offer a plain `--no-tui` (or equivalent) mode** for automation and accessibility, so
  the tool still works when a full-screen UI is unavailable or unusable.

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
