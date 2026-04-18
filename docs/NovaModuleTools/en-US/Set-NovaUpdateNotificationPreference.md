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

Enables or disables prerelease build-update notifications.

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

`Set-NovaUpdateNotificationPreference` manages the user preference that controls whether successful builds warn about
newer prerelease versions of `NovaModuleTools`.

Stable release notifications always remain enabled and cannot be disabled.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications
```

Turns off prerelease update notifications for future successful builds.

### EXAMPLE 2

```powershell
PS> Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications
```

Turns prerelease update notifications back on.

## PARAMETERS

### -EnablePrereleaseNotifications

Enables prerelease update notifications after successful builds.

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

Disables prerelease update notifications after successful builds. Stable release notifications still remain enabled.

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

Returns the current prerelease-notification state, the always-on stable-notification state, and the user settings path.

## NOTES

Use this command together with `Get-NovaUpdateNotificationPreference` when you want to confirm the stored setting.

## RELATED LINKS

- `Get-NovaUpdateNotificationPreference`
- `Invoke-NovaBuild`

