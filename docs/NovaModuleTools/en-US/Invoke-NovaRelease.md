---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/14/2026
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
PS> Invoke-NovaRelease -PublishOption @{ Local = $true }
```

Runs a local release flow and publishes to the local module path.

### EXAMPLE 2

```powershell
PS> Invoke-NovaRelease -PublishOption @{ Repository = 'PSGallery'; ApiKey = $env:PSGALLERY_API }
```

Runs release flow and publishes to the specified repository.

### EXAMPLE 3

```powershell
PS> Invoke-NovaRelease -Path ./example -PublishOption @{ Local = $true }
```

Runs the release workflow from the project rooted at `./example`.

## PARAMETERS

### -PublishOption

Hashtable controlling publish behavior.

Common keys:

- `Local`
- `Repository`
- `ApiKey`
- `ModuleDirectoryPath`

Use `Local = $true` for local publishing, or provide `Repository` and `ApiKey` for repository publishing.

```yaml
Type: System.Collections.Hashtable
DefaultValue: '@{}'
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

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### PSCustomObject

Returns the version update result from `Update-NovaModuleVersion`, including the previous version, new version,
selected release label, and commit count.

## NOTES

If build or tests fail, version bump and publish are not completed.

## RELATED LINKS

- `Invoke-NovaBuild`
- `Test-NovaBuild`
- `Update-NovaModuleVersion`
- `Publish-NovaModule`

