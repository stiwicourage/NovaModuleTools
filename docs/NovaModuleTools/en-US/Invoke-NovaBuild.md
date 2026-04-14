---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/14/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaBuild
---

# Invoke-NovaBuild

## SYNOPSIS

Builds the current NovaModuleTools project into a ready-to-import PowerShell module.

## SYNTAX

### __AllParameterSets

```powershell
Invoke-NovaBuild [<CommonParameters>]
```

## DESCRIPTION

`Invoke-NovaBuild` runs the NovaModuleTools build pipeline for the current project.

The command:

1. clears the existing `dist/` output
2. generates the module `.psm1`
3. validates duplicate top-level function names when enabled
4. writes the module manifest
5. builds external help from the Markdown files in `docs/`
6. copies project resources into the built module output

If `SetSourcePath` is enabled, the generated `.psm1` includes `# Source:` markers before each source block.

If `Preamble` is configured, those lines are written at the very top of the generated `.psm1` before the rest of the
module content.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> Invoke-NovaBuild
```

Builds the current project into `dist/<ProjectName>/`.

### EXAMPLE 2

```powershell
PS> Invoke-NovaBuild -Verbose
```

Builds the current project and writes verbose progress for the build workflow.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### None

This cmdlet does not emit an output object.

## NOTES

Run this command from the project root so `project.json`, `src/`, `docs/`, and `tests/` resolve correctly.

## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Get-NovaProjectInfo.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Test-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Publish-NovaModule.md
