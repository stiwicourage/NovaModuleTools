---
applyTo: "docs/**/*.html,docs/assets/**/*.js,docs/NovaModuleTools/en-US/**/*.md,README.md,CONTRIBUTING.md,CHANGELOG.md,RELEASE_NOTE.md"
---

# NovaModuleTools documentation separation

## Files outside the applyTo scope

For any documentation file not covered by the `applyTo` glob, apply the same audience-separation principles on a best-effort basis. If uncertain which audience a file targets, default to contributor/maintainer framing and flag it for review.

## Purpose

NovaModuleTools has multiple documentation surfaces with different audiences. Keep them clearly separated.

## Documentation audiences

- `docs/*.html` - GitHub Pages end-user documentation
- `docs/NovaModuleTools/en-US/*.md` - PowerShell command help source
- `README.md` / `CONTRIBUTING.md` - contributor and maintainer documentation
- `RELEASE_NOTE.md` - end-user-facing release announcements; use CLI syntax when a CLI variant exists, cmdlet syntax otherwise

## Separation rules

- Do not write `docs/*.html` as if it were cmdlet help.
- Do not write cmdlet help markdown as if it were `nova` CLI documentation.
- Use CLI syntax in CLI-oriented website docs when a CLI variant exists.
- Use cmdlet syntax in help markdown and PowerShell-specific contributor guidance.
- On website pages that support the command-surface toggle, keep surface-specific wording behind the matching visibility gate.
    - CLI-only flags, labels, and guidance belong in elements marked with `data-command-visibility="command-line"`.
    - PowerShell-only parameters, labels, and guidance belong in elements marked with `data-command-visibility="powershell"`.
    - Shared, always-visible prose must be surface-neutral: never use `--option` (CLI) or `-Parameter` (PowerShell) syntax in any always-visible element. Surface-specific syntax belongs exclusively inside the matching `data-command-visibility` gate.
    - When a PowerShell-only cmdlet appears in CLI-oriented website docs under the allowed exception, do not place it inside a `data-command-visibility="powershell"` gate; keep it in always-visible prose and note that no `nova` CLI alternative exists.
- When a `nova` command and a PowerShell cmdlet both exist for the same task but behave differently, document the behavioral difference inside the respective `data-command-visibility` gate for each surface. Do not silently substitute one for the other.

## Allowed exception

- A PowerShell-only cmdlet may appear in CLI-oriented website docs only when the specific operation it performs has no equivalent `nova` CLI command at all (not merely when the CLI command is less convenient or less documented).
- The clearest current example is installation:
    - `Install-Module -Name NovaModuleTools` is a valid website-doc example
    - `nova` installation/setup docs may mention it because installation is still PowerShell-driven

## Practical review questions

- Does this page describe a `nova` workflow or a PowerShell cmdlet workflow?
- If a `nova` command exists, is the website doc using it instead of the cmdlet?
- If a cmdlet is shown in website docs, is it there because no CLI variant exists?
- If the page uses the command-surface toggle, do the visible labels, flags, and parameter names match the selected surface?
- Would an end user mistake this page for cmdlet help?

## Follow-up expectations

- Review `CHANGELOG.md` when a docs separation fix changes how users are guided.
- Review `RELEASE_NOTE.md` when a change affects user-visible CLI or cmdlet behavior.
- Review `README.md` / `CONTRIBUTING.md` if contributor expectations or documentation ownership changed.
