---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
  ms.date: 05/03/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaRelease
---

# Invoke-NovaRelease

## SYNOPSIS

Runs the Nova release pipeline (build, test, version bump, rebuild, publish).

## SYNTAX

### Local

```text
PS> Invoke-NovaRelease [-Local] [[-ModuleDirectoryPath] <string>] [[-ApiKey] <string>] [-SkipTests] [-ContinuousIntegration] [-OverrideWarning] [[-Path] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Repository

```text
PS> Invoke-NovaRelease -Repository <string> [[-ModuleDirectoryPath] <string>] [[-ApiKey] <string>] [-SkipTests] [-ContinuousIntegration] [-OverrideWarning] [[-Path] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Invoke-NovaRelease` orchestrates a full release flow:

1. Build module (`Invoke-NovaBuild`)
2. Run tests (`Test-NovaBuild`)
3. Bump version (`Update-NovaModuleVersion`)
4. Build again to include the updated version
5. Publish through the resolved local-directory or repository publish action

Use `-Repository` and `-ApiKey` for repository publishing, or `-Local` / `-ModuleDirectoryPath` for local release
publishing. This keeps the release command aligned with the direct PowerShell parameter style used by
`Publish-NovaModule`.

Use `-SkipTests` when tests already ran earlier in your pipeline and you only want to skip the pre-release
`Test-NovaBuild` step. Both build steps still run.

The command changes location to `-Path` for execution and always restores the previous location.

Use `-ContinuousIntegration` when the same CI/self-hosting session should re-activate the built `dist/` module at the
release workflow boundaries where session state matters. Nova forwards that CI intent into the nested build and version
bump steps and restores the built module again after publish.

Use `-OverrideWarning` only when you intentionally want the nested release builds to continue even though a file under
`src/public` contains zero or multiple top-level functions.

When local release mode is selected, the resolved local publish target is previewed consistently with
`Publish-NovaModule -Local`. Unlike `Publish-NovaModule -Local`, `Invoke-NovaRelease` does not import the published
module into the current session after publishing; it returns the version result for automation-friendly release flows.

This command supports `-WhatIf` and `-Confirm` through PowerShell `SupportsShouldProcess`. Use `-WhatIf` to preview the
entire release workflow and resolved publish target without building, testing, versioning, or publishing.

## EXAMPLES

### EXAMPLE 1

```text
PS> Invoke-NovaRelease -Local
```

Runs a local release flow and publishes to the local module path.
The command returns the version result and does not reload the published module into the current session.

### EXAMPLE 2

```text
PS> Invoke-NovaRelease -Repository PSGallery -ApiKey $env:PSGALLERY_API
```

Runs release flow and publishes to the specified repository.

### EXAMPLE 3

```text
PS> Invoke-NovaRelease -Path ./src/resources/example -Local
```

Runs the release workflow from the project rooted at `./src/resources/example`.

### EXAMPLE 4

```text
PS> Invoke-NovaRelease -Repository PSGallery -ApiKey $env:PSGALLERY_API -WhatIf
```

Previews the release workflow and repository target without making changes.

### EXAMPLE 5

```text
PS> Invoke-NovaRelease -Repository PSGallery -ApiKey $env:PSGALLERY_API -SkipTests
```

Runs the release workflow without re-running the pre-release `Test-NovaBuild` step.

### EXAMPLE 6

```text
PS> Invoke-NovaRelease -Repository PSGallery -ApiKey $env:PSGALLERY_API -ContinuousIntegration
```

Runs the release workflow and re-activates the built `dist/<ProjectName>/<ProjectName>.psd1` at the CI-sensitive
workflow boundaries so later commands in the same session keep using the built module state.

## PARAMETERS

### -Local

Use the local release target. When `-ModuleDirectoryPath` is omitted, Nova resolves the normal local module install
path for the current platform.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: Local
    Position: Named
    IsRequired: true
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: [ ]
HelpMessage: ''
```

### -Repository

Publish the release output to a PowerShell repository such as `PSGallery`.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: Repository
    Position: Named
    IsRequired: true
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: [ ]
HelpMessage: ''
```

### -ModuleDirectoryPath

Local directory where the built module should be copied when the release publishes to a filesystem target.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: Local
    Position: Named
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
  - Name: Repository
    Position: Named
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: [ ]
HelpMessage: ''
```

### -ApiKey

Explicit repository API key. When `-Repository PSGallery` is used and `-ApiKey` is omitted, Nova still falls back to
`$env:PSGALLERY_API`.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: Local
    Position: Named
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
  - Name: Repository
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

### -SkipTests

Skip the pre-release `Test-NovaBuild` step. `Invoke-NovaBuild` still runs before the version bump and again after the
bump so the published output reflects the updated version.

This option is mainly intended for CI/CD flows where tests already passed earlier in the pipeline.

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

Re-activate the built module from `dist/` at the release workflow boundaries where the active module state matters.

Use this for CI/self-hosting flows that continue in the same session after build, version bump, or publish.

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

Continue the nested release builds even if the `src/public` layout guard reports that a public file does not contain
exactly one top-level function.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: Local
    Position: Named
  - Name: Repository
    Position: Named
DontShow: false
AcceptedValues: [ ]
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`,
`-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`, `-ProgressAction`, `-Verbose`,
`-WarningAction`, `-WarningVariable`, `-WhatIf`, and `-Confirm`.

## INPUTS

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### PSCustomObject

Returns the version update result from `Update-NovaModuleVersion`, including the previous version, new version,
selected release label, and commit count.

## NOTES

If build or tests fail, version bump and publish are not completed.

When `-SkipTests` is used, only the pre-release `Test-NovaBuild` step is skipped. Both build steps still run.

Use `Publish-NovaModule -Local` when you want a successful local publish to reload the published module into the active
PowerShell session.

When `-ContinuousIntegration` is used, the release workflow restores the built `dist/` module after CI-sensitive
boundaries so later steps in the same session keep using the built module state instead of a stale or publish-modified
copy.

`Invoke-NovaRelease` uses `SupportsShouldProcess`, so `Get-Help Invoke-NovaRelease -Full` surfaces native `-WhatIf`
and `-Confirm` support.

## RELATED LINKS

- `Invoke-NovaBuild`
- `Test-NovaBuild`
- `Update-NovaModuleVersion`
- `Publish-NovaModule`
