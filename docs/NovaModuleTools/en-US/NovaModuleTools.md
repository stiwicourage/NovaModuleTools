---
document type: module
Help Version: 1.0.0.0
HelpInfoUri: ''
Locale: en-US
Module Guid: 6b9202c8-0353-473b-b73c-afab632125a6
Module Name: NovaModuleTools
ms.date: 04/25/2026
PlatyPS schema version: 2024-05-01
title: NovaModuleTools Module
---

# NovaModuleTools Module

## Description

NovaModuleTools helps you scaffold, build, test, package, version, and publish PowerShell modules with a consistent
project layout and a repeatable workflow.

Use the module when you want a structured path from source files under `src/` to a built module under `dist/`, including
manifest generation, external help generation, resource copying, and Pester-based validation.

## NovaModuleTools Cmdlets

### `PS> Get-NovaProjectInfo`

Reads `project.json` and returns resolved project metadata and paths.

### `PS> Get-NovaUpdateNotificationPreference`

Shows whether prerelease update notifications are enabled. Stable release notifications always remain enabled.

### `PS> Install-NovaCli`

Installs the bundled command-line launcher into a user command directory on macOS or Linux.

### `PS> Invoke-NovaBuild`

Builds the current NovaModuleTools project into a ready-to-import PowerShell module.

### `PS> Invoke-NovaCli`

Routes Nova commands through the explicit PowerShell cmdlet entrypoint.

### `PS> Invoke-NovaRelease`

Runs the Nova release pipeline (build, test, version bump, rebuild, publish).

### `PS> New-NovaModulePackage`

Builds, tests, and packages the current project as one or more configured package artifacts.

### `PS> Deploy-NovaPackage`

Uploads generated package artifacts to a raw HTTP endpoint by using generic package upload settings.

### `PS> Test-NovaBuild`

Runs the project's Pester test workflow using settings from `project.json`.

### `PS> Update-NovaModuleTool`

Updates the installed `NovaModuleTools` module by using the stored prerelease preference that also controls whether
prerelease self-updates are eligible. The compatibility alias `Update-NovaModuleTools` is also available.

### `PS> Initialize-NovaModule`

Creates a new NovaModuleTools project scaffold through an interactive prompt flow.

### `PS> Publish-NovaModule`

Builds, tests, and publishes the current project either locally or to a repository.

### `PS> Set-NovaUpdateNotificationPreference`

Enables or disables whether prerelease self-updates are eligible for `Update-NovaModuleTool`.

### `PS> Update-NovaModuleVersion`

Updates the project version in `project.json` based on the current git commit history.
