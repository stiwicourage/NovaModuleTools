---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/25/2026
PlatyPS schema version: 2024-05-01
title: Get-NovaUpdateNotificationPreference
---

# Get-NovaUpdateNotificationPreference

## SYNOPSIS

Shows the current prerelease update preference used by Nova self-update commands.

## SYNTAX

### __AllParameterSets

```text
PS> Get-NovaUpdateNotificationPreference [<CommonParameters>]
```

## DESCRIPTION

`Get-NovaUpdateNotificationPreference` returns the current user preference that controls whether
`Update-NovaModuleTool` / `Update-NovaModuleTools` may select prerelease versions of `NovaModuleTools`.

The same stored preference is also used by `Update-NovaModuleTool` (alias: `Update-NovaModuleTools`) when it decides
whether a prerelease self-update is eligible.

Stable self-updates remain available and do not require prerelease eligibility.

## EXAMPLES

### EXAMPLE 1

```text
PS> Get-NovaUpdateNotificationPreference
```

Shows whether prerelease self-updates are currently enabled, whether stable self-updates remain available, and where the
preference is stored.

### EXAMPLE 2

```text
PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications
PS> Get-NovaUpdateNotificationPreference
```

Shows the stored preference after prerelease self-updates have been disabled.

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

Returns the prerelease self-update state, the always-available stable-update state, and the user settings path.

## NOTES

Use `Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications` to stop prerelease self-updates from being
eligible.

Use `Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications` to allow prerelease self-updates again.

When prerelease notifications are enabled again, `Update-NovaModuleTool` / `Update-NovaModuleTools` may again select a
prerelease target. Prerelease self-updates still require explicit confirmation before the update proceeds.

## RELATED LINKS

- `Invoke-NovaBuild`
- `Set-NovaUpdateNotificationPreference`
- `Update-NovaModuleTool`
