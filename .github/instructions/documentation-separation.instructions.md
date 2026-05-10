---
applyTo: "docs/**/*.html,docs/assets/**/*.js,docs/NovaModuleTools/en-US/**/*.md,README.md,CONTRIBUTING.md,CHANGELOG.md,RELEASE_NOTE.md"
---

# NovaModuleTools documentation separation

## Purpose

NovaModuleTools has multiple documentation surfaces with different audiences. Keep them clearly separated.

## Documentation audiences

- `docs/*.html` - GitHub Pages end-user documentation
- `docs/NovaModuleTools/en-US/*.md` - PowerShell command help source
- `README.md` / `CONTRIBUTING.md` - contributor and maintainer documentation

## Separation rules

- Do not write `docs/*.html` as if it were cmdlet help.
- Do not write cmdlet help markdown as if it were `nova` CLI documentation.
- Use CLI syntax in CLI-oriented website docs when a CLI variant exists.
- Use cmdlet syntax in help markdown and PowerShell-specific contributor guidance.

## Allowed exception

- A PowerShell-only command may appear in CLI-oriented website docs when there is no CLI alternative for that task.
- The clearest current example is installation:
    - `Install-Module -Name NovaModuleTools` is a valid website-doc example
    - `nova` installation/setup docs may mention it because installation is still PowerShell-driven

## Practical review questions

- Does this page describe a `nova` workflow or a PowerShell cmdlet workflow?
- If a `nova` command exists, is the website doc using it instead of the cmdlet?
- If a cmdlet is shown in website docs, is it there because no CLI variant exists?
- Would an end user mistake this page for cmdlet help?

## Follow-up expectations

- Review `CHANGELOG.md` when a docs separation fix changes how users are guided.
- Review `README.md` / `CONTRIBUTING.md` if contributor expectations or documentation ownership changed.
