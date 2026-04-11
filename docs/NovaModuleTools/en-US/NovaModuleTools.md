---
document type: module
Help Version: 1.0.0.0
HelpInfoUri: ''
Locale: en-US
Module Guid: 6b9202c8-0353-473b-b73c-afab632125a6
Module Name: NovaModuleTools
ms.date: 03/19/2026
PlatyPS schema version: 2024-05-01
title: NovaModuleTools Module
---

# NovaModuleTools Module

## Description

NovaModuleTools is a versatile, standalone PowerShell module builder. Create anything from simple to robust modules with ease. Built for CICD and Automation.

## NovaModuleTools Cmdlets

### `Get-NovaProjectInfo`

Retrieves information about a project by reading data from a project.json file in a NovaModuleTools project folder.

### `Invoke-NovaBuild`

Build a NovaModuleTools project to generate a ready-to-import PowerShell module.

### `Invoke-NovaCli`

Runs Nova CLI-style commands through a single command entrypoint.

### `Invoke-NovaRelease`

Runs the Nova release pipeline (build, test, version bump, rebuild, publish).

### `Test-NovaBuild`

Runs Pester tests using settings from project.json

### `New-NovaModule`

Create module scaffolding along with project.json file to easily build and manage modules in the NovaModuleTools opinionated format.

### `Publish-NovaModule`

Copy built module to local PSModulePath.

### `Update-NovaModuleVersion`

Updates the version number of a module in project.json file. Uses [semver] object type.



