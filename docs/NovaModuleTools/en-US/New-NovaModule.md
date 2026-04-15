---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/14/2026
PlatyPS schema version: 2024-05-01
title: New-NovaModule
---

# New-NovaModule

## SYNOPSIS

Creates a new NovaModuleTools project scaffold through an interactive prompt flow.

## SYNTAX

### __AllParameterSets

```powershell
PS> New-NovaModule [[-Path] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`New-NovaModule` creates a new project folder, the standard `src/`, `tests/`, and `docs/` layout, and a starter
`project.json` file.

The command collects project details interactively, including the module name, description, version, author, minimum
PowerShell version, Git initialization, and basic Pester support.

Use this command when you want to start a new module in the NovaModuleTools structure without hand-creating the project
layout.

This command supports `-WhatIf` and `-Confirm` through PowerShell `SupportsShouldProcess`. Use `-WhatIf` to preview the
scaffold target after the interactive answers have been collected, without creating folders, writing `project.json`, or
initializing Git.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> New-NovaModule -Path ~/Work
```

Starts the interactive scaffold flow and creates the new module under `~/Work`.

### EXAMPLE 2

```powershell
PS> New-NovaModule -Path ~/Work -WhatIf
```

Shows what would be created without writing the scaffold.

### EXAMPLE 3

```bash
nova init ~/Work
```

Runs the same scaffold flow through the `nova` CLI.

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
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

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

Generated projects start with NovaModuleTools defaults for recursive discovery, source markers, and duplicate-function
validation.

`New-NovaModule` uses `SupportsShouldProcess`, so `Get-Help New-NovaModule -Full` surfaces native `-WhatIf` and
`-Confirm` support.

## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Get-NovaProjectInfo.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaCli.md




