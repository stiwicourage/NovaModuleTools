---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 03/19/2026
PlatyPS schema version: 2024-05-01
title: Test-NovaBuild
---

# Test-NovaBuild

## SYNOPSIS

Runs Pester tests using settings from project.json

## SYNTAX

### __AllParameterSets

```
Test-NovaBuild [[-TagFilter] <string[]>] [[-ExcludeTagFilter] <string[]>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Run Pester tests using the specified configuration and settings as defined in project.json. With the default
`BuildRecursiveFolders=true`, test files in nested folders under `tests` are discovered and run. Set
`BuildRecursiveFolders=false` to limit discovery to top-level `tests/*.Tests.ps1` files, following Pester's normal
test-file convention. The generated Pester XML report is written to `artifacts/TestResults.xml`.

## EXAMPLES

### EXAMPLE 1

Test-NovaBuild
Runs the Pester tests for the project.

### EXAMPLE 2

Test-NovaBuild -TagFilter "unit","integrate"
Runs the Pester tests for the project, that has tag unit or integrate

### EXAMPLE 3

Test-NovaBuild -ExcludeTagFilter "unit"
Runs the Pester tests for the project, excludes any test with tag unit

## PARAMETERS

### -ExcludeTagFilter

Array of tags to exclude, Provide the tag Pester should exclude

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

Array of tags to run, Provide the tag Pester should run

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}




