---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/15/2026
PlatyPS schema version: 2024-05-01
title: Update-NovaModuleVersion
---

# Update-NovaModuleVersion

## SYNOPSIS

Updates the project version in `project.json` based on git commit history.

## SYNTAX

### __AllParameterSets

```powershell
PS> Update-NovaModuleVersion [[-Path] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Update-NovaModuleVersion` reads the current project version from `project.json`, collects Git commit messages from the
project repository, chooses a semantic version bump label, calculates the next semantic version, and writes the updated
version back to `project.json`.

The release label is inferred from the commit set:

- `Major` for breaking changes
- `Minor` for `feat:` commits
- `Patch` for `fix:` commits and all other cases

When Git tags exist, only commits since the latest tag are considered. If the folder is not a Git repository, the
command falls back to a patch bump.

If the repository exists but has no commits yet, the command stops with: `Cannot bump version because the repository
has no commits yet. Create an initial commit first.`

This command supports `-WhatIf` and `-Confirm` through PowerShell `SupportsShouldProcess`. Use `-WhatIf` to preview the
calculated release label and the exact next version without changing the stored version.

When the current version is already a prerelease for the selected release line, Nova finalizes that same semantic
version instead of incrementing again. For example, a `Major` bump from `2.0.0-preview7` resolves to `2.0.0`, not
`3.0.0-preview7`.

From the standalone `nova` launcher on macOS/Linux, `nova bump -Confirm` uses a CLI-friendly confirmation prompt. If you
choose `No`, `No to All`, or `Suspend`, the command exits without changing `project.json` and without returning a
version
result object.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> Update-NovaModuleVersion
```

Updates the version in the current project using the release label inferred from recent commit messages.

### EXAMPLE 2

```powershell
PS> Update-NovaModuleVersion -Path ./src/resources/example
```

Updates the version for the project rooted at `./src/resources/example`.

### EXAMPLE 3

```text
PS> Update-NovaModuleVersion -WhatIf

What if: Performing the operation "Update module version using Minor release label" on target "project.json".

PreviousVersion: 1.12.0
NewVersion: 1.13.0
Label: Minor
CommitCount: 12
```

Shows the calculated version update without modifying `project.json`.

### EXAMPLE 4

```text
PS> Update-NovaModuleVersion -WhatIf

What if: Performing the operation "Update module version using Major release label" on target "project.json".

PreviousVersion: 2.0.0-preview7
NewVersion: 2.0.0
Label: Major
CommitCount: 84
```

Shows how Nova finalizes an existing prerelease target instead of carrying the old prerelease label into the next major.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, -WarningVariable, -WhatIf, and -Confirm. For more information, see
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

`Update-NovaModuleVersion` uses `SupportsShouldProcess`, so `Get-Help Update-NovaModuleVersion -Full` surfaces native
`-WhatIf` and `-Confirm` support.

## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Get-NovaProjectInfo.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaRelease.md
