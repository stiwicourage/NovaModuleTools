---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/12/2026
PlatyPS schema version: 2024-05-01
title: Install-NovaCli
---

# Install-NovaCli

## SYNOPSIS

Installs the bundled `nova` launcher so it can be run directly from zsh/bash on macOS or Linux.

## SYNTAX

### __AllParameterSets

```powershell
Install-NovaCli [[-DestinationDirectory] <string>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Install-NovaCli` copies the bundled `nova` launcher from the installed NovaModuleTools module into a user-facing
command directory.

By default, the launcher is installed to `~/.local/bin/nova` on macOS and Linux. If that directory is not on your
`PATH`, the command warns so you can update your shell profile.

This command is currently intended for macOS and Linux. On Windows, use the `nova` alias inside `pwsh` after importing
NovaModuleTools.

## EXAMPLES

### EXAMPLE 1

```powershell
Install-NovaCli
```

Installs `nova` to `~/.local/bin/nova`.

### EXAMPLE 2

```powershell
Install-NovaCli -DestinationDirectory ~/bin -Force
```

Installs or overwrites `nova` in a custom directory.

## PARAMETERS

### -DestinationDirectory

Optional target directory for the installed `nova` launcher.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: (All)
    Position: 0
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: [ ]
HelpMessage: ''
```

### -Force

Overwrite an existing `nova` launcher at the destination path.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: [ ]
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

## OUTPUTS

### PSCustomObject

Returns the installed command name, destination directory, installed path, and whether the destination directory is
currently on `PATH`.

## NOTES

After running `Install-NovaCli`, add the destination directory to your shell `PATH` if needed.

## RELATED LINKS

- `Invoke-NovaCli`
- `Publish-NovaModule`

