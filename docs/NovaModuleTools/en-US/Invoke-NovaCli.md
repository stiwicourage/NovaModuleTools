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

`Invoke-NovaCli` routes the same top-level command names as the bundled command-line launcher, but it keeps the entry
surface explicit for PowerShell callers.

Use `-Command` to select the routed command and `-Arguments` when a routed command needs additional raw arguments.

When `-Command` is omitted, `Invoke-NovaCli` routes to the root help view.

Direct PowerShell cmdlets such as `Invoke-NovaBuild`, `Publish-NovaModule`, `Deploy-NovaPackage`,
`Update-NovaModuleVersion`, and `Invoke-NovaRelease` keep their native `-WhatIf` and `-Confirm` behavior when called
directly.

## EXAMPLES

### EXAMPLE 1

```text
PS> Invoke-NovaCli -Command build
```

Routes the build workflow through the explicit PowerShell cmdlet entrypoint.

### EXAMPLE 2

```text
PS> Invoke-NovaCli -Command version
```

Routes the version workflow through the explicit PowerShell cmdlet entrypoint.

### EXAMPLE 3

```text
PS> Invoke-NovaCli -Command update -WhatIf
```

Routes the self-update workflow while previewing the outer PowerShell action.

### EXAMPLE 4

```text
PS> Invoke-NovaCli -Command notification
```

Routes the notification-preference status workflow through the explicit PowerShell cmdlet entrypoint.

### EXAMPLE 5

```text
PS> Invoke-NovaCli -Command build -Confirm
```

Prompts before the routed build workflow starts.

## PARAMETERS

### -Command

Top-level Nova command to route. When omitted, the cmdlet routes to the root help view.

```yaml
Type: System.String
DefaultValue: (root help view)
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

Use this parameter when a routed command needs additional command-specific arguments.

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

Install the bundled command-line launcher with `Install-NovaCli` when you want the same routed command surface from
your shell.

`Invoke-NovaCli` uses `SupportsShouldProcess` so the outer PowerShell call still surfaces native `-WhatIf` and
`-Confirm` support.

## RELATED LINKS

- `Install-NovaCli`
- `Invoke-NovaBuild`
- `Initialize-NovaModule`
- `New-NovaModulePackage`
- `Deploy-NovaPackage`
- `Publish-NovaModule`
- `Update-NovaModuleVersion`
