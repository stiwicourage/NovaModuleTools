# AGENTS.md

Use this file as a landing page for work with agents in this repository.

This repository uses an Agentic Copilot workflow.

This is a Nova-managed PowerShell module project. Use Nova commands and `project.json` for build, test, package, and release behavior. Match PowerShell code, tests, and examples to `project.json` `Manifest.PowerShellHostVersion`; if it is `5.1`, avoid PowerShell 7.x-only features. Fix any ScriptAnalyzer findings reported by `run.ps1` before handoff. Follow `.github/instructions/psscriptanalyzer.instructions.md` as the ScriptAnalyzer workflow source of truth, with `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and `./run.ps1` as the normal entrypoints. Use `Test-NovaBuild` as the project test entrypoint and do not validate with direct `Invoke-Pester`. Keep one externally called function per file and match the file name to that function, with private-file extras limited to related same-file top-level support helpers and no nested function declarations inside PowerShell functions. Follow `.github/instructions/code-quality-matrix.instructions.md` for source/helper-script maintainability and
`.github/instructions/testing-policy.instructions.md` for test design. Keep
`docs/{{ProjectName}}/en-US/*.md` as valid PlatyPS command help by using `New-MarkdownCommandHelp`,
`Update-MarkdownCommandHelp`, and `Test-MarkdownCommandHelp`, and create the matching help file immediately for every new public entry point. End every changed or generated text file with exactly one trailing newline and no extra blank lines at the bottom. Do not hand-create module
`.psm1` or module `.psd1` files in source. Do not exclude or suppress PSScriptAnalyzer rules.

## Workflow

1. Design
2. Implement
3. Review
4. Prepare release

For the full workflow, continue with the files below.

## Authoritative files

- `README.md`
- `CONTRIBUTING.md`
- `.github/copilot-instructions.md`
- `.github/instructions/`
- `.github/agents/`
- `.github/skills/`
- `.github/prompts/`
