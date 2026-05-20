---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: 'https://www.novamoduletools.com/core-workflows.html#agentic-copilot'
Locale: en-US
Module Name: NovaModuleTools
ms.date: 05/20/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaAgenticCopilotScaffold
---

# Invoke-NovaAgenticCopilotScaffold

## SYNOPSIS

Apply or refresh Nova's managed Agentic Copilot scaffold in an existing project.

## SYNTAX

### __AllParameterSets

```text
Invoke-NovaAgenticCopilotScaffold [[-Path] <string>] [-ShortName] <string> [-OverrideWarning]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Invoke-NovaAgenticCopilotScaffold` applies Nova's maintained Agentic Copilot scaffold to an existing project root.

The command reads `ProjectName` and `Description` from the target `project.json`, requires a `ShortName` on every run for token replacement, and refreshes only Nova-managed Agentic Copilot paths. Existing `README.md`, `CHANGELOG.md`, and `RELEASE_NOTE.md` are preserved and are created only when they are missing.

By default the workflow shows an overwrite warning before it updates the managed scaffold paths. Use `-OverrideWarning` only when you intentionally want a non-interactive apply or refresh.

The target path must contain a valid `project.json`. Invalid project metadata or an invalid short name stops the command with a clear validation error.

## EXAMPLES

### EXAMPLE 1

```text
PS> Invoke-NovaAgenticCopilotScaffold -ShortName NMT
```

Apply or refresh the Nova-managed Agentic Copilot scaffold in the current project root after the overwrite warning is confirmed.

### EXAMPLE 2

```text
PS> Invoke-NovaAgenticCopilotScaffold -Path ~/Work/MyModule -ShortName NMT -OverrideWarning
```

Apply or refresh the managed scaffold in a specific project root without showing the overwrite warning prompt.

### EXAMPLE 3

```text
PS> Invoke-NovaAgenticCopilotScaffold -ShortName NMT -WhatIf
```

Preview the managed scaffold apply workflow without writing or overwriting files.

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

### -OverrideWarning

Skip the overwrite warning prompt and continue directly with the managed scaffold apply or refresh workflow.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

Project root that contains the existing `project.json` file. Defaults to the current location.

```yaml
Type: System.String
DefaultValue: ''
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

### -ShortName

Short placeholder name used in generated guidance tokens such as `Invoke-<ShortName>*`. Use a value that starts with a letter and contains only letters or numbers.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

You can't pipe objects to this cmdlet.

## OUTPUTS

### None

This cmdlet does not emit an output object.

## NOTES

This workflow does not persist `ShortName` to `project.json` and does not infer it from any existing scaffold files. It refreshes only these Nova-managed paths:

- `.github/agents/`
- `.github/instructions/`
- `.github/prompts/`
- `.github/skills/`
- `.github/copilot-instructions.md`
- `.github/pull_request_template.md`
- `AGENTS.md`
- `CONTRIBUTING.md`

`README.md`, `CHANGELOG.md`, and `RELEASE_NOTE.md` are created only when they are missing.

## RELATED LINKS

- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Initialize-NovaModule.md
- https://github.com/stiwicourage/NovaModuleTools/blob/main/docs/NovaModuleTools/en-US/Get-NovaProjectInfo.md
