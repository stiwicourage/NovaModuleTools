---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 05/24/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaCli
---

# Invoke-NovaCli

## SYNOPSIS

Runs Nova's launcher-style command routing from PowerShell.

## SYNTAX

### __AllParameterSets

```text
PS> Invoke-NovaCli [[-Command] <string>] [[-Arguments] <string[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Invoke-NovaCli` is the PowerShell entrypoint behind the launcher-style `nova <command>` workflow.

Use this cmdlet when you want Nova's routed CLI experience from inside PowerShell, including root help, per-command help, and the routed command surfaces such as `build`, `test`, `package`, `publish`, `release`, `update`, and `notification`.

When `-Command` is omitted or blank, Nova falls back to the root CLI help.

This cmdlet forwards `-WhatIf` and `-Confirm` semantics to the routed command surface instead of treating `Invoke-NovaCli` itself as the mutating operation owner.

Use `Get-Help Invoke-NovaCli -Full` when you want the PowerShell wrapper help. Use `nova --help`, `nova <command> --help`, or `nova --help <command>` when you want launcher-native CLI help.

## EXAMPLES

### EXAMPLE 1

```text
PS> Invoke-NovaCli
```

Shows the root Nova CLI help.

### EXAMPLE 2

```text
PS> Invoke-NovaCli build --help
```

Shows the short help for the routed `build` command by using launcher-style arguments from PowerShell.

### EXAMPLE 3

```text
PS> Invoke-NovaCli --help build
```

Shows the long help for the routed `build` command.

### EXAMPLE 4

```text
PS> Invoke-NovaCli publish --repository PSGallery --api-key <key> -WhatIf
```

Previews the routed publish workflow without changing files or publishing artifacts.

## PARAMETERS

### -Arguments

Pass the remaining launcher-style arguments for the routed command.

Use CLI syntax here, for example `--help`, `--verbose`, `--what-if`, or route-specific flags such as `--repository`.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
  - Name: (All)
    Position: 1
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: true
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Command

Choose the routed Nova command to run, for example `build`, `test`, `package`, `publish`, `release`, `notification`, `update`, or the root help/version forms such as `--help` and `--version`.

When this parameter is omitted or blank, Nova shows the root CLI help.

```yaml
Type: System.String
DefaultValue: ''
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

### -Confirm

Forward confirmation behavior to routed mutating commands that support Nova's CLI confirmation flow.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
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

### -WhatIf

Forward preview behavior to routed commands that support Nova's non-destructive preview flow.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### System.Object

This cmdlet returns the routed command result or CLI help text for help and version requests.

## NOTES

`Invoke-NovaCli` is a PowerShell wrapper around Nova's launcher-style command routing. The routed command surfaces keep CLI syntax such as `--help`, `--verbose`, and `--what-if`.

Use `Ctrl+C` if you need to cancel a running routed workflow.

## RELATED LINKS

- [Invoke-NovaBuild](./Invoke-NovaBuild.md)
- [Test-NovaBuild](./Test-NovaBuild.md)
- [Install-NovaCli](./Install-NovaCli.md)
- [NovaModuleTools Module](./NovaModuleTools.md)
