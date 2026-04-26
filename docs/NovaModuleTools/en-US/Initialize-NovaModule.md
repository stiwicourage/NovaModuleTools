---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
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

The command collects project details interactively, including the module name, description, version, author, minimum
PowerShell version, Git initialization, and, for the standard scaffold, optional basic Pester support.

Use this command when you want to start a new module in the NovaModuleTools structure without hand-creating the project
layout.

Use `-Path` when you want to create the project under a specific base directory. Positional path syntax is no longer
supported.

Use `-Example` when you want the scaffold to start from the packaged example project instead of the minimal default
layout. The example flow keeps the example source, resource, and test files, skips the Pester enable/disable question,
and applies the interactive metadata values to the copied `project.json`.

This command supports `-WhatIf` and `-Confirm` through PowerShell `SupportsShouldProcess`. Use `-WhatIf` to preview the
scaffold target after the interactive answers have been collected, without creating folders, writing `project.json`, or
initializing Git.

## EXAMPLES

### EXAMPLE 1

```text
PS> Initialize-NovaModule -Path ~/Work
```

Starts the interactive scaffold flow and creates the new module under `~/Work`.

### EXAMPLE 2

```text
PS> Initialize-NovaModule -Path ~/Work -WhatIf
```

Shows what would be created without writing the scaffold.

### EXAMPLE 3

```text
PS> Initialize-NovaModule -Example -Path ~/Work
```

Creates a new project under `~/Work` from the packaged example template and applies the answers from the interactive
prompt flow to the copied `project.json`.

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
validation. The packaged example scaffold keeps its bundled example source and tests, while still updating prompt-driven
metadata such as project name, description, version, author, and PowerShell host version.

`Initialize-NovaModule` uses `SupportsShouldProcess`, so `Get-Help Initialize-NovaModule -Full` surfaces native
`-WhatIf` and
`-Confirm` support.

## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Get-NovaProjectInfo.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaCli.md
