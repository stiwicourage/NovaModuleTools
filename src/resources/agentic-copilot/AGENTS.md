# AGENTS.md

Use this file as a landing page for work with agents in this repository.

This repository uses an Agentic Copilot workflow.

This is a Nova-managed PowerShell module project. Use Nova commands and `project.json` for build, test, package, and release behavior. Match PowerShell code, tests, and examples to `project.json` `Manifest.PowerShellHostVersion`; if it is `5.1`, avoid PowerShell 7.x-only features. Fix any ScriptAnalyzer findings reported by `run.ps1` before handoff. Keep one externally called function per file and match the file name to that function, with private-file extras limited to same-file support helpers. Follow `.github/instructions/code-quality-matrix.instructions.md` as the best-effort src/tests quality matrix; this starter does not require `.codescene/code-health-rules.json`. End every changed or generated text file with exactly one trailing newline and no extra blank lines at the bottom. Do not hand-create module `.psm1` or module `.psd1` files in source. Do not exclude or suppress PSScriptAnalyzer rules.

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
