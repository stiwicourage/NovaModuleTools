---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: 'https://www.novamoduletools.com/core-workflows.html#test'
Locale: en-US
Module Name: NovaModuleTools
ms.date: 05/31/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaTest
---

# Invoke-NovaTest

## SYNOPSIS

Runs the NovaModuleTools unit-test workflow for the current project.

## SYNTAX

### __AllParameterSets

```text
PS> Invoke-NovaTest [[-TagFilter] <string[]>] [[-ExcludeTagFilter] <string[]>]
 [[-OutputVerbosity] <string>] [[-OutputRenderMode] <string>]
 [[-PesterConfigurationOverride] <hashtable>] [-OverrideWarning] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

`Invoke-NovaTest` reads the Pester configuration from `project.json`, discovers the repository unit-test files, and runs the managed Nova test workflow without rebuilding the project first.

Nova resolves a supported installed `Pester` version from `5.7.1` through `5.10.0` for the managed test workflow and stops with a clear dependency error when only unsupported `Pester 6.x` versions are available.

The unit-test workflow writes NUnit XML to `artifacts/UnitTestResults.xml`.

When `Pester.CodeCoverage.Enabled` is `true`, Nova also writes JaCoCo coverage to `artifacts/coverage.xml` and fails the run when the measured percentage is lower than `Pester.CodeCoverage.CoveragePercentTarget`.

Use `Test-NovaBuild` when you need the separate build-validation integration flow that runs against the built module output.

Use `-PesterConfigurationOverride` only when you need runtime-only unit-test data injection through file-backed `New-PesterContainer -Path` objects. In v1, Nova accepts only `Run.Container` and still keeps test discovery, output files, coverage, and required execution flags under Nova control.

Use `-OverrideWarning` only when you intentionally want to bypass Nova's public-file export guard for the current unit-test run.

This command supports `-WhatIf` and `-Confirm` through PowerShell `SupportsShouldProcess`. Use `-WhatIf` to preview the planned unit-test run and output paths without invoking Pester.

## EXAMPLES

### EXAMPLE 1

```text
PS> Invoke-NovaTest
```

Runs the managed unit-test workflow for the current project and writes `artifacts/UnitTestResults.xml`.

### EXAMPLE 2

```text
PS> Invoke-NovaTest -TagFilter fast
```

Runs only unit tests tagged `fast`.

### EXAMPLE 3

```text
PS> Invoke-NovaTest -ExcludeTagFilter slow
```

Runs the unit-test workflow while excluding tests tagged `slow`.

### EXAMPLE 4

```text
PS> Invoke-NovaTest -OutputVerbosity Detailed -OutputRenderMode Ansi
```

Overrides the Pester console output settings for the current unit-test run.

### EXAMPLE 5

```text
PS> $credential = Get-Credential
PS> $container = New-PesterContainer -Path 'tests/public/PublishNovaModule.Tests.ps1' -Data @{ Credential = $credential }
PS> Invoke-NovaTest -PesterConfigurationOverride @{ Run = @{ Container = @($container) } }
```

Runs the standard Nova unit-test discovery set while injecting a runtime-only `PSCredential` into the selected test file through `Run.Container`.

### EXAMPLE 6

```text
PS> Invoke-NovaTest -OverrideWarning
```

Runs the unit-test workflow while explicitly bypassing Nova's public-file export guard for this invocation.

### EXAMPLE 7

```text
PS> Invoke-NovaTest -WhatIf
```

Previews the planned unit-test run and does not execute tests or write artifacts.

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -ExcludeTagFilter

Array of Pester tags to exclude from the unit-test run.

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

### -OutputRenderMode

Overrides how Pester renders console output for the current unit-test run.

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

### -OutputVerbosity

Overrides the Pester console verbosity for the current unit-test run.

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

### -PesterConfigurationOverride

Advanced Pester configuration override for the current unit-test invocation. In v1, Nova accepts only `Run.Container`, and each container must be a file-backed `New-PesterContainer -Path` entry that matches a unit-test file already discovered by Nova.

```yaml
Type: System.Collections.Hashtable
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OverrideWarning

Bypasses Nova's public-file export guard for this unit-test invocation.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
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

### -TagFilter

Array of Pester tags to include in the unit-test run.

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

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Object

Returns the Pester result object from the managed unit-test run.

## NOTES

`Invoke-NovaTest` is the PowerShell unit-test entry point for NovaModuleTools. The `nova test` CLI route maps to this command unless `--build` or `-b` is supplied.

## RELATED LINKS

- [Test-NovaBuild](./Test-NovaBuild.md)
- [Invoke-NovaBuild](./Invoke-NovaBuild.md)
