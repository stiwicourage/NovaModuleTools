---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/26/2026
PlatyPS schema version: 2024-05-01
title: Test-NovaBuild
---

# Test-NovaBuild

## SYNOPSIS

Runs Pester tests for the current NovaModuleTools project.

## SYNTAX

### __AllParameterSets

```text
PS> Test-NovaBuild [-Build] [[-TagFilter] <string[]>] [[-ExcludeTagFilter] <string[]>]
 [[-OutputVerbosity] <string>] [[-OutputRenderMode] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Test-NovaBuild` reads the Pester configuration from `project.json`, resolves the correct test path, and runs the test
suite against the current project.

Use `-Build` when you want Nova to rebuild the project output before the Pester run starts.

With the default
`BuildRecursiveFolders=true`, test files in nested folders under `tests` are discovered and run. Set
`BuildRecursiveFolders=false` to limit discovery to top-level `tests/*.Tests.ps1` files, following Pester's normal
test-file convention. The generated Pester XML report is written to `artifacts/TestResults.xml`.

This command supports `-WhatIf` and `-Confirm` through PowerShell `SupportsShouldProcess`. Use `-WhatIf` to preview the
planned test run and XML output path without creating `artifacts/` or invoking Pester.

## EXAMPLES

### EXAMPLE 1

```text
PS> Test-NovaBuild
```

Runs the Pester tests for the current project.

### EXAMPLE 2

```text
PS> Test-NovaBuild -Build
```

Builds the project first, then runs the configured Pester test workflow.

### EXAMPLE 3

```text
PS> Test-NovaBuild -TagFilter unit,fast
```

Runs only tests tagged `unit` or `fast`.

### EXAMPLE 4

```text
PS> Test-NovaBuild -ExcludeTagFilter slow
```

Runs the test suite while excluding tests tagged `slow`.

### EXAMPLE 5

```text
PS> Test-NovaBuild -OutputVerbosity Normal -OutputRenderMode Ansi
```

Overrides the console output settings for the current test run while keeping color-capable rendering.

### EXAMPLE 6

```text
PS> Test-NovaBuild -WhatIf
```

Previews the planned Pester run without executing tests or writing `artifacts/TestResults.xml`.

### EXAMPLE 7

```text
PS> Test-NovaBuild -Build -WhatIf
```

Previews the build-before-test workflow without rebuilding the project or running Pester.

## PARAMETERS

### -Build

Builds the project before the test workflow starts.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: (All)
    Position: Named
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: [ ]
HelpMessage: ''
```

### -ExcludeTagFilter

Array of Pester tags to exclude from the run.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -TagFilter

Array of Pester tags to include in the run.

```yaml
Type: System.String[]
DefaultValue: ''
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

### -OutputVerbosity

Overrides the Pester console verbosity for the current run.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- None
- Normal
- Detailed
- Diagnostic
HelpMessage: ''
```

### -OutputRenderMode

Overrides how Pester renders console output for the current run.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- Auto
- Ansi
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

This cmdlet does not emit an output object. It throws when the test run fails.

## NOTES

The generated test result XML is written to `artifacts/TestResults.xml`.

`Test-NovaBuild` uses `SupportsShouldProcess`, so `Get-Help Test-NovaBuild -Full` surfaces native `-WhatIf` and
`-Confirm` support.

## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Get-NovaProjectInfo.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Publish-NovaModule.md
