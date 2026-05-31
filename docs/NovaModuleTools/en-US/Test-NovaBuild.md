---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: 'https://www.novamoduletools.com/core-workflows.html#test'
Locale: en-US
Module Name: NovaModuleTools
ms.date: 05/31/2026
PlatyPS schema version: 2024-05-01
title: Test-NovaBuild
---

# Test-NovaBuild

## SYNOPSIS

Runs the NovaModuleTools build-validation integration-test workflow for the current project.

## SYNTAX

### __AllParameterSets

```text
PS> Test-NovaBuild [[-TagFilter] <string[]>] [[-ExcludeTagFilter] <string[]>]
 [[-OutputVerbosity] <string>] [[-OutputRenderMode] <string>] [-OverrideWarning] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

`Test-NovaBuild` reads the Pester configuration from `project.json`, discovers the build-validation integration tests for the current project, and runs the managed Nova test workflow against the built-module validation surface.

This build-validation flow writes NUnit XML to `artifacts/TestResults.xml`.

Unlike `Invoke-NovaTest`, this command does not enforce source-coverage targets. Use `Invoke-NovaTest` for the unit-test and code-coverage workflow, and use `Test-NovaBuild` when you need build-validation integration coverage that reflects the built module path.

`-OverrideWarning` lets the nested build-validation flow continue even if the `src/public` layout guard reports zero or multiple top-level functions in a public file.

With the default `BuildRecursiveFolders=true`, integration test files in nested folders under `tests` are discovered and run. Set `BuildRecursiveFolders=false` to limit discovery to top-level matching test files.

This command supports `-WhatIf` and `-Confirm` through PowerShell `SupportsShouldProcess`. Use `-WhatIf` to preview the planned build-validation run and XML output path without invoking Pester.

## EXAMPLES

### EXAMPLE 1

```text
PS> Test-NovaBuild
```

Runs the build-validation integration tests for the current project and writes `artifacts/TestResults.xml`.

### EXAMPLE 2

```text
PS> Test-NovaBuild -TagFilter smoke
```

Runs only build-validation tests tagged `smoke`.

### EXAMPLE 3

```text
PS> Test-NovaBuild -ExcludeTagFilter slow
```

Runs the build-validation suite while excluding tests tagged `slow`.

### EXAMPLE 4

```text
PS> Test-NovaBuild -OverrideWarning
```

Continues the build-validation flow even if the public-command file-layout guard reports warnings.

### EXAMPLE 5

```text
PS> Test-NovaBuild -OutputVerbosity Detailed -OutputRenderMode Ansi
```

Overrides the console output settings for the current build-validation run.

### EXAMPLE 6

```text
PS> Test-NovaBuild -WhatIf
```

Previews the planned build-validation run and does not execute tests or write `artifacts/TestResults.xml`.

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

Array of Pester tags to exclude from the build-validation run.

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

Overrides how Pester renders console output for the current build-validation run.

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

Overrides the Pester console verbosity for the current build-validation run.

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

### -OverrideWarning

Continue the nested build-validation setup even if the `src/public` layout guard reports that a public file does not contain exactly one top-level function.

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

### -TagFilter

Array of Pester tags to include in the build-validation run.

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

Returns the Pester result object from the managed build-validation run.

## NOTES

`Test-NovaBuild` is the PowerShell build-validation entry point for NovaModuleTools. The `nova test --build` and `nova test -b` CLI forms map to this command.

## RELATED LINKS

[Invoke-NovaTest](Invoke-NovaTest.md)
[Invoke-NovaBuild](Invoke-NovaBuild.md)
