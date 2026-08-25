# Project Instructions

## CLI consistency

`install.sh` is a command-line interface. When modifying it — adding or changing
flags, help text, output, errors, or prompts — apply the `cli-ux` skill
(`skills/cli-ux/`, including its `references/`) and run its review checklist
before finishing.

Verify every change with:

```bash
bash -n install.sh
./install.sh --help
./install.sh --list
./install.sh --dry-run all
```
