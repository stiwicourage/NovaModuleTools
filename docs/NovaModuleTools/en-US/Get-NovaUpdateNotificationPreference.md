---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/18/2026
PlatyPS schema version: 2024-05-01
title: Get-NovaUpdateNotificationPreference
---

# Get-NovaUpdateNotificationPreference

## SYNOPSIS

Shows the current build-update notification preference for prerelease checks.

## SYNTAX

### __AllParameterSets

```powershell
PS> Get-NovaUpdateNotificationPreference [<CommonParameters>]
```

## DESCRIPTION

`Get-NovaUpdateNotificationPreference` returns the current user preference that controls whether successful builds also
notify about newer prerelease versions of `NovaModuleTools`.

Stable release notifications always remain enabled and cannot be disabled.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> Get-NovaUpdateNotificationPreference
```

Shows whether prerelease update notifications are currently enabled and where the preference is stored.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`,
`-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`, `-ProgressAction`, `-Verbose`,
`-WarningAction`, and `-WarningVariable`.

## INPUTS

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### PSCustomObject

Returns the prerelease-notification state, the always-on stable-notification state, and the user settings path.

## NOTES

Use `Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications` to stop prerelease notifications.

Use `Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications` to turn prerelease notifications back on.

## RELATED LINKS

- `Invoke-NovaBuild`
- `Set-NovaUpdateNotificationPreference`

