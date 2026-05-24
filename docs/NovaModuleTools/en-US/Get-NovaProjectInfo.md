---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: 'https://www.novamoduletools.com/project-json-reference.html'
Locale: en-US
Module Name: NovaModuleTools
ms.date: 05/06/2026
PlatyPS schema version: 2024-05-01
title: Get-NovaProjectInfo
---

# Get-NovaProjectInfo

## SYNOPSIS

Reads `project.json` and returns resolved NovaModuleTools project metadata or a version-focused view.

## SYNTAX

### ProjectInfo

```text
PS> Get-NovaProjectInfo [[-Path] <string>] [<CommonParameters>]
```

### ProjectVersion

```text
PS> Get-NovaProjectInfo [[-Path] <string>] [-Version] [<CommonParameters>]
```

### InstalledVersion

```text
PS> Get-NovaProjectInfo [-Installed] [<CommonParameters>]
```

## DESCRIPTION

`Get-NovaProjectInfo` reads the `project.json` file in a NovaModuleTools project and returns a project information object with:

- the raw project metadata
- normalized project paths such as `src/`, `tests/`, `docs/`, and `dist/`
- defaulted build settings such as `BuildRecursiveFolders`, `SetSourcePath`, and `CopyResourcesToModuleRoot`
- the resolved module output file paths for the generated `.psm1` and `.psd1`

Use this command from scripts, tests, or troubleshooting when you want one object that describes the current project.

When you use `-Version`, the command returns only the project version string instead of the full project object.

When you use `-Installed`, the command returns the installed `NovaModuleTools` module name and version string instead of project metadata.

When `-Path` does not resolve to an existing project root folder, or the folder does not contain `project.json`,
the command fails with an actionable error that tells you how to recover.

## EXAMPLES

### EXAMPLE 1

```text
PS> Get-NovaProjectInfo
```

Returns the full project information object for the current directory.

### EXAMPLE 2

```text
PS> Get-NovaProjectInfo -Path ./src/resources/example
```

Returns the full project information object for the packaged example project rooted at `./src/resources/example`.

### EXAMPLE 3

```text
PS> Get-NovaProjectInfo -Version
```

Returns only the version string from `project.json`.

### EXAMPLE 4

```text
PS> Get-NovaProjectInfo -Installed
```

Returns the installed `NovaModuleTools` module name and version string.

## PARAMETERS

### -Path

Project root path that contains `project.json`.

```yaml
Type: System.String
DefaultValue: (Get-Location).Path
SupportsWildcards: false
Aliases: []
ParameterSets:
  - Name: ProjectInfo
    Position: 0
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
  - Name: ProjectVersion
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
  - Name: ProjectVersion
    Position: Named
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Installed

Return the installed `NovaModuleTools` module name and version string instead of project metadata.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
  - Name: InstalledVersion
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

### System.String

Returned when you use `-Installed`.

### PSCustomObject

Returned by default. The object includes project metadata, defaulted build settings, and resolved paths.

## NOTES

This command throws a clear error when `project.json` is missing or empty.

If `-Path` points to a file or a folder that does not exist, `Get-NovaProjectInfo` tells you to rerun it from a
Nova project root or pass `-Path` to the folder that contains `project.json`.

`-Installed` does not require a project path or a `project.json` file.

## RELATED LINKS

- [Invoke-NovaBuild](./Invoke-NovaBuild.md)
- [Test-NovaBuild](./Test-NovaBuild.md)
- [Update-NovaModuleVersion](./Update-NovaModuleVersion.md)
