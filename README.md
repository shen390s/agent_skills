# Crush skills

A collection of portable [Agent Skills](https://agentskills.io) for AI coding
assistants. Each skill is a single `SKILL.md` file written against the open
Agent Skills format, so the same skill works in Crush, Claude Code, and Kiro
(AWS).

## Skills

| Skill | Description |
|-------|-------------|
| [`cli-ux`](skills/cli-ux/SKILL.md) | Design and review CLI/TUI user experience (naming, help, flags, output, errors, prompts, colors, config). Synthesizes the [CLI Guidelines](https://cli-guidelines.github.io), the [Heroku CLI Style Guide](https://devcenter.heroku.com/articles/cli-style-guide), and Jeff Dickey's [12 Factor CLI Apps](https://jdx.dev/posts/2018-10-08-12-factor-cli-apps/). |

## Requirements

- Any of: Crush, Claude Code, or Kiro (AWS)
- `bash` and `cp` (POSIX) — the installer has no other dependencies
- Nix with flakes enabled (optional, for `nix run`)

## Installation

The installer copies every skill from `skills/<name>/SKILL.md` into each tool's
skills directory. Running it with no arguments shows help; give it a tool or
skill to install (defaults: **all** skills to **Crush**).

### Nix (run straight from the repo)

```bash
nix run github:shen390s/agent_skills -- --help       # view help
nix run github:shen390s/agent_skills -- all          # all skills -> all tools
nix run github:shen390s/agent_skills -- claude --skill cli-ux
```

The flake wraps `install.sh` together with `skills/`, so the installer finds its
skill sources from the Nix store. Any arguments after `--` are passed to the
installer.

### From a checkout

```bash
./install.sh                       # show help (no action)
./install.sh crush                 # all skills -> Crush (global)
./install.sh all                   # all skills -> all tools
./install.sh --skill cli-ux        # one skill -> Crush
./install.sh claude --skill cli-ux # one skill -> Claude Code
```

Select tools with positional args or `--tool`; select skills with `--skill`
(both repeatable). `all` means "every tool" / "every skill in `skills/`".

### Global (available in every project)

```bash
./install.sh all
./install.sh --tool crush --tool kiro --skill cli-ux
```

Global install locations:

| Tool | Location |
|------|----------|
| Crush | `~/.config/crush/skills/<skill>/` |
| Claude Code | `~/.claude/skills/<skill>/` |
| Kiro | `~/.kiro/skills/<skill>/` |

Override the global root with the tool's env var: `CRUSH_SKILLS_DIR`,
`CLAUDE_CONFIG_DIR`, or `KIRO_HOME`.

### Project-local (one project only)

```bash
./install.sh --project=. all                                # all skills -> all tools (this project)
./install.sh --project=/path/to/repo claude --skill cli-ux  # one skill -> Claude Code (this project)
```

Project-local install locations:

| Tool | Location |
|------|----------|
| Crush | `.crush/skills/<skill>/` |
| Claude Code | `.claude/skills/<skill>/` |
| Kiro | `.kiro/skills/<skill>/` |

### Options

```text
[tool ...]        Tools to install into (default: crush; "all" = all tools)
--tool NAME       Tool to install into (repeatable)
--skill NAME      Skill to install, or "all" (repeatable; default: all skills)
--project[=DIR]   Install project-locally (default: current dir)
-f, --force       Overwrite existing installations without prompting
--no-color        Disable colored output
-n, --dry-run     Show what would be done without doing it
-l, --list        List available skills and exit
-V, --version     Show version and exit
-h, --help        Show this help
```

## Usage

After installation, no manual activation is needed. The assistant automatically
loads a skill when a request matches its `description`. For `cli-ux`, that means
any request to design or review CLI/TUI UX:

- "Design a CLI for ..."
- "Review this command's help text and output."
- "What flags and output format should this tool have?"

In Crush a skill appears as `user:<name>` (global) or `project:<name>`
(project). In Claude Code and Kiro it is discovered by the `name` field.

## Adding a new skill

Create a directory under `skills/` with a `SKILL.md` inside:

```text
skills/
  my-skill/
    SKILL.md
```

The installer auto-discovers it — no installer changes needed. The frontmatter
must include `name` (lowercase, hyphenated) and `description` (a clear trigger
for when to load it).

## Update

Re-run the installer; it overwrites installed copies (add `-f` to skip the
overwrite prompt).

## Uninstall

```bash
rm -rf ~/.config/crush/skills/cli-ux   # Crush (global)
rm -rf ~/.claude/skills/cli-ux         # Claude Code (global)
rm -rf ~/.kiro/skills/cli-ux           # Kiro (global)
```

For project-local installs, remove the matching `.crush/skills/<skill>`,
`.claude/skills/<skill>`, or `.kiro/skills/<skill>` directory inside the project.

## Layout

```text
skills/
  <name>/
    SKILL.md    # one skill per directory (source of truth)
install.sh      # installer for Crush / Claude Code / Kiro
README.md       # this guide
```

## Editing a skill

Edit `skills/<name>/SKILL.md` directly, then re-run `./install.sh` to propagate
changes to each installed location.
