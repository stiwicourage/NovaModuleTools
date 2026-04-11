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

### [Get-NovaProjectInfo](Get-NovaProjectInfo.md)

Retrieves information about a project by reading data from a project.json file in a NovaModuleTools project folder.

### [Invoke-NovaBuild](Invoke-NovaBuild.md)

Build a ModuleTool project to generate ready to import PowerShell Module.

### [Invoke-NovaCli](Invoke-NovaCli.md)

Runs Nova CLI-style commands through a single command entrypoint.

### [Invoke-NovaRelease](Invoke-NovaRelease.md)

Runs the Nova release pipeline (build, test, version bump, rebuild, publish).

### [Test-NovaBuild](Test-NovaBuild.md)

Runs Pester tests using settings from project.json

### [New-NovaModule](New-NovaModule.md)

Create module scaffolding along with project.json file to easily build and manage modules in the NovaModuleTools opinionated format.

### [Publish-NovaModule](Publish-NovaModule.md)

Copy built module to local PSModulePath.

### [Update-NovaModuleVersion](Update-NovaModuleVersion.md)

Updates the version number of a module in project.json file. Uses [semver] object type.



