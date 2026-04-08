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

### [Get-MTProjectInfo](Get-MTProjectInfo.md)

Retrieves information about a project by reading data from a project.json file in a NovaModuleTools project folder.

### [Invoke-MTBuild](Invoke-MTBuild.md)

Build a ModuleTool project to generate ready to import PowerShell Module.

### [Invoke-MTTest](Invoke-MTTest.md)

Runs Pester tests using settings from project.json

### [New-MTModule](New-MTModule.md)

Create module scaffolding along with project.json file to easily build and manage modules in the NovaModuleTools opinionated format.

### [Publish-MTLocal](Publish-MTLocal.md)

Copy built module to local PSModulePath.

### [Update-MTModuleVersion](Update-MTModuleVersion.md)

Updates the version number of a module in project.json file. Uses [semver] object type.



