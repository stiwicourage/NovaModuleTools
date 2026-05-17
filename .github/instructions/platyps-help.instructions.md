---
applyTo: "docs/NovaModuleTools/**/*.md"
---

# PlatyPS command help rules

## Scope

Use this file when creating or updating command help under `docs/NovaModuleTools/en-US/`.

## Why this matters

- Nova build imports command-help markdown with `Import-MarkdownCommandHelp` and converts it to MAML with `Export-MamlCommandHelp`.
- `Microsoft.PowerShell.PlatyPS` is part of Nova's help toolchain, so use its cmdlets instead of inventing command-help Markdown by hand.

## Required workflow

1. Build and import the dist module before generating or updating help files. This ensures PlatyPS picks up the correct module name for both the `Module Name` and `external help file` metadata fields.

```powershell
Invoke-NovaBuild
Import-Module ./dist/NovaModuleTools/NovaModuleTools.psd1 -Force
```

2. For new command help, generate the initial skeleton with `New-MarkdownCommandHelp` from the imported module commands rather than starting from a blank Markdown file.

```powershell
$newMarkdownHelp = @{
    CommandInfo  = Get-Command -Module 'NovaModuleTools'
    OutputFolder = './docs'
    WithModulePage = $true
    Force = $true
}
New-MarkdownCommandHelp @newMarkdownHelp
```

3. Every new public entry point must add its matching command-help file in the same change. A new `src/public/<CommandName>.ps1` file is not done until `docs/NovaModuleTools/en-US/<CommandName>.md` exists.
4. Keep the resulting command-help files under `docs/NovaModuleTools/en-US/` before handoff. If you generate files in a staging folder first, move the command-help markdown files into the repository's locale folder before you finish.
5. For existing command help, refresh syntax and parameter metadata with `Update-MarkdownCommandHelp` instead of editing the generated YAML structure by hand.

```powershell
Measure-PlatyPSMarkdown -Path ./docs/NovaModuleTools/en-US/*.md |
        Where-Object FileType -match 'CommandHelp' |
        Update-MarkdownCommandHelp -Path {$_.FilePath}
```

6. Validate the final help with `Test-MarkdownCommandHelp -DetailView`, and inspect `Import-MarkdownCommandHelp` diagnostics when the structure or build result is unclear.

```powershell
Test-MarkdownCommandHelp -Path ./docs/NovaModuleTools/en-US/*.md -DetailView

Import-MarkdownCommandHelp -Path ./docs/NovaModuleTools/en-US/<CommandName>.md |
        Select-Object -ExpandProperty Diagnostics
```

7. Remember the build path: Nova effectively runs `Measure-PlatyPSMarkdown | Import-MarkdownCommandHelp | Export-MamlCommandHelp`. If your help files fail that path, the help is not done yet.
8. `-WithModulePage` is optional. Nova build consumes the command-help markdown files; a module page can exist, but it does not replace per-command help.

## Required format

- Files under `docs/NovaModuleTools/en-US/` must be valid PlatyPS command-help markdown, not plain project prose.
- Start new help files from a PlatyPS-generated skeleton or from an existing valid help file that already matches the repository's help shape.
- Keep one command-help file per public entry point, and match the markdown file name to the command name.
- Keep the YAML metadata block at the top of every help file, delimited by `---`.
- Keep the metadata aligned with the command being documented. At minimum, preserve the same metadata keys used by the repository's existing valid help files, including `document type`, `external help file`, `HelpUri`, `Locale`, `Module Name`, `ms.date`, `PlatyPS schema version`, and `title`.
- The `external help file` field must always use the module name, not the command name: `NovaModuleTools-Help.xml`. The `Module Name` field must match the project name. When both fields use the module name, Nova build produces a single `<ModuleName>-Help.xml` under `dist/<ModuleName>/en-US/`. If either field contains a command name instead, the build produces per-command XML files and the module manifest cannot find its help.
- Keep the H1 title equal to the exact command name.
- Preserve the standard PlatyPS section order with uppercase H2 headers: `SYNOPSIS`, `SYNTAX`, optional `ALIASES`, `DESCRIPTION`, `EXAMPLES`, `PARAMETERS`, `INPUTS`, `OUTPUTS`, `NOTES`, and `RELATED LINKS`.
- Keep at least one example under `## EXAMPLES`.
- Keep parameter sections as `### -ParameterName` blocks with the PlatyPS-generated YAML metadata code block.
- Only hand-edit parameter metadata when PlatyPS cannot infer it correctly, especially `DefaultValue` and `SupportsWildcards`.
- `## NOTES` and `## RELATED LINKS` headers are required even when the sections are empty.
- Do not add ad hoc sections or reorder the required sections.
- If content is still incomplete, keep placeholder text inside a valid PlatyPS skeleton rather than collapsing the file into generic Markdown.

## Authoring guidance

- Always import the built dist module (`Import-Module ./dist/NovaModuleTools/NovaModuleTools.psd1 -Force`) before running `New-MarkdownCommandHelp` or `Update-MarkdownCommandHelp`. Generating help without the module imported causes PlatyPS to default `external help file` to the command name instead of the module name, which produces per-command XML files that the module manifest cannot find.
- Prefer generating the initial help shape from the actual public command so syntax and parameter blocks stay aligned with the implementation.
- When source adds a new public entry point, create the matching help file immediately in the same change even if the narrative text still needs follow-up refinement.
- When editing an existing help file, preserve the YAML metadata and parameter sections unless you intentionally regenerate the file from the command surface.
- Use `Update-MarkdownCommandHelp` after command or parameter changes so syntax, aliases, and parameter metadata stay synchronized with the implementation.
- Use `Test-MarkdownCommandHelp` as the quick structural gate before handoff; use `Import-MarkdownCommandHelp` diagnostics when you need more detail.
- Use existing valid files under `docs/NovaModuleTools/en-US/` as the structural template before inventing a new layout.
- Keep command help separate from contributor docs and project/site docs.

## Review expectations

- Reviewers should flag help files that lack YAML metadata, break the expected PlatyPS section structure, skip the `New-MarkdownCommandHelp` / `Update-MarkdownCommandHelp` workflow, or look like plain Markdown prose instead of command help.
- Reviewers should flag help files where `external help file` contains a command name (e.g., `Get-Something-Help.xml`) instead of the module name (`NovaModuleTools-Help.xml`). This produces per-command XML files that the module manifest cannot locate at runtime.
- Reviewers should flag help files that would fail `Test-MarkdownCommandHelp` or produce diagnostics/errors when imported with `Import-MarkdownCommandHelp`.
- Reviewers should flag any new public entry point that does not add its matching command-help file in the same change.
- Treat build errors from `Import-MarkdownCommandHelp` as a sign that the file is not valid PlatyPS help yet.
