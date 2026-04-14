---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/14/2026
PlatyPS schema version: 2024-05-01
title: Get-NovaProjectInfo
---

# Get-NovaProjectInfo

## SYNOPSIS

Reads `project.json` and returns resolved NovaModuleTools project metadata.

## SYNTAX

### __AllParameterSets

```powershell
Get-NovaProjectInfo [[-Path] <string>] [-Version] [<CommonParameters>]
```

## DESCRIPTION

`Get-NovaProjectInfo` reads the `project.json` file in a NovaModuleTools project and returns a project information
object with:

- the raw project metadata
- normalized project paths such as `src/`, `tests/`, `docs/`, and `dist/`
- defaulted build settings such as `BuildRecursiveFolders`, `SetSourcePath`, and `CopyResourcesToModuleRoot`
- the resolved module output file paths for the generated `.psm1` and `.psd1`

Use this command from scripts, tests, or troubleshooting when you want one object that describes the current project.

When you use `-Version`, the command returns only the project version string instead of the full project object.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> Get-NovaProjectInfo
```

Returns the full project information object for the current directory.

### EXAMPLE 2

```powershell
PS> Get-NovaProjectInfo -Path ./example
```

Returns the full project information object for the project rooted at `./example`.

### EXAMPLE 3

```powershell
PS> Get-NovaProjectInfo -Version
```

Returns only the version string from `project.json`.

## PARAMETERS

### -Path

Project root path that contains `project.json`.

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

### -Version

Return only the project version string instead of the full project information object.

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

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`,
`-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`, `-ProgressAction`, `-Verbose`,
`-WarningAction`, and `-WarningVariable`.

## INPUTS

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### System.String

Returned when you use `-Version`.

### PSCustomObject

Returned by default. The object includes project metadata, defaulted build settings, and resolved paths.

## NOTES

This command throws a clear error when `project.json` is missing or empty.

## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Test-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Update-NovaModuleVersion.md



