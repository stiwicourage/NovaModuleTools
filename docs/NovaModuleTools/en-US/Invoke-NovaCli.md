---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/25/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaCli
---

# Invoke-NovaCli

## SYNOPSIS

Provides the PowerShell command backend for routed Nova CLI operations.

## SYNTAX

### __AllParameterSets

```text
PS> Invoke-NovaCli [[-Command] <string>] [[-Arguments] <string[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Invoke-NovaCli` is the explicit PowerShell cmdlet entrypoint for routed Nova command dispatch.

In day-to-day usage, the intended CLI experience is to run the `nova` launcher rather than call `Invoke-NovaCli`
directly.

It dispatches high-level commands such as `% nova info`, `% nova version`, `% nova --version`, `% nova -v`,
`% nova --help`,
`% nova -h`, `% nova build`, `% nova test`, `% nova package`, `% nova deploy`, `% nova init`, `% nova update`,
`% nova notification`, `% nova publish`, `% nova bump`, and `% nova release` to the matching Nova cmdlet.

Use `Invoke-NovaCli` when you need a scriptable PowerShell command entrypoint. Use `nova` when you want the
user-focused CLI experience.

Use `% nova <command> --help` or `% nova <command> -h` when you want the routed PowerShell help for a specific command
such
as `% nova package`, `% nova deploy`, or `% nova init`.

Mutating routed commands (`build`, `test`, `package`, `deploy`, `bump`, `update`, `notification`, `publish`, and
`release`) forward CLI `--verbose`/`-v` and `--whatif`/`-w` to the underlying cmdlet, while `--confirm`/`-c` is
handled at the CLI layer so routed commands never expose PowerShell's interactive `Suspend` behavior.

The routed PowerShell cmdlets themselves still expose their native `-Verbose`, `-WhatIf`, and `-Confirm` behavior when
you call those cmdlets directly from PowerShell. Use the `nova` surface when you want the shell-safe CLI confirmation
flow.

Use `% nova package` when you want to build, test, and package the current project into one or more configured package
artifacts. By default it writes a `.nupkg` to `artifacts/packages/`, and you can override that with
`Package.OutputDirectory.Path` in `project.json`.

Use `Package.Types` in `project.json` when you want to switch from the default `NuGet` output to `Zip`, or when you
want both formats. Supported values are `NuGet`, `Zip`, `.nupkg`, and `.zip`, and matching is case-insensitive.

Set `Package.Latest` to `true` when you also want `% nova package` to create companion latest-named package artifacts
such
as `NovaModuleTools.latest.nupkg` next to the normal versioned files.

Set `Package.AddVersionToFileName` to `true` when `Package.PackageFileName` is a stable base name such as
`AgentInstaller` and you want Nova to append `.<Version>` from `project.json` before creating the package files.

Use `% nova deploy` when you want to push existing package artifacts from the configured package output directory to a
raw
HTTP endpoint. It can upload all matching artifacts for the configured package types, including versioned and `latest`
files, and it resolves the upload target from `--url`, `Package.RepositoryUrl`, or `Package.Repositories`.

For local publish inside an imported PowerShell session, `% nova publish --local` now reloads the published module from
the
resolved local install path after the copy succeeds. Preview or cancelled runs do not import anything.

Use `% nova notification` to show the current prerelease self-update preference,
`% nova notification --disable` / `% nova notification -d` to keep `% nova update` on stable releases only, and
`% nova notification --enable` / `% nova notification -e` to allow prerelease self-update targets again.

Use `% nova version` to show the current project version from `project.json`.

Use `% nova version --installed` / `% nova version -i` to show the locally installed version of the current
project/module
from the local PowerShell module path.

Use `% nova --version` / `% nova -v` to show the installed `NovaModuleTools` version. Those are intentionally separate
version views.

Use `% nova update` to self-update the installed `NovaModuleTools` module. It uses the stored prerelease preference to
decide whether a prerelease target is eligible. When that preference is disabled, `% nova update` only targets stable
releases. When it is enabled, `% nova update` may target a prerelease, but it always asks for explicit confirmation
before running a prerelease update. If no newer version is available, the standalone launcher prints a short
`You're up to date!` summary that includes the installed version.

For routed CLI usage, `% nova <mutating-command> --confirm` / `% nova <mutating-command> -c` uses a CLI-friendly
confirmation prompt. `Y` / `Yes` and `A` / `Yes to All` continue, `N` / `No` and `L` / `No to All` cancel with a
non-zero exit code, and `S` / `Suspend` is treated as cancel because nested PowerShell prompts are not supported in
CLI mode.

Use `% nova bump --preview` / `% nova bump -p` when you want an explicit prerelease-continuation bump. Stable versions
resolve to the normal semantic target plus `-preview`, while existing prerelease versions stay on the same semantic core
and preserve the current prerelease stem while appending or incrementing trailing digits such as `preview -> preview01`,
`preview09 -> preview10`, `rc -> rc01`, `rc1 -> rc2`, or `SNAPSHOT -> SNAPSHOT01`.

`% nova init` remains interactive. Use `% nova init --path <path>` / `% nova init -p <path>` when you want an explicit
destination and `% nova init --example` / `% nova init -e` when you want the packaged example scaffold. The CLI rejects
positional `% nova init <path>` usage and also rejects `% nova init --whatif` / `% nova init -w` with a clear error.

