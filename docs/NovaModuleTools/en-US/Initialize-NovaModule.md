---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: 'https://www.novamoduletools.com/core-workflows.html#scaffold'
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/25/2026
PlatyPS schema version: 2024-05-01
title: Initialize-NovaModule
---

# Initialize-NovaModule

## SYNOPSIS

Creates a new NovaModuleTools project scaffold through an interactive prompt flow.

## SYNTAX

### __AllParameterSets

```text
PS> Initialize-NovaModule [-Path <string>] [-Example] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Initialize-NovaModule` creates a new project folder, the standard `src/` layout, and a starter `project.json` file.

The standard scaffold `project.json` includes Nova's standard Pester defaults, including an opt-in `CodeCoverage` block with `Enabled=false`, common `src/` coverage paths, JaCoCo output in `artifacts/coverage.xml`, and a `90` percent target that can be enabled later.

The command collects project details interactively, including the module name, description, version, author, minimum PowerShell version, Git initialization, and an optional Agentic Copilot starter package. Before the first interactive question, Nova checks whether a newer `NovaModuleTools` release is available and warns without blocking the scaffold flow. When Git initialization is enabled, Nova also creates or updates a default `.gitignore` in the generated project root so common local and CI artifact paths such as `artifacts/`, `dist/`, `run.ps1`, and `reload.ps1` are ignored from the start. Existing `.gitignore` files are preserved and only receive the missing Nova-managed entries. When you enable the Agentic package, Nova also asks for a project short name used in generated guidance placeholders such as `Invoke-<ShortName>*`; for NovaModuleTools the short name is `Nova`, but it could also have been
`NMT`. The Agentic package follows Nova's maintained agentic guidance through a filtered starter mirror, including Nova build/test/package expectations, `project.json`
`Manifest.PowerShellHostVersion` compatibility guidance, strict ScriptAnalyzer guidance without excluded rules, generated `dist` module files, command-help ownership, source-mirrored test guidance, guidance that ScriptAnalyzer findings reported by
`run.ps1` must be fixed before handoff, explicit PSScriptAnalyzer workflow guidance for `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`, `./run.ps1`, and focused `Invoke-ScriptAnalyzer` usage, explicit public/private PowerShell file ownership rules, best-effort source/helper-script maintainability guidance plus separate test-design guidance delivered through Agentic Copilot files, a generated `scripts/build/Test-TextFileFormatting.ps1` helper plus `tests/TextFileFormatting.Tests.ps1` when project tests are enabled so trailing blank-line violations fail the project test flow, explicit valid-PlatyPS help guidance for `docs/<ProjectName>/en-US/*.md` that uses `New-MarkdownCommandHelp`, `Update-MarkdownCommandHelp`, and `Test-MarkdownCommandHelp`, and a strict file-ending rule for changed or generated text files. For the standard scaffold, the interactive flow also includes optional basic Pester support.

If you enter an invalid answer during the interactive flow, `Initialize-NovaModule` reports the validation problem immediately and retries that prompt before it continues to the next question.

Use this command when you want to start a new module in the NovaModuleTools structure without hand-creating the project layout.

Use `-Path` when you want to create the project under a specific base directory. Positional path syntax is no longer supported.

Use `-Example` when you want the scaffold to start from the packaged example project instead of the minimal default layout. The example flow keeps the example source, resource, and source-mirrored test files, skips the Pester enable/disable question, and applies the interactive metadata values to the copied `project.json`, including an enabled-by-default `CodeCoverage` block that targets `src/**/*.ps1`. The packaged example can run `Test-NovaBuild` before `Invoke-NovaBuild`, and the same test flow writes JaCoCo coverage to `artifacts/coverage.xml`. The standard and example flows share the same upfront Nova update warning, inline validation and retry behavior for interactive answers, and optional Agentic Copilot setup prompt after the Git question. When Git is enabled in either flow, Nova also ensures the generated project root has the default `.gitignore` entries for local and CI artifacts without overwriting any existing `.gitignore` content. When you answer
`Yes`, Nova asks for the short project name, adds the same starter package to either scaffold style, and merges the example README instead of replacing it with the generic starter README outright.

This command supports `-WhatIf` and `-Confirm` through PowerShell `SupportsShouldProcess`. Use `-WhatIf` to preview the scaffold target after the interactive answers have been collected, without creating folders, writing `project.json`, or initializing Git.

During scaffold creation, Nova shows progress for the main setup phases and finishes with the created project root plus the next cmdlet to run.

## EXAMPLES

### EXAMPLE 1

```text
PS> Initialize-NovaModule -Path ~/Work
```

Starts the interactive scaffold flow and creates the new module under `~/Work`. Invalid interactive answers are retried immediately before the command continues.

### EXAMPLE 2

```text
PS> Initialize-NovaModule -Path ~/Work -WhatIf
```

Shows what would be created without writing the scaffold.

### EXAMPLE 3

```text
PS> Initialize-NovaModule -Example -Path ~/Work
```

Creates a new project under `~/Work` from the packaged example template and applies the answers from the interactive prompt flow to the copied `project.json`. Invalid interactive answers are retried immediately here as well.

### EXAMPLE 4

```text
PS> Initialize-NovaModule -Example -Path ~/Work -WhatIf
```

Shows what the example-based scaffold flow would create without writing files.

## PARAMETERS

### -Path

Base directory where the new project folder will be created.

```yaml
Type: System.String
DefaultValue: (Get-Location).Path
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Example

Create the new project from the packaged example template instead of the minimal default scaffold.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, -WarningVariable, -WhatIf, and -Confirm. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### None

This cmdlet does not emit an output object.

## NOTES

Generated projects start with NovaModuleTools defaults for recursive discovery, source markers, duplicate-function validation, and—when Git is enabled—a default `.gitignore` for common local and CI artifact paths. The standard scaffold keeps Pester `CodeCoverage` opt-in (`Enabled=false`, shared `src/` paths, JaCoCo output in `artifacts/coverage.xml`, and a `90` percent target). The packaged example scaffold keeps its bundled example source and source-mirrored tests, while also enabling that same `CodeCoverage` block by default so `Test-NovaBuild` measures `src/**/*.ps1` without requiring a prior build. Both scaffold styles still update prompt-driven metadata such as project name, description, version, author, and PowerShell host version. The optional Agentic Copilot starter package adds repository-local Copilot workflow files under the project root and `.github/` that tell agents to keep build/test/package workflows on Nova, treat `project.json` `Manifest.PowerShellHostVersion` as the PowerShell compatibility target, run ScriptAnalyzer before build/test through the repo-standard `Invoke-ScriptAnalyzerCI.ps1` /
`run.ps1` workflow, fix any ScriptAnalyzer findings before handoff, run project tests through `Test-NovaBuild` instead of direct `Invoke-Pester`, leave `.psm1` / `.psd1` files to generated
`dist` output, generate and validate command help with the Microsoft.PowerShell.PlatyPS cmdlets instead of hand-written Markdown structure, require a matching help file for every new public entry point in the same change, mirror new tests to source files, and add a text-file-formatting guardrail helper plus a Pester guardrail test when project tests are enabled.

`Initialize-NovaModule` uses `SupportsShouldProcess`, so `Get-Help Initialize-NovaModule -Full` surfaces native
`-WhatIf` and
`-Confirm` support.

Press `Ctrl+C` during the interactive prompt flow if you want to cancel before Nova creates the scaffold.

## RELATED LINKS

- [Invoke-NovaBuild](./Invoke-NovaBuild.md)
- [Get-NovaProjectInfo](./Get-NovaProjectInfo.md)
