---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/18/2026
PlatyPS schema version: 2024-05-01
title: Update-NovaModuleTool
---

# Update-NovaModuleTool

## SYNOPSIS

Updates the installed `NovaModuleTools` module using the shared prerelease preference.

## SYNTAX

### __AllParameterSets

```powershell
PS> Update-NovaModuleTool [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Update-NovaModuleTool` self-updates the installed `NovaModuleTools` module.

The cmdlet is also available through the compatibility alias `Update-NovaModuleTools`.

Before it runs `Update-Module`, it resolves the best available update candidate by using the same stored prerelease
preference that controls the automatic post-build update notifications.

When prerelease notifications are disabled, `Update-NovaModuleTool` only considers stable releases and never passes
`-AllowPrerelease` to the update flow.

When prerelease notifications are enabled, `Update-NovaModuleTool` may target a prerelease. If the selected target is a
prerelease, the command always asks for explicit confirmation before it proceeds.

Stable updates do not require prerelease confirmation.

Use `nova update` when you want the same behavior through the Nova CLI entrypoint.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> Update-NovaModuleTool
```

Updates the installed `NovaModuleTools` module by using the stored prerelease preference to resolve the update
candidate.

### EXAMPLE 2

```powershell
PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications
PS> Update-NovaModuleTool
```

Restricts self-update to stable releases only.

### EXAMPLE 3

```powershell
nova update
```

Runs the same self-update flow from the Nova CLI. If the selected target is a prerelease, the CLI asks for explicit
confirmation before running the update.

### EXAMPLE 4

```powershell
PS> Update-NovaModuleTool -WhatIf
```

Previews the resolved update action without running `Update-Module`.

## PARAMETERS

### -WhatIf

Shows what would happen if the cmdlet runs. `Update-NovaModuleTool` resolves the target version first, then previews the
selected stable or prerelease update action without changing the installed module.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: [ wi ]
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

Prompts you for confirmation before the cmdlet runs.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: [ cf ]
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

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`,
`-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`, `-ProgressAction`, `-Verbose`,
`-WarningAction`, `-WarningVariable`, `-WhatIf`, and `-Confirm`.

## INPUTS

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### PSCustomObject

Returns a self-update plan/result object that shows the current version, the resolved target version, whether a newer
update was available, whether the target was prerelease, and whether the update ran or was cancelled.

## NOTES

If the PowerShell Gallery cannot be reached well enough to resolve an update candidate, the command stops before calling
`Update-Module`.

Use `Get-NovaUpdateNotificationPreference`, `Set-NovaUpdateNotificationPreference`, `nova notification`,
`nova notification -disable`, and `nova notification -enable` to inspect or change the same stored prerelease setting.

## RELATED LINKS

- `Invoke-NovaCli`
- `Get-NovaUpdateNotificationPreference`
- `Set-NovaUpdateNotificationPreference`
- `Invoke-NovaBuild`
