---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/14/2026
PlatyPS schema version: 2024-05-01
title: Publish-NovaModule
---

# Publish-NovaModule

## SYNOPSIS

Builds, tests, and publishes the current project either locally or to a PowerShell repository.

## SYNTAX

### Local

```powershell
PS> Publish-NovaModule [-Local] [[-ModuleDirectoryPath] <string>] [[-ApiKey] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Repository

```powershell
PS> Publish-NovaModule [-Repository] <string> [[-ModuleDirectoryPath] <string>] [[-ApiKey] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Publish-NovaModule` runs the normal NovaModuleTools build and test flow, then publishes the built module.

Use local mode when you want to copy the built module into a module directory on the current machine.

Use repository mode when you want to publish the built module to a registered PowerShell repository such as
`PSGallery`.

This command supports `-WhatIf` and `-Confirm` through PowerShell `SupportsShouldProcess`. Use `-WhatIf` to preview the
build, test, and publish workflow without changing `dist/`, writing test artifacts, copying module files, or calling the
target repository.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> Publish-NovaModule -Local
```

Builds, tests, and copies the module to the default local module path.

### EXAMPLE 2

```powershell
PS> Publish-NovaModule -Local -ModuleDirectoryPath ~/Modules
```

Builds, tests, and copies the module to a custom local directory.

### EXAMPLE 3

```powershell
PS> Publish-NovaModule -Repository PSGallery -ApiKey $env:PSGALLERY_API
```

Builds, tests, and publishes the module to `PSGallery`.

### EXAMPLE 4

```powershell
PS> Publish-NovaModule -Repository PSGallery -ApiKey $env:PSGALLERY_API -WhatIf
```

Previews the build, test, and repository publish workflow without making changes.

### EXAMPLE 5

```bash
nova publish -repository PSGallery -apikey $PSGALLERY_API
```

Runs the same publish flow through the `nova` CLI.

## PARAMETERS

### -Local

Use local publish mode. When no repository is supplied, the command publishes to a local module directory.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Local
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Repository

Target repository name for repository publishing, for example `PSGallery`.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Repository
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ModuleDirectoryPath

Custom destination directory for local publishing.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Local
  Position: Named
- Name: Repository
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ApiKey

Repository API key used when publishing to a repository. This value is ignored for normal local publishing.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Local
  Position: Named
- Name: Repository
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
-ProgressAction, -Verbose, -WarningAction, -WarningVariable, -WhatIf, and -Confirm. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### None

This cmdlet does not emit an output object.

## NOTES

The command always builds and tests before publishing.

`Publish-NovaModule` uses `SupportsShouldProcess`, so `Get-Help Publish-NovaModule -Full` surfaces native `-WhatIf` and
`-Confirm` support.

## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Test-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaRelease.md



