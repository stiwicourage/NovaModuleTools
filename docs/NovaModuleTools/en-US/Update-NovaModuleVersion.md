---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: 'https://www.novamoduletools.com/versioning-and-updates.html#bump'
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/25/2026
PlatyPS schema version: 2024-05-01
title: Update-NovaModuleVersion
---

# Update-NovaModuleVersion

## SYNOPSIS

Updates the project version in `project.json` based on git commit history.

## SYNTAX

### __AllParameterSets

```text
PS> Update-NovaModuleVersion [[-Path] <string>] [-Preview] [-ContinuousIntegration] [-OverrideWarning] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Update-NovaModuleVersion` reads the current project version from `project.json`, collects Git commit messages from the project repository, chooses a semantic version bump label, calculates the next semantic version, and writes the updated version back to `project.json`.

Use `-Preview` when you want an explicit prerelease-continuation bump instead of the default prerelease finalization behavior. In preview mode, stable versions always enter the next patch preview track by incrementing the patch version and appending `-preview`. Existing prerelease versions keep the same semantic core and preserve the current prerelease stem while appending or incrementing trailing digits. Any bare prerelease label now starts at `01` for predictable ordering, for example `preview -> preview01`, `preview09 -> preview10`, `rc -> rc01`, `rc1 -> rc2`, and
`SNAPSHOT -> SNAPSHOT01`.

The release label is inferred from the commit set:

- `Major` for breaking changes
- `Minor` for `feat:` commits
- `Patch` for `fix:` commits and all other cases

When the current stable version is still on `0.y.z` and the inferred label is `Major`, Nova keeps the release on the initial-development line and plans the next minor version instead of jumping straight to `1.0.0`. The result still reports the detected `Major` label so you can see that the commit set contained a breaking change, and Nova prints guidance about manually setting `1.0.0` once the software is stable. With `-Preview`, stable versions still enter the next patch preview track instead of applying semantic history inference to the semantic core.

When Git tags exist, only commits since the latest tag are considered. If Git-based inference is unavailable because the project path is not inside a Git repository, the command stops with a clear warning/error instead of silently presenting an inferred-looking patch result. Use `-OverrideWarning` only when you intentionally want that Patch fallback, for example in example/template flows outside Git.

If the repository exists but has no commits yet, the command stops with: `Cannot bump version because the repository
has no commits yet. Create an initial commit first.`

This command supports `-WhatIf` and `-Confirm` through PowerShell `SupportsShouldProcess`. Use `-WhatIf` to preview the calculated release label and the exact next version without changing the stored version.

Use `-ContinuousIntegration` when the same session should first re-activate the built `dist/` module before the version bump workflow starts. This is useful in CI/self-hosting flows where an earlier command changed the active module state.

When the current version is already a prerelease for the selected release line, Nova finalizes that same semantic version instead of incrementing again. For example, a `Major` bump from `2.0.0-preview7` resolves to `2.0.0`, not
`3.0.0-preview7`.

## EXAMPLES

### EXAMPLE 1

```text
PS> Update-NovaModuleVersion
```

Updates the version in the current project using the release label inferred from recent commit messages.

### EXAMPLE 2

```text
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

### EXAMPLE 5

```text
PS> Update-NovaModuleVersion -Preview -WhatIf

What if: Performing the operation "Update module version using Minor release label" on target "project.json".

PreviousVersion: 1.5.3
NewVersion: 1.5.4-preview
Label: Minor
CommitCount: 12
```

Shows how `-Preview` keeps the detected semantic label for reporting but deterministically enters the next patch preview track when the current version is stable.

### EXAMPLE 6

```text
PS> Update-NovaModuleVersion -Preview -WhatIf

What if: Performing the operation "Update module version using Patch release label" on target "project.json".

PreviousVersion: 1.5.3-preview01
NewVersion: 1.5.3-preview02
Label: Patch
CommitCount: 3
```

Shows how `-Preview` stays on the same semantic core and increments the current prerelease label when the current version is already a prerelease.

### EXAMPLE 7

```text
PS> Update-NovaModuleVersion -Preview -WhatIf

What if: Performing the operation "Update module version using Patch release label" on target "project.json".

PreviousVersion: 1.5.3-SNAPSHOT
NewVersion: 1.5.3-SNAPSHOT01
Label: Patch
CommitCount: 3
```

Shows how `-Preview` starts any bare non-preview prerelease stem at `01` instead of jumping directly to `1`.

### EXAMPLE 8

```text
PS> Update-NovaModuleVersion -ContinuousIntegration
```

Re-imports the built `dist/<ProjectName>/<ProjectName>.psd1` first and then runs the normal version bump workflow.

### EXAMPLE 9

```text
PS> Update-NovaModuleVersion -WhatIf

What if: Performing the operation "Update module version using Major release label" on target "project.json".
WARNING: Major version zero (0.y.z) is for initial development, so Nova keeps stable bumps on the 0.y.z line and plans breaking-change bumps as the next minor version instead of 1.0.0. Set 1.0.0 manually once the software is stable; after that, automatic major-version bumps work normally.

PreviousVersion: 0.1.0
NewVersion: 0.2.0
Label: Major
CommitCount: 34
```

Shows how stable `0.y.z` bumps still warn that `1.0.0` must be set manually when the API becomes stable, while breaking-change commits on that line continue to plan the next minor version instead of jumping straight to `1.0.0`.

### EXAMPLE 10

```text
PS> Update-NovaModuleVersion -Path ./src/resources/example -OverrideWarning -WhatIf

WARNING: Cannot infer the version bump label from Git history because no Git repository was found for this project path. Use -OverrideWarning to continue intentionally with a Patch fallback.

What if: Performing the operation "Update module version using Patch release label" on target "project.json".
```

Shows how to opt in explicitly to the Patch fallback when a project lives outside a Git repository and Nova therefore cannot infer the semantic label from commit history.

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

### -Preview

Opt into preview bump mode.

When the current version is stable, Nova increments the patch version and appends `-preview`. When the current version already has any prerelease label, Nova keeps the same semantic core version and increments the current prerelease suffix instead of finalizing or advancing to another release line. Any prerelease stem without a trailing number starts at `01`, while labels that already include a number simply increment that number.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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

### -ContinuousIntegration

Re-import the built module from `dist/` before the version bump workflow starts.

Use this when later steps in the same CI/self-hosting session must stay aligned with the built module state that Nova just produced earlier in the workflow.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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

### -OverrideWarning

Allow the version bump to continue with the explicit Patch fallback when Git-based inference is unavailable.

Use this only when you intentionally want to bump a project outside a Git repository, for example in example/template flows where no commit history exists.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, -WarningVariable, -WhatIf, and -Confirm. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### PSCustomObject

Returns the previous version, new version, selected release label, and commit count.

## NOTES

Run this command from a NovaModuleTools project root or supply `-Path`.

This command updates `project.json`. Rebuild the module afterward if you want the generated manifest and built output to reflect the new version.

`Update-NovaModuleVersion` uses `SupportsShouldProcess`, so `Get-Help Update-NovaModuleVersion -Full` surfaces native
`-WhatIf` and `-Confirm` support.

When `-ContinuousIntegration` is used with a real update, the command re-activates the built `dist/` module first. When combined with `-WhatIf`, Nova still previews the bump without changing the loaded module state.

When Git-based inference is unavailable, `Update-NovaModuleVersion` now requires `-OverrideWarning` before it continues with the intentional Patch fallback.

## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Get-NovaProjectInfo.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaBuild.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Invoke-NovaRelease.md
