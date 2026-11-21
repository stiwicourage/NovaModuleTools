---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: 'https://www.novamoduletools.com/versioning-and-updates.html#self-update'
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/25/2026
PlatyPS schema version: 2024-05-01
title: Update-NovaModuleTool
---

# Update-NovaModuleTool

## SYNOPSIS

Updates the installed `NovaModuleTools` module using the shared prerelease preference.

## SYNTAX

### __AllParameterSets

```text
PS> Update-NovaModuleTool [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Update-NovaModuleTool` self-updates the installed `NovaModuleTools` module.

The cmdlet is also available through the compatibility alias `Update-NovaModuleTools`.

`Update-NovaModuleTool` uses the `PSModuleUpdate` module to resolve and install the update. `PSModuleUpdate` stages and verifies the new version with `Microsoft.PowerShell.PSResourceGet` before it activates it. Before it installs anything, it resolves the best available update candidate by using the stored prerelease preference exposed through `Get-NovaUpdateNotificationPreference`, `Set-NovaUpdateNotificationPreference`, and those PowerShell preference commands.

`PSModuleUpdate` is loaded only when you run the self-update command. If `PSModuleUpdate` 0.3.0 or later is not installed, `Update-NovaModuleTool` installs it from PowerShell Gallery for the current user first. Build and init update notifications do not need `PSModuleUpdate`.

The update keeps the scope of the installed module. When `NovaModuleTools` is installed for all users, run the command from an elevated PowerShell session.

When prerelease notifications are disabled, `Update-NovaModuleTool` only considers stable releases and never passes
`-AllowPrerelease` to the update flow.

When prerelease notifications are enabled, `Update-NovaModuleTool` may target a prerelease. If the selected target is a prerelease, the command always asks for explicit confirmation before it proceeds, and that prerelease confirmation defaults to `No` so pressing Enter cancels the update.

Stable updates do not require prerelease confirmation.

When a newer version is available, `Update-NovaModuleTool` shows progress while it installs the update and reads the release-notes link from the updated module. Every command path ends with a visible summary: up-to-date, preview, cancelled, or updated.

After a successful update, `Update-NovaModuleTool` prints the release notes link from the installed module manifest and suggests `Get-NovaProjectInfo -InstalledNovaVersion` as the next verification step.

## EXAMPLES

### EXAMPLE 1

```text
PS> Update-NovaModuleTool
```

Updates the installed `NovaModuleTools` module by using the stored prerelease preference to resolve the update candidate, then prints the current version, target version, and the next suggested verification step.

### EXAMPLE 2

```text
PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications
PS> Update-NovaModuleTool
```

Restricts self-update to stable releases only.

### EXAMPLE 3

```text
PS> Get-NovaUpdateNotificationPreference
PS> Update-NovaModuleTool
```

Reads the current prerelease preference and then runs the self-update flow from PowerShell.

Successful updates print the release notes link from the installed module manifest.

### EXAMPLE 4

```text
PS> Update-NovaModuleTool -WhatIf
```

Previews the resolved update action without prompting for prerelease confirmation or installing the update. `-WhatIf` does not install `PSModuleUpdate`; if it is missing, the command stops with install guidance.

## PARAMETERS

### -WhatIf

Shows what would happen if the cmdlet runs. `Update-NovaModuleTool` resolves the target version first, then previews the selected stable or prerelease update action without prompting for prerelease confirmation or changing the installed module.

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

Returns a self-update plan/result object that shows the current version, the resolved target version, whether a newer update was available, whether the target was prerelease, and whether the update ran or was cancelled.

## NOTES

If the PowerShell Gallery cannot be reached well enough to resolve an update candidate, the command stops before it
installs anything.

If `PSModuleUpdate` cannot be installed automatically, run
`Install-PSResource -Name PSModuleUpdate -Scope CurrentUser -Repository PSGallery` and rerun the command.

If the newer version is already installed but not loaded, the command tells you to restart PowerShell instead of
installing it again.

Use `Get-NovaUpdateNotificationPreference` and `Set-NovaUpdateNotificationPreference` to inspect or change the stored prerelease setting.

Use `Ctrl+C` if you need to stop an active self-update before the install finishes.

## RELATED LINKS

- [Get-NovaUpdateNotificationPreference](./Get-NovaUpdateNotificationPreference.md)
- [Set-NovaUpdateNotificationPreference](./Set-NovaUpdateNotificationPreference.md)
- [Get-NovaProjectInfo](./Get-NovaProjectInfo.md)
- [Invoke-NovaBuild](./Invoke-NovaBuild.md)
