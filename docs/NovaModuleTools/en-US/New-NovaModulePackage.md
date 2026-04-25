---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/25/2026
PlatyPS schema version: 2024-05-01
title: New-NovaModulePackage
---

# New-NovaModulePackage

## SYNOPSIS

Builds, tests, and packages the current project as one or more configured package artifacts.

## SYNTAX

### __AllParameterSets

```text
PS> New-NovaModulePackage [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`New-NovaModulePackage` runs the normal NovaModuleTools build and test flow, then packages the built module output from
`dist/<ProjectName>/` into the package formats requested by `Package.Types`.

The package is written to `artifacts/packages/` by default. You can override generic package metadata through the
optional `Package` section in `project.json`.

Use this `project.json` shape when you want to control package types and the package output directory:

```json
{
  "Package": {
    "PackageFileName": "AgentInstaller",
    "AddVersionToFileName": true,
    "Types": [
      "NuGet",
      "Zip"
    ],
    "Latest": true,
    "OutputDirectory": {
      "Path": "artifacts/packages",
      "Clean": true
    }
  }
}
```

`Package.Types` is optional. When it is missing, empty, or null, `New-NovaModulePackage` defaults to `NuGet` and creates
a `.nupkg` file.

Supported `Package.Types` values are `NuGet`, `Zip`, `.nupkg`, and `.zip`, and matching is case-insensitive.

`Package.Latest` is optional and defaults to `false`. When set to `true`, `New-NovaModulePackage` also writes a
companion `*.latest.*` artifact for each selected package type while keeping the normal versioned file.

`Package.PackageFileName` lets you override the base package file name.

`Package.AddVersionToFileName` defaults to `false`. When you set it to `true`, Nova appends `.<Version>` from
`project.json` to the configured `Package.PackageFileName` before the package extension is applied.

When both `Package.AddVersionToFileName` and `Package.Latest` are enabled, `New-NovaModulePackage` replaces that
appended version suffix with `.latest` for the companion artifact.

`Package.OutputDirectory.Clean` defaults to `true`, which deletes the configured package output directory before a new
package is created. Set it to `false` when you want to keep existing files in that directory.

This command is intended for NovaModuleTools user projects that need a deployable package artifact without publishing to
PowerShell Gallery.

## EXAMPLES

### EXAMPLE 1

```text
PS> New-NovaModulePackage
```

Builds the project, runs `Test-NovaBuild`, cleans `artifacts/packages/` by default, and writes a new `.nupkg` there
when `Package.Types` is omitted or resolves to `NuGet`.

### EXAMPLE 2

```text
% nova package
```

Runs the same packaging workflow through the `nova` CLI.

### EXAMPLE 3

```text
PS> New-NovaModulePackage
```

When `Package.Types` is `@('NuGet', 'Zip')`, the command writes both `*.nupkg` and `*.zip` artifacts to the configured
package output directory.

### EXAMPLE 4

```text
PS> New-NovaModulePackage
```

When `Package.Latest` is `true`, the command keeps the normal versioned package file and also writes a companion latest
file such as `NovaModuleTools.latest.nupkg`.

### EXAMPLE 5

```text
PS> New-NovaModulePackage
```

When `Package.PackageFileName` is `AgentInstaller` and `Package.AddVersionToFileName` is `true`, the command writes
package files such as `AgentInstaller.2.3.4.nupkg` and `AgentInstaller.latest.nupkg`.

### EXAMPLE 6

```text
PS> New-NovaModulePackage -WhatIf
```

Previews the build, test, and package workflow without writing a package artifact.

### EXAMPLE 7

```text
PS> New-NovaModulePackage -Confirm
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

Returns one artifact metadata object per generated package, including the package type, generated package path, output
directory, and source module directory.

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

`Manifest.Tags`, `Manifest.ProjectUri`, `Manifest.ReleaseNotes`, and `Manifest.LicenseUri` are optional. When they are
missing, `New-NovaModulePackage` omits the matching package metadata fields instead of treating them as required.

Use the top-level `Package` section only for generic packaging overrides such as package type selection, output
directory, or package file name. `New-NovaModulePackage` always allows packaging when you invoke it; there is no
separate
`Package.Enabled` switch.

## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Test-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaCli.md
