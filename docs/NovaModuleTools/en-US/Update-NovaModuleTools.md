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

Before it runs `Update-Module`, it resolves the best available update candidate by using the stored prerelease preference exposed through `Get-NovaUpdateNotificationPreference`, `Set-NovaUpdateNotificationPreference`, and those PowerShell preference commands.

When prerelease notifications are disabled, `Update-NovaModuleTool` only considers stable releases and never passes
`-AllowPrerelease` to the update flow.

When prerelease notifications are enabled, `Update-NovaModuleTool` may target a prerelease. If the selected target is a prerelease, the command always asks for explicit confirmation before it proceeds, and that prerelease confirmation defaults to `No` so pressing Enter cancels the update.

Stable updates do not require prerelease confirmation.

When a newer version is available, `Update-NovaModuleTool` shows progress while it installs the update and reads the release-notes link from the updated module. Every command path ends with a visible summary: up-to-date, preview, cancelled, or updated.

After a successful update, `Update-NovaModuleTool` prints the release notes link from the installed module manifest and suggests `Get-NovaProjectInfo -Installed` as the next verification step.

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

Previews the resolved update action without prompting for prerelease confirmation or running `Update-Module`.

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

If the PowerShell Gallery cannot be reached well enough to resolve an update candidate, the command stops before calling
`Update-Module`.

Use `Get-NovaUpdateNotificationPreference` and `Set-NovaUpdateNotificationPreference` to inspect or change the stored prerelease setting.

Use `Ctrl+C` if you need to stop an active self-update before `Update-Module` finishes.

## RELATED LINKS

- [Get-NovaUpdateNotificationPreference](./Get-NovaUpdateNotificationPreference.md)
- [Set-NovaUpdateNotificationPreference](./Set-NovaUpdateNotificationPreference.md)
- [Get-NovaProjectInfo](./Get-NovaProjectInfo.md)
- [Invoke-NovaBuild](./Invoke-NovaBuild.md)
