---
document type: module
Help Version: 1.0.0.0
HelpInfoUri: ''
Locale: en-US
Module Guid: 6b9202c8-0353-473b-b73c-afab632125a6
Module Name: NovaModuleTools
ms.date: 04/14/2026
PlatyPS schema version: 2024-05-01
title: NovaModuleTools Module
---

# NovaModuleTools Module

## Description

NovaModuleTools helps you scaffold, build, test, version, and publish PowerShell modules with a consistent project
layout and a repeatable workflow.

Use the module when you want a structured path from source files under `src/` to a built module under `dist/`, including
manifest generation, external help generation, resource copying, and Pester-based validation.

## NovaModuleTools Cmdlets

### `Get-NovaProjectInfo`

Reads `project.json` and returns resolved project metadata and paths.

### `Install-NovaCli`

Installs the bundled `nova` launcher into a user command directory on macOS or Linux.

### `Invoke-NovaBuild`

Builds the current NovaModuleTools project into a ready-to-import PowerShell module.

### `Invoke-NovaCli`

Routes the `nova` CLI experience through a single PowerShell command entrypoint.

### `Invoke-NovaRelease`

Runs the Nova release pipeline (build, test, version bump, rebuild, publish).

### `Test-NovaBuild`

Runs the project's Pester test workflow using settings from `project.json`.

### `New-NovaModule`

Creates a new NovaModuleTools project scaffold through an interactive prompt flow.

### `Publish-NovaModule`

Builds, tests, and publishes the current project either locally or to a repository.

### `Update-NovaModuleVersion`

Updates the project version in `project.json` based on the current git commit history.



