---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/19/2026
PlatyPS schema version: 2024-05-01
title: Pack-NovaModule
---

# Pack-NovaModule

## SYNOPSIS

Builds, tests, and packages the current project as a `.nupkg` artifact.

## SYNTAX

### __AllParameterSets

```powershell
PS> Pack-NovaModule [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Pack-NovaModule` runs the normal NovaModuleTools build and test flow, then packages the built module output from
`dist/<ProjectName>/` into a NuGet-compatible `.nupkg` artifact.

The package is written to `artifacts/packages/` by default. You can override generic package metadata through the
optional `Package` section in `project.json`.

This command is intended for NovaModuleTools user projects that need a deployable package artifact without publishing to
PowerShell Gallery.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> Pack-NovaModule
```

Builds the project, runs `Test-NovaBuild`, and writes a `.nupkg` to `artifacts/packages/`.

### EXAMPLE 2

```powershell
PS> nova pack
```

Runs the same packaging workflow through the `nova` CLI.

### EXAMPLE 3

```powershell
PS> Pack-NovaModule -WhatIf
```

Previews the build, test, and package workflow without writing a package artifact.

### EXAMPLE 4

```powershell
PS> Pack-NovaModule -Confirm
```

Prompts before the package artifact is created.

## PARAMETERS

### -WhatIf

Shows what would happen if the cmdlet runs. The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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
AcceptedValues: [ ]
HelpMessage: ''
```

### -Confirm

Prompts for confirmation before the package artifact is created.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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
AcceptedValues: [ ]
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

### System.Management.Automation.PSCustomObject

Returns package metadata that includes the generated package path, output directory, and source module directory.

## NOTES

Package metadata reuses values from `project.json` when possible, including:

- `ProjectName`
- `Description`
- `Version`
- `Manifest.Author`
- `Manifest.Tags`
- `Manifest.ProjectUri`
- `Manifest.ReleaseNotes`
- `Manifest.LicenseUri`

Use the top-level `Package` section only for generic packaging overrides such as output directory or package file name.

## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Test-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaCli.md