Inside PowerShell, call `Invoke-NovaCli` explicitly when you need the routed cmdlet backend in scripts, tests, or
command
dispatch scenarios. To make `nova` available directly in the shell, install or use the packaged launcher. The launcher
forwards `--verbose`/`-v` and `--whatif`/`-w`, and it uses the same CLI-safe confirmation flow for `--confirm`/`-c`
on mutating commands.

## EXAMPLES

### EXAMPLE 1

```text
% nova --version
% nova -v
```

Returns the installed `NovaModuleTools` module version.
The output format is `NovaModuleTools <Version>` for stable installs and `NovaModuleTools <Version>-<Prerelease>` when
the installed module manifest includes prerelease metadata.

### EXAMPLE 2

```text
% nova package --help
```

Shows the full help for `New-NovaModulePackage` through the CLI.

### EXAMPLE 3

```text
% nova version --installed
```

Returns the version currently installed locally for the current project/module.

### EXAMPLE 4

```text
% nova build
```

Builds the module using `Invoke-NovaBuild`.

### EXAMPLE 5

```text
% nova package
```

Builds, tests, and packages the current project by using the configured `Package.Types` values. When `Package.Types` is
omitted, `% nova package` creates a `.nupkg` by default.

### EXAMPLE 6

```text
% nova deploy --repository LocalNexus
```

Uploads the current project's generated package artifacts to the configured raw repository named `LocalNexus`.

### EXAMPLE 7

```text
% nova deploy --url https://packages.example/raw/ --token $env:NOVA_PACKAGE_TOKEN
```

Uploads the matching package artifacts directly to the provided raw endpoint by using an explicit token.

### EXAMPLE 8

```text
% nova publish --repository PSGallery --api-key $env:PSGALLERY_API
```

Parses CLI arguments and publishes using `Publish-NovaModule`.

When routed inside PowerShell with `--local`, the published module is reloaded from the local install path.

### EXAMPLE 9

```text
% nova --help
```

Shows the top-level Nova CLI help.

### EXAMPLE 10

```text
PS> Invoke-NovaCli -Command build
```

Runs the same routed build flow through the explicit PowerShell cmdlet entrypoint.

### EXAMPLE 11

```text
PS> Invoke-NovaCli -Command publish -Arguments @('--local') -WhatIf
```

Routes `publish --local` through the PowerShell cmdlet entrypoint while keeping native PowerShell `-WhatIf` on the
outer call.

### EXAMPLE 12

```text
PS> Invoke-NovaCli -Command init -Arguments @('--path', '~/Work')
```

Starts the routed init flow from the PowerShell cmdlet entrypoint.

### EXAMPLE 13

```text
PS> Invoke-NovaCli -Command init -Arguments @('--example', '--path', '~/Work')
```

Starts the example scaffold flow from the PowerShell cmdlet entrypoint.

### EXAMPLE 14

```text
% nova deploy --help
```

Shows the full help for `Deploy-NovaPackage` through the CLI.

### EXAMPLE 15

```text
% nova init --help
```

Shows the full help for `Initialize-NovaModule` through the CLI without starting the interactive scaffold flow.

### EXAMPLE 16

```text
% nova bump --preview --whatif
```

Previews an explicit preview bump by routing `--preview` through `Update-NovaModuleVersion`.

### EXAMPLE 17

```text
% nova version
```

Returns the current project version from `project.json`.
The output format is `<ProjectName> <Version>`.

### EXAMPLE 18

```text
% nova update
```

Runs the self-update flow through the launcher-oriented CLI surface.

### EXAMPLE 19

```text
% nova notification
```

Shows the current prerelease self-update preference from the CLI surface.

### EXAMPLE 20

```text
% nova notification --disable
```

Disables prerelease self-update eligibility through the CLI surface.

### EXAMPLE 21

```text
PS> Invoke-NovaCli -Command notification -Arguments @('--enable')
```

Routes the notification enable command through the explicit PowerShell cmdlet entrypoint.

## PARAMETERS

### -Command

Top-level Nova command to route. Defaults to `--help`.

```yaml
Type: System.String
DefaultValue: --help
SupportsWildcards: false
Aliases: [ nova ]
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

### -Arguments

Raw routed argument list for the selected Nova command.

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

### -WhatIf

Shows what would happen if the routed command runs.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases:
  - wi
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

Prompts for confirmation before the routed command runs when the selected routed command supports confirmation.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases:
  - cf
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

### System.Object

Returns the same output that the selected routed Nova command returns.

## NOTES

Use `Invoke-NovaCli` directly when you need the underlying PowerShell command in scripts, tests, or command dispatch
scenarios.

`Invoke-NovaCli` uses `SupportsShouldProcess` to surface native `-WhatIf` and `-Confirm`, then forwards those switches
to the routed command model that owns the final confirmation behavior.

## RELATED LINKS

- `Install-NovaCli`
- `Invoke-NovaBuild`
- `Initialize-NovaModule`
- `New-NovaModulePackage`
- `Deploy-NovaPackage`
- `Publish-NovaModule`
- `Update-NovaModuleVersion`
