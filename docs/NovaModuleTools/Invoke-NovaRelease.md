---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/11/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaRelease
---

# Invoke-NovaRelease

## SYNOPSIS

Runs the Nova release pipeline (build, test, version bump, rebuild, publish).

## SYNTAX

### __AllParameterSets

```powershell
Invoke-NovaRelease [[-PublishOption] <hashtable>] [[-Path] <string>] [<CommonParameters>]
```

## DESCRIPTION

`Invoke-NovaRelease` orchestrates a full release flow:

1. Build module (`Invoke-NovaBuild`)
2. Run tests (`Test-NovaBuild`)
3. Bump version (`Update-NovaModuleVersion`)
4. Build again to include the updated version
5. Publish via `Publish-NovaBuiltModule`

The command changes location to `-Path` for execution and always restores the previous location.

## EXAMPLES

### EXAMPLE 1

```powershell
Invoke-NovaRelease -PublishOption @{Local = $true}
```

Runs a local release flow and publishes to the local module path.

### EXAMPLE 2

```powershell
Invoke-NovaRelease -PublishOption @{Repository = 'PSGallery'; ApiKey = $env:PSGALLERY_API}
```

Runs release flow and publishes to the specified repository.

## PARAMETERS

### -PublishOption

Hashtable controlling publish behavior.

Common keys:

- `Local`
- `Repository`
- `ApiKey`
- `ModuleDirectoryPath`

```yaml
Type: System.Collections.Hashtable
DefaultValue: @{ }
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

### -Path

Project root path where the release command should run.

```yaml
Type: System.String
DefaultValue: (Get-Location).Path
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

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`,
`-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`, `-ProgressAction`, `-Verbose`,
`-WarningAction`, and `-WarningVariable`.

## INPUTS

## OUTPUTS

## NOTES

If build or tests fail, version bump and publish are not completed.

## RELATED LINKS

- [Invoke-NovaBuild](Invoke-NovaBuild.md)
- [Test-NovaBuild](Test-NovaBuild.md)
- [Update-NovaModuleVersion](Update-NovaModuleVersion.md)
- [Publish-NovaModule](Publish-NovaModule.md)

