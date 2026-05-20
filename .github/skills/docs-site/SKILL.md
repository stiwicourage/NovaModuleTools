---
name: docs-site
description: Guidance for NovaModuleTools website documentation so docs/*.html stay accurate and clearly separated from cmdlet help and contributor docs.
---

# Skill: docs site HTML

## When to use

Use this skill when changing `docs/*.html`, end-user examples, installation guidance, or any documentation that appears on the NovaModuleTools website.

## Relevant files

- `docs/*.html`
- `docs/NovaModuleTools/en-US/*.md`
- `README.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- Relevant `src/public/*.ps1` files

## Expected practices

- Write `docs/*.html` for end users, not for contributors.
- Use CLI-oriented examples when the workflow has a `nova` variant.
- Mention PowerShell cmdlets only when no CLI equivalent exists for that scenario.
- Keep installation guidance explicit about PowerShell-only steps such as `Install-Module`.
- On pages with the command-surface toggle, keep option/parameter wording aligned with the active surface by using `data-command-visibility="command-line"` and `data-command-visibility="powershell"` blocks instead of one shared paragraph that mixes CLI flags with PowerShell parameters.
- Recheck the matching command-help markdown when public behavior changes.

## Common pitfalls

- Mixing `Get-/Set-/Invoke-/Install-` cmdlets into CLI docs where `nova` exists
- Leaving `--option` text visible in PowerShell mode, or `-Parameter` text visible in command-line mode, because the surrounding prose was not split by `data-command-visibility`
- Duplicating cmdlet help text in website docs instead of adapting it for end users
- Forgetting that `docs/NovaModuleTools/en-US/*.md` and `docs/*.html` serve different audiences
- Updating website docs without reviewing changelog or contributor-doc impact

## Verification

- Read the touched HTML page as an end-user flow
- Toggle the page mentally between PowerShell and command-line surfaces and confirm the visible option/parameter names still match that surface
- Check whether the same behavior is documented consistently in help markdown or contributor docs
- Use docs-only validation when no executable behavior changed
