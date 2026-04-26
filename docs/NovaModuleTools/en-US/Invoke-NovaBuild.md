---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/25/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaBuild
---

# Invoke-NovaBuild

## SYNOPSIS

Builds the current NovaModuleTools project into a ready-to-import PowerShell module.

## SYNTAX

### __AllParameterSets

```text
PS> Invoke-NovaBuild [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Invoke-NovaBuild` runs the NovaModuleTools build pipeline for the current project.

This command supports `-WhatIf` and `-Confirm` through PowerShell `SupportsShouldProcess`. Use `-WhatIf` to preview the
build target without clearing `dist/` or generating new build output.

The command:

1. clears the existing `dist/` output
2. generates the module `.psm1`
3. validates duplicate top-level function names when enabled
4. writes the module manifest
5. builds external help from the Markdown files in `docs/`
6. copies project resources into the built module output

To update the installed `NovaModuleTools` module itself, use `Update-NovaModuleTool` (alias:
`Update-NovaModuleTools`).

Use `Set-NovaUpdateNotificationPreference` or `Get-NovaUpdateNotificationPreference` when you want to control whether
prerelease self-updates are eligible.

If `Invoke-NovaBuild` detects that a newer `NovaModuleTools` release or prerelease is available after the build, the
warning includes the recommended update command together with the release notes link from the installed module
manifest.

If `SetSourcePath` is enabled, the generated `.psm1` includes `# Source:` markers before each source block.

If `Preamble` is configured, those lines are written at the very top of the generated `.psm1` before the rest of the
module content.

## EXAMPLES

### EXAMPLE 1

```text
PS> Invoke-NovaBuild
```

Builds the current project into `dist/<ProjectName>/`.

### EXAMPLE 2

```text
PS> Invoke-NovaBuild -Verbose
```

Builds the current project and writes verbose progress for the build workflow.

### EXAMPLE 3

```text
PS> Invoke-NovaBuild -WhatIf
```

Previews the build action without resetting `dist/` or generating module output.

### EXAMPLE 4

```text
PS> Invoke-NovaBuild -Confirm
```

Prompts before the build workflow runs when confirmation is required.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, -WarningVariable, -WhatIf, and -Confirm. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### None

This cmdlet does not emit an output object.

## NOTES

Run this command from the project root so `project.json`, `src/`, `docs/`, and `tests/` resolve correctly.

`Invoke-NovaBuild` uses `SupportsShouldProcess`, so `Get-Help Invoke-NovaBuild -Full` shows the native `-WhatIf` and
`-Confirm` behavior.

## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Get-NovaProjectInfo.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Test-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Publish-NovaModule.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Update-NovaModuleTools.md
