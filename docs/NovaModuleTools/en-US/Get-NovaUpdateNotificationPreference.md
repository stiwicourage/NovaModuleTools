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

If you prefer the Nova CLI surface, run `nova notification` to view the same preference.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> Get-NovaUpdateNotificationPreference
```

Shows whether prerelease update notifications are currently enabled and where the preference is stored.

### EXAMPLE 2

```powershell
nova notification
```

Shows the same prerelease notification state from the Nova CLI entrypoint.

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

Use `PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications` or `nova notification -disable` to stop
prerelease notifications.

Use `PS> Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications` or `nova notification -enable` to turn
prerelease notifications back on.

## RELATED LINKS

- `Invoke-NovaBuild`
- `Set-NovaUpdateNotificationPreference`

