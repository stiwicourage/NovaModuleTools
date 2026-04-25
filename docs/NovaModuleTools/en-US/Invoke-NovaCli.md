---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/25/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaCli
---

# Invoke-NovaCli

## SYNOPSIS

Routes Nova commands through the explicit PowerShell cmdlet entrypoint.

## SYNTAX

### __AllParameterSets

```text
PS> Invoke-NovaCli [[-Command] <string>] [[-Arguments] <string[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Invoke-NovaCli` is the explicit PowerShell cmdlet entrypoint for routed Nova command dispatch.

Use it when you need scripted routing inside PowerShell, for example in tests, automation, or wrapper functions.

Use the installed `nova` launcher when you want the end-user CLI experience. The module does not export `nova` as a
PowerShell alias.

`Invoke-NovaCli` routes the same top-level commands that the launcher supports, including `% nova info`, `% nova
version`, `% nova --version`, `% nova --help`, `% nova build`, `% nova test`, `% nova package`, `% nova deploy`, `% nova
init`, `% nova bump`, `% nova update`, `% nova notification`, `% nova publish`, and `% nova release`.

Mutating routed commands forward CLI `--verbose`/`-v` and `--whatif`/`-w` to the underlying cmdlet. Routed CLI
`--confirm`/`-c` is handled by the shared CLI confirmation flow so the launcher never exposes PowerShell's interactive
`Suspend` prompt.

Direct PowerShell cmdlets such as `Invoke-NovaBuild`, `Publish-NovaModule`, `Deploy-NovaPackage`,
`Update-NovaModuleVersion`, and `Invoke-NovaRelease` keep their native `-WhatIf` and `-Confirm` behavior when called
directly.

Use `% nova <command> --help` or `% nova <command> -h` when you want the routed help for a specific command.

## EXAMPLES

### EXAMPLE 1

```text
PS> Invoke-NovaCli -Command build
```

Routes the build workflow through the explicit PowerShell cmdlet entrypoint.

### EXAMPLE 2

```text
PS> Invoke-NovaCli -Command publish -Arguments @('--local') -WhatIf
```

Routes the local publish workflow while keeping native PowerShell `-WhatIf` on the outer call.

### EXAMPLE 3

```text
PS> Invoke-NovaCli -Command init -Arguments @('--example', '--path', '~/Work')
```

Starts the example scaffold flow from the explicit PowerShell cmdlet entrypoint.

### EXAMPLE 4

```text
% nova build --confirm
```

Runs the routed build workflow through the launcher-facing CLI surface and uses the shared CLI confirmation flow.

### EXAMPLE 5

```text
% nova version --installed
```

Returns the locally installed version of the current project/module.

### EXAMPLE 6

```text
% nova --version
```

Returns the installed `NovaModuleTools` module version.

### EXAMPLE 7

```text
% nova update
```

Runs the self-update flow through the launcher-oriented CLI surface.

### EXAMPLE 8

```text
% nova notification --disable
```

Disables prerelease self-update eligibility through the launcher-facing CLI surface.

## PARAMETERS

### -Command

Top-level Nova command to route. Defaults to `--help`.

```yaml
Type: System.String
DefaultValue: --help
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: (All)
    Position: 0
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: [ ]
HelpMessage: ''
```

### -Arguments

Raw routed argument list for the selected Nova command.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: (All)
    Position: 1
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: true
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

### System.Object

Returns the same output that the selected routed Nova command returns.

## NOTES

Use `Invoke-NovaCli` directly when you need the underlying PowerShell command in scripts, tests, or command dispatch
scenarios.

Install the bundled `nova` launcher with `Install-NovaCli` when you want `% nova ...` available from your shell.

`Invoke-NovaCli` uses `SupportsShouldProcess` so the outer PowerShell call still surfaces native `-WhatIf` and
`-Confirm`, while routed CLI `--confirm`/`-c` stays inside the shared CLI confirmation flow.

## RELATED LINKS

- `Install-NovaCli`
- `Invoke-NovaBuild`
- `Initialize-NovaModule`
- `New-NovaModulePackage`
- `Deploy-NovaPackage`
- `Publish-NovaModule`
- `Update-NovaModuleVersion`
