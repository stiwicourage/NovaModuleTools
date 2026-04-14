---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/14/2026
PlatyPS schema version: 2024-05-01
title: Update-NovaModuleVersion
---

# Update-NovaModuleVersion

## SYNOPSIS

Updates the project version in `project.json` based on git commit history.

## SYNTAX

### __AllParameterSets

```powershell
Update-NovaModuleVersion [[-Path] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Update-NovaModuleVersion` reads the current project version from `project.json`, collects Git commit messages from the
project repository, chooses a semantic version bump label, and writes the updated version back to `project.json`.

The release label is inferred from the commit set:

- `Major` for breaking changes
- `Minor` for `feat:` commits
- `Patch` for `fix:` commits and all other cases

When Git tags exist, only commits since the latest tag are considered. If the folder is not a Git repository, the
command falls back to a patch bump.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> Update-NovaModuleVersion
```

Updates the version in the current project using the release label inferred from recent commit messages.

### EXAMPLE 2

```powershell
PS> Update-NovaModuleVersion -Path ./example
```

Updates the version for the project rooted at `./example`.

### EXAMPLE 3

```powershell
PS> Update-NovaModuleVersion -WhatIf
```

Shows the planned version update without modifying `project.json`.

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
AcceptedValues: []
HelpMessage: ''
```

### -Confirm

Prompts for confirmation before `project.json` is updated.

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
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### PSCustomObject

Returns the previous version, new version, selected release label, and commit count.

## NOTES

Run this command from a NovaModuleTools project root or supply `-Path`.

This command updates `project.json`. Rebuild the module afterward if you want the generated manifest and built output to
reflect the new version.


## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Get-NovaProjectInfo.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaRelease.md



