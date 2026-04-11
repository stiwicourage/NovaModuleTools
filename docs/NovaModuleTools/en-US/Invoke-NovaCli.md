---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/11/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaCli
---

# Invoke-NovaCli

## SYNOPSIS

Provides the command backend for the `nova` alias and a more user-friendly CLI experience.

## SYNTAX

### __AllParameterSets

```powershell
Invoke-NovaCli [[-Command] <string>] [[-Arguments] <string[]>] [<CommonParameters>]
```

## DESCRIPTION

`Invoke-NovaCli` is the cmdlet behind the `nova` alias. In day-to-day usage, the intended experience is to run the
`nova` command rather than call `Invoke-NovaCli` directly.

It dispatches high-level commands such as `nova info`, `nova --version`, `nova --help`, `nova build`, `nova test`,
`nova init`, `nova publish`, `nova bump`, and `nova release` to the matching Nova cmdlet.

Use `Invoke-NovaCli` when you need a scriptable PowerShell command entrypoint. Use `nova` when you want the more
user-friendly CLI-style experience.

## EXAMPLES

### EXAMPLE 1

```powershell
nova --version
```

Returns the version from `project.json`.

### EXAMPLE 2

```powershell
nova build
```

Builds the module using `Invoke-NovaBuild`.

### EXAMPLE 3

```powershell
nova publish --repository PSGallery --apikey ***
```

Parses CLI arguments and publishes using `Publish-NovaModule`.

### EXAMPLE 4

```powershell
nova --help
```

Displays the built-in Nova CLI help text.

### EXAMPLE 5

```powershell
Invoke-NovaCli -Command build
```

Shows the equivalent scripted PowerShell form behind `nova build`.

## PARAMETERS

### -Command

The command to execute. Supported values: `info`, `--version`, `--help`, `build`, `test`, `init`, `publish`, `bump`,
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
AcceptedValues: [ info, --version, --help, build, test, init, publish, bump, release ]
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
`-WarningAction`, and `-WarningVariable`.

## INPUTS

## OUTPUTS

## NOTES

For interactive use, prefer the `nova` alias.

Use `Invoke-NovaCli` directly when you need the underlying PowerShell command in scripts, tests, or command dispatch
implementations.

## RELATED LINKS

- `Invoke-NovaBuild`
- `Test-NovaBuild`
- `Invoke-NovaRelease`

