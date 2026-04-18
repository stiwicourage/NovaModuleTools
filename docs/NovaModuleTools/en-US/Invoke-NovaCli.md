---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/14/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaCli
---

# Invoke-NovaCli

## SYNOPSIS

Provides the command backend for the `nova` alias and a more user-friendly CLI experience.

## SYNTAX

### __AllParameterSets

```powershell
PS> Invoke-NovaCli [[-Command] <string>] [[-Arguments] <string[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Invoke-NovaCli` is the cmdlet behind the `nova` alias. In day-to-day usage, the intended experience is to run the
`nova` CLI rather than call `Invoke-NovaCli` directly.

It dispatches high-level commands such as `nova info`, `nova version`, `nova --version`, `nova --help`, `nova build`,
`nova test`,
`nova init`, `nova publish`, `nova bump`, and `nova release` to the matching Nova cmdlet.

Use `Invoke-NovaCli` when you need a scriptable PowerShell command entrypoint. Use `nova` when you want the
user-focused CLI experience.

Mutating routed commands (`build`, `test`, `bump`, `publish`, and `release`) forward PowerShell
`-WhatIf`/`-Confirm` to the underlying cmdlet. That means `nova build -WhatIf` and
`Invoke-NovaCli -Command build -WhatIf` both preview the build instead of running it.

For local publish inside an imported PowerShell session, `nova publish -local` now reloads the published module from the
resolved local install path after the copy succeeds. Preview or cancelled runs do not import anything.

For the standalone launcher, `nova bump -Confirm` uses a CLI-friendly confirmation prompt. Declined or suspended choices
cancel the bump cleanly and return control to the shell without printing a version result.

`nova init` remains interactive. Use `nova init -Path <path>` when you want an explicit destination and
`nova init -Example` when you want the packaged example scaffold. The CLI rejects positional `nova init <path>` usage
and also rejects `nova init -WhatIf` with a clear error.

Inside an imported PowerShell session, `nova` is available through the cmdlet alias. To make `nova` available directly
from zsh/bash on macOS or Linux, install the launcher once with `Install-NovaCli`. The standalone launcher also forwards
`-Verbose`, `-WhatIf`, and `-Confirm` for mutating commands.

## EXAMPLES

### EXAMPLE 1

```powershell
nova --version
```

Returns the installed `NovaModuleTools` module version.
The output format is `NovaModuleTools <Version>`.

### EXAMPLE 2

```powershell
nova version
```

Returns the current project version from `project.json`.
The output format is `<ProjectName> <Version>`.

### EXAMPLE 3

```powershell
nova build
```

Builds the module using `Invoke-NovaBuild`.

### EXAMPLE 4

```powershell
nova publish --repository PSGallery --apikey $env:PSGALLERY_API
```

Parses CLI arguments and publishes using `Publish-NovaModule`.

When routed inside PowerShell with `-local`, the published module is reloaded from the local install path.

### EXAMPLE 5

```powershell
nova --help
```

Displays the built-in Nova CLI help text.

### EXAMPLE 6

```powershell
PS> Invoke-NovaCli -Command build
```

Shows the equivalent scripted PowerShell form behind `nova build`.

### EXAMPLE 7

```powershell
PS> Invoke-NovaCli -Command publish -Arguments @('-local') -WhatIf
```

Previews the routed local publish flow without rebuilding, testing, or copying the module.

### EXAMPLE 8

```powershell
PS> Invoke-NovaCli -Command init -Arguments @('-Path', '~/Work')
```

Runs the interactive init flow and creates the project under `~/Work`.

### EXAMPLE 9

```powershell
PS> Invoke-NovaCli -Command init -Arguments @('-Example', '-Path', '~/Work')
```

Runs the interactive init flow, scaffolds from the packaged example project, and creates the project under `~/Work`.

## PARAMETERS

### -Command

The command to execute. Supported values: `info`, `version`, `--version`, `--help`, `build`, `test`, `init`, `publish`,
`bump`,
`release`.

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
AcceptedValues: [ info, version, --version, --help, build, test, init, publish, bump, release ]
HelpMessage: ''
```

### -Arguments

Remaining CLI arguments passed to the selected command.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: (All)
    Position: 1
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: true
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

### System.String

Returned for text-oriented commands such as `nova --help`, `nova version`, and `nova --version`.

### PSCustomObject

Returned when the selected subcommand returns an object, for example `nova info`.

### None

Some routed commands complete without returning an output object.

## NOTES

For interactive use, prefer the `nova` alias.

Use `Invoke-NovaCli` directly when you need the underlying PowerShell command in scripts, tests, or command dispatch
implementations.

`Invoke-NovaCli` uses `SupportsShouldProcess` to surface native `-WhatIf` and `-Confirm`, then forwards those switches
only to mutating subcommands.

## RELATED LINKS

- `Invoke-NovaBuild`
- `Install-NovaCli`
- `Test-NovaBuild`
- `Invoke-NovaRelease`

