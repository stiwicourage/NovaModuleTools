---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/11/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaCli
---

# Invoke-NovaCli

## SYNOPSIS

Runs Nova CLI-style commands through a single command entrypoint.

## SYNTAX

### __AllParameterSets

```powershell
Invoke-NovaCli [[-Command] <string>] [[-Arguments] <string[]>] [<CommonParameters>]
```

## DESCRIPTION

`Invoke-NovaCli` dispatches high-level commands (`info`, `version`, `build`, `test`, `init`, `publish`, `bump`,
`release`) to the matching Nova cmdlet.

This cmdlet is also exposed through the alias `nova`.

## EXAMPLES

### EXAMPLE 1

```powershell
Invoke-NovaCli -Command version
```

Returns the version from `project.json`.

### EXAMPLE 2

```powershell
Invoke-NovaCli -Command build
```

Builds the module using `Invoke-NovaBuild`.

### EXAMPLE 3

```powershell
Invoke-NovaCli -Command publish -Arguments @('--repository', 'PSGallery', '--apikey', '***')
```

Parses CLI arguments and publishes using `Publish-NovaModule`.

## PARAMETERS

### -Command

The command to execute. Supported values: `info`, `version`, `build`, `test`, `init`, `publish`, `bump`, `release`.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: (All)
    Position: 0
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: [ info, version, build, test, init, publish, bump, release ]
HelpMessage: ''
```

### -Arguments

Remaining CLI arguments passed to the selected command.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: (All)
    Position: 1
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: true
DontShow: false
AcceptedValues: [ ]
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`,
`-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`, `-ProgressAction`, `-Verbose`,
`-WarningAction`, and `-WarningVariable`.

## INPUTS

## OUTPUTS

## NOTES

Use `Invoke-NovaCli` when you want a single programmable entrypoint, or use the `nova` alias for interactive CLI usage.

## RELATED LINKS

- [Invoke-NovaBuild](Invoke-NovaBuild.md)
- [Test-NovaBuild](Test-NovaBuild.md)
- [Invoke-NovaRelease](Invoke-NovaRelease.md)

