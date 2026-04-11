---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 03/19/2026
PlatyPS schema version: 2024-05-01
title: New-NovaModule
---

# New-NovaModule

## SYNOPSIS

Create module scaffolding along with project.json file to easily build and manage modules in the NovaModuleTools opinionated format.

## SYNTAX

### __AllParameterSets

```
New-NovaModule [[-Path] <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This command creates folder structure and project.json file easily. Use this to quickly set up a NovaModuleTools-compatible module. Provide all parameters to the command or enter details in the interactive prompts with sane defaults. Generated projects now start with enterprise-oriented defaults for recursive discovery, source-path markers, and duplicate-function validation.

## EXAMPLES

### EXAMPLE 1

New-NovaModule -Path c:\work
Creates module inside c:\work folder

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
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
AcceptedValues: []
HelpMessage: ''
```

### -Path

Path where module will be created.

```yaml
Type: System.String
DefaultValue: (Get-Location).Path
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
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
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

The structure of the NovaModuleTools module is meticulously designed according to PowerShell best practices for module development.
While some design decisions may seem unconventional, they are made to ensure that NovaModuleTools and the process of building modules remain straightforward and easy to manage.


## RELATED LINKS

{{ Fill in the related links here }}




