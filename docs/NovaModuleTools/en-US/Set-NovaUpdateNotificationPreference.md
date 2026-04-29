---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/25/2026
PlatyPS schema version: 2024-05-01
title: Set-NovaUpdateNotificationPreference
---

# Set-NovaUpdateNotificationPreference

## SYNOPSIS

Enables or disables prerelease self-update eligibility.

## SYNTAX

### Enable

```text
PS> Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Disable

```text
PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Set-NovaUpdateNotificationPreference` manages the user preference that controls whether
`Update-NovaModuleTool` / `Update-NovaModuleTools` may select prerelease versions of `NovaModuleTools`.

The same stored preference is also used by `Update-NovaModuleTool` (alias: `Update-NovaModuleTools`) when it decides
whether a prerelease self-update can be selected.

Stable self-updates remain available and do not require prerelease eligibility.

## EXAMPLES

### EXAMPLE 1

```text
PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications
```

Turns off prerelease self-update eligibility and restricts `Update-NovaModuleTool` to stable releases only.

### EXAMPLE 2

```text
PS> Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications
```

Turns prerelease self-update eligibility back on, which allows `Update-NovaModuleTool` /
`Update-NovaModuleTools` to consider a prerelease target again.

### EXAMPLE 3

```text
PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications -WhatIf
```

Previews the change that would disable prerelease self-update eligibility.

### EXAMPLE 4

```text
PS> Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications -Confirm
```

Prompts before the preference is changed to allow prerelease self-updates again.

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


## RELATED LINKS

- `Get-NovaUpdateNotificationPreference`
- `Update-NovaModuleTool`
