---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/18/2026
PlatyPS schema version: 2024-05-01
title: Set-NovaUpdateNotificationPreference
---

# Set-NovaUpdateNotificationPreference

## SYNOPSIS

Enables or disables prerelease self-update eligibility.

## SYNTAX

### Enable

```powershell
PS> Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Disable

```powershell
PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Set-NovaUpdateNotificationPreference` manages the user preference that controls whether
`Update-NovaModuleTool` / `Update-NovaModuleTools` and `nova update` may select prerelease versions of
`NovaModuleTools`.

The same stored preference is also used by `Update-NovaModuleTool` (alias: `Update-NovaModuleTools`) and `nova update`
when they decide whether a prerelease self-update can be selected.

Stable self-updates remain available and do not require prerelease eligibility.

If you prefer the Nova CLI surface, use `nova notification -disable` and `nova notification -enable` for the same
stored preference.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications
```

Turns off prerelease self-update eligibility and restricts `Update-NovaModuleTool` /
`nova update` to stable releases only.

### EXAMPLE 2

```powershell
PS> Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications
```

Turns prerelease self-update eligibility back on, which allows `Update-NovaModuleTool` /
`Update-NovaModuleTools` and `nova update` to consider a prerelease target again.

### EXAMPLE 3

```powershell
nova notification -disable
```

Uses the Nova CLI entrypoint to disable prerelease self-update eligibility.

### EXAMPLE 4

```powershell
nova notification -enable
```

Uses the Nova CLI entrypoint to re-enable prerelease self-update eligibility.

## PARAMETERS

### -EnablePrereleaseNotifications

Enables prerelease self-update eligibility.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: Enable
    Position: Named
    IsRequired: true
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: [ ]
HelpMessage: ''
```

### -DisablePrereleaseNotifications

Disables prerelease self-update eligibility. Stable self-updates still remain available.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: Disable
    Position: Named
    IsRequired: true
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: [ ]
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
  - Name: Enable
    Position: Named
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
  - Name: Disable
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

Prompts for confirmation before the preference is changed.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases:
  - cf
ParameterSets:
  - Name: Enable
    Position: Named
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
  - Name: Disable
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

Returns the current prerelease self-update state, the always-available stable-update state, and the user settings path.

## NOTES

Use this command together with `Get-NovaUpdateNotificationPreference` when you want to confirm the stored setting.

Use `nova notification` when you want to view the same setting through the CLI surface.

## RELATED LINKS

- `Get-NovaUpdateNotificationPreference`
- `Update-NovaModuleTool`
