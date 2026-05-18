@{
    OutputPath = 'src/resources/agentic-copilot'

    SourcePaths = @(
        '.github/copilot-instructions.md'
        '.github/agents'
        '.github/instructions'
        '.github/skills'
        '.github/prompts'
    )

    ScaffoldOwnedPaths = @(
        'README.md'
        'CONTRIBUTING.md'
        'CHANGELOG.md'
        'RELEASE_NOTE.md'
        '.github/pull_request_template.md'
        'scripts/build/Test-TextFileFormatting.ps1'
        'tests/TextFileFormatting.Tests.ps1'
    )

    GeneratedMirrors = @(
        @{
            Source = '.github/copilot-instructions.md'
            RepositoryTarget = 'AGENTS.md'
            ScaffoldTarget = 'AGENTS.md'
        }
    )

    IdentifierReplacements = @(
        @{
            Old = 'NovaModuleTools'
            New = '{{ProjectName}}'
        }
        @{
            Old = '-Nova*'
            New = '-{{ShortName}}*'
        }
    )

    ExcludedPaths = @(
        '.github/agents/docs-site.agent.md'
        '.github/instructions/documentation-separation.instructions.md'
        '.github/skills/docs-site/'
        '.github/skills/codescene-quality/'
        '.github/skills/guiding-refactoring-with-code-health/'
        '.github/skills/safeguarding-ai-generated-code/'
        '.github/skills/github-actions/'
        '.github/prompts/fix-ci-failure.prompt.md'
    )

    TextReplacements = @(
        @{
            Old = 'NovaModuleTools is not a generic PowerShell repo. It has a strong split between public commands, private helpers, Pester-heavy testing, GitHub Actions automation, CodeScene coverage gates, and Keep a Changelog / SemVer release flow.'
            New = '{{ProjectName}} is a Nova-managed PowerShell module project. Keep public commands, private helpers, Pester tests, release history, and documentation aligned with `project.json` and the generated project layout.'
        }
        @{
            Old = 'CodeScene'
            New = 'quality tooling'
        }
        @{
            Old = 'Code Health'
            New = 'maintainability'
        }
        @{
            Old = 'docs-site'
            New = 'documentation'
        }
        @{
            Old = 'github-actions'
            New = 'workflow guidance'
        }
        @{
            Old = 'documentation-separation'
            New = 'documentation'
        }
        @{
            Old = '- Treat maintainability as authoritative for maintainability in this repository.'
            New = '- Treat maintainability as a release-readiness concern for this repository.'
        }
        @{
            Old = '- Target maintainability `10.0` for AI-touched files; `9.x` is not the goal state.'
            New = '- Keep AI-touched files small, clear, and easy to review.'
        }
        @{
            Old = '- Keep `docs/*.html`, `docs/NovaModuleTools/en-US/*.md`, and contributor docs clearly separated by audience and syntax.'
            New = '- Keep command help `docs/{{ProjectName}}/en-US/*.md`, contributor docs, and release history clearly separated by audience and syntax.'
        }
        @{
            Old = '- CI-parity coverage flow: `./scripts/build/ci/Invoke-NovaModuleToolsCI.ps1 -OutputDirectory ./artifacts`'
            New = '- CI-parity coverage flow: use the repository-specific CI helper when one exists'
        }
        @{
            Old = 'When quality tooling tooling is available:'
            New = 'When project-specific quality tooling is available:'
        }
        @{
            Old = '- run the pre-commit safeguard on AI-touched changes before suggesting a commit'
            New = '- run the configured local safeguard before suggesting a commit'
        }
        @{
            Old = '- run a branch/change-set analysis before suggesting a PR or declaring a larger change ready'
            New = '- run the configured branch or change-set check before suggesting a PR'
        }
        @{
            Old = '- if quality tooling reports a regression, refactor instead of treating the work as done'
            New = '- if quality tooling reports a regression, refactor instead of treating the work as done'
        }
        @{
            Old = '- use the `guiding-refactoring-with-maintainability` skill for small, measured maintainability-driven refactors'
            New = '- use the relevant refactoring guidance for small, measured maintainability improvements'
        }
        @{
            Old = '- use the `guiding-refactoring-with-code-health` skill for small, measured maintainability-driven refactors'
            New = '- use the relevant refactoring guidance for small, measured maintainability improvements'
        }
        @{
            Old = '- use the `safeguarding-ai-generated-code` skill when deciding whether AI-touched work is ready for commit or PR handoff'
            New = '- use the relevant review or quality guidance when deciding whether AI-touched work is ready for handoff'
        }
        @{
            Old = 'If quality tooling tooling is unavailable locally, continue with the normal repository validation flow and continue silently; the pull request and CI flow remains the effective quality tooling gate.'
            New = 'If optional quality tooling is unavailable locally, continue with the normal repository validation flow; pull requests and CI remain the effective gate.'
        }
        @{
            Old = '- `.github/workflows/` - GitHub Actions CI, analyzer, dependency review, and publish automation'
            New = '- `.github/workflows/` - repository workflow automation, when present'
        }
        @{
            Old = '- `.github/actions/` - reusable workflow actions used by release and coverage flows'
            New = '- `.github/actions/` - reusable workflow actions, when present'
        }
        @{
            Old = '- `docs/NovaModuleTools/en-US/` - command help source'
            New = '- `docs/{{ProjectName}}/en-US/` - command help source'
        }
        @{
            Old = '- `project docs` - end-user GitHub Pages content'
            New = '- `docs/` - project documentation'
        }
        @{
            Old = '- `.github/instructions/documentation.instructions.md`'
            New = ''
        }
        @{
            Old = '- `/quality tooling-quality`'
            New = ''
        }
        @{
            Old = '- `/codescene-quality`'
            New = ''
        }
        @{
            Old = '- `/guiding-refactoring-with-maintainability`'
            New = ''
        }
        @{
            Old = '- `/guiding-refactoring-with-code-health`'
            New = ''
        }
        @{
            Old = '- `/safeguarding-ai-generated-code`'
            New = ''
        }
        @{
            Old = '- `/workflow guidance`'
            New = ''
        }
        @{
            Old = '- `/documentation-html`'
            New = ''
        }
        @{
            Old = '`scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`'
            New = 'repository CI helper scripts, when present'
        }
        @{
            Old = '`.github/workflows/Tests.yml`'
            New = 'workflow files, when present'
        }
        @{
            Old = '`.github/workflows/Publish.yml`'
            New = 'release workflow files, when present'
        }
        @{
            Old = '`.github/workflows/*.yml`'
            New = 'workflow files, when present'
        }
        @{
            Old = '`.github/workflows/`'
            New = 'workflow files, when present'
        }
        @{
            Old = '`.github/actions/`'
            New = 'reusable workflow actions, when present'
        }
        @{
            Old = '.github/workflows/Tests.yml,.github/actions/check-coverage/action.yml'
            New = ''
        }
        @{
            Old = '.github/workflows/Publish.yml,'
            New = ''
        }
        @{
            Old = 'src/public/InvokeNovaRelease.ps1,src/public/PublishNovaModule.ps1,src/public/UpdateNovaModuleVersion.ps1'
            New = 'src/public/*.ps1'
        }
        @{
            Old = 'docs/*.html'
            New = 'project docs'
        }
        @{
            Old = '`project docs`'
            New = 'project docs'
        }
        @{
            Old = 'website docs'
            New = 'project docs'
        }
        @{
            Old = 'website documentation'
            New = 'project documentation'
        }
        @{
            Old = 'NovaCommandModel*.Tests.ps1'
            New = '*Command*.Tests.ps1'
        }
        @{
            Old = 'ArchitectureGuardrails.Tests.ps1'
            New = '*Architecture*.Tests.ps1'
        }
        @{
            Old = '- CI coverage is generated by `./scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`.'
            New = '- CI coverage is generated by the repository-specific CI helper when one exists.'
        }
        @{
            Old = '- The Cobertura artifact is reused by the quality tooling PR coverage gate and by the develop/manual quality tooling analysis flow.'
            New = '- Coverage artifacts should stay compatible with the repository quality flow when one exists.'
        }
        @{
            Old = '- workflow files, when present - repository workflow automation, when present'
            New = '- workflow files - repository workflow automation, when present'
        }
        @{
            Old = '- reusable workflow actions, when present - reusable workflow actions, when present'
            New = '- reusable workflow actions - reusable workflow actions, when present'
        }
        @{
            Old = '- project docs - end-user GitHub Pages content'
            New = '- `docs/` - project documentation'
        }
        @{
            Old = 'applyTo: "tests/**/*.ps1,scripts/build/**/*.ps1,"'
            New = 'applyTo: "tests/**/*.ps1,scripts/build/**/*.ps1"'
        }
        @{
            Old = 'applyTo: "src/**/*.ps1,tests/**/*.ps1,scripts/**/*.ps1,run.ps1,reload.ps1"'
            New = 'applyTo: "src/**/*.ps1,tests/**/*.ps1,scripts/**/*.ps1,reload.ps1"'
        }
        @{
            Old = 'applyTo: "src/**/*.ps1,scripts/**/*.ps1,run.ps1,reload.ps1"'
            New = 'applyTo: "src/**/*.ps1,scripts/**/*.ps1,reload.ps1"'
        }
        @{
            Old = '- Use these rules when writing or reviewing `src/**/*.ps1`, `scripts/**/*.ps1`, `run.ps1`, and `reload.ps1`.'
            New = '- Use these rules when writing or reviewing `src/**/*.ps1`, `scripts/**/*.ps1`, and `reload.ps1`.'
        }
        @{
            Old = 'quality tooling tooling'
            New = 'quality tooling'
        }
        @{
            Old = '- Must not mix PowerShell cmdlet UX and `nova` CLI UX.'
            New = ''
        }
        @{
            Old = ', and the `nova` CLI routing model.'
            New = '.'
        }
        @{
            Old = '- Run `./run.ps1`'
            New = '- Run the repository quality loop when one exists'
        }
        @{
            Old = '- local quality loop: `pwsh -NoLogo -NoProfile -File ./run.ps1`'
            New = '- local quality loop: use the repository quality wrapper when one exists; otherwise run ScriptAnalyzer, build, and `Test-NovaBuild` in the documented project order'
        }
        @{
            Old = 'If `run.ps1` or `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` reports findings, fix them before review, handoff, or commit. Do not treat a failing local quality loop as an acceptable stopping point.'
            New = 'If the repository quality loop or `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` reports findings, fix them before review, handoff, or commit. Do not treat a failing validation run as an acceptable stopping point.'
        }
        @{
            Old = '    - full local loop: `./run.ps1`'
            New = '    - full local loop: the repository quality wrapper, when present'
        }
        @{
            Old = '- Prefer one focused analyzer run on the changed files while iterating, then rerun `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`, then `./run.ps1` before handoff.'
            New = '- Prefer one focused analyzer run on the changed files while iterating, then rerun `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`, then the repository quality loop before handoff when the project defines one.'
        }
        @{
            Old = 'Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and `./run.ps1`'
            New = 'Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and the repository quality loop, when present'
        }
        @{
            Old = 'Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and the repository quality loop, when present for normal analyzer loops; use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repository-approved settings.'
            New = 'Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and the repository quality loop, when present, for normal analyzer loops; use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repository-approved settings.'
        }
        @{
            Old = 'If `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings'
            New = 'If the repository quality loop or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings'
        }
        @{
            Old = 'reported by `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1`'
            New = 'reported by the repository quality loop or `Invoke-ScriptAnalyzerCI.ps1`'
        }
        @{
            Old = 'from `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1`'
            New = 'from the repository quality loop or `Invoke-ScriptAnalyzerCI.ps1`'
        }
        @{
            Old = '`run.ps1`-style local checks ordered as ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Test-NovaBuild`.'
            New = 'local quality checks ordered as ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Test-NovaBuild` when the project defines a combined wrapper.'
        }
        @{
            Old = 'Resolve any ScriptAnalyzer findings that `./run.ps1` reports before handoff.'
            New = 'Resolve any ScriptAnalyzer findings reported by the repository quality loop before handoff.'
        }
        @{
            Old = '4. After meaningful steps, run `./run.ps1` (analyzer → build → `Test-NovaBuild`).'
            New = '4. After meaningful steps, run the repository quality loop when present (typically analyzer → build → `Test-NovaBuild`).'
        }
        @{
            Old = 'or GitHub release automation.'
            New = 'or release automation.'
        }
        @{
            Old = 'a GitHub issue-ready change design'
            New = 'a tracker-ready change design'
        }
        @{
            Old = 'an issue-ready change design'
            New = 'a tracker-ready change design'
        }
        @{
            Old = 'fully issue-ready'
            New = 'fully tracker-ready'
        }
        @{
            Old = 'and a GitHub issue draft'
            New = 'and an issue/work item draft'
        }
        @{
            Old = 'a GitHub issue draft'
            New = 'an issue/work item draft'
        }
        @{
            Old = 'GitHub issue draft'
            New = 'issue/work item draft'
        }
        @{
            Old = 'GitHub issue'
            New = 'issue/work item'
        }
        @{
            Old = 'issue-ready change design'
            New = 'tracker-ready change design'
        }
        @{
            Old = 'issue drafting'
            New = 'issue/work item drafting'
        }
        @{
            Old = 'paste-ready GitHub text'
            New = 'paste-ready tracker text'
        }
        @{
            Old = '- `pwsh -NoLogo -NoProfile -File ./run.ps1` before completion'
            New = '- the repository quality loop before completion'
        }
        @{
            Old = '- `pwsh -NoLogo -NoProfile -File ./run.ps1`'
            New = '- the repository quality loop, when present'
        }
        @{
            Old = '- `./scripts/build/ci/Invoke-{{ProjectName}}CI.ps1 -OutputDirectory ./artifacts`'
            New = ''
        }
        @{
            Old = '- Preserve the distinction between PowerShell cmdlet UX and `nova` CLI UX.'
            New = ''
        }
        @{
            Old = '- Do not modify GitHub Actions release automation casually; `Publish.yml` mutates `main` and `develop`.'
            New = ''
        }
        @{
            Old = '- Do not bypass warnings or guards silently; Nova uses explicit `-OverrideWarning` / `--override-warning`.'
            New = ''
        }
        @{
            Old = '- Preserve the distinction between public PowerShell cmdlets and `% nova` CLI behavior.'
            New = ''
        }
        @{
            Old = '- For step-by-step refactoring of unhealthy files, use the `building-maintainable-code` and `guiding-refactoring-with-code-health` skills together: the first picks the right guideline, the second runs measured maintainability checks between steps.'
            New = '- For step-by-step refactoring of unhealthy files, use the `building-maintainable-code` skill for checks between steps.'
        }
        @{
            Old = ', `codescene-quality`, `safeguarding-ai-generated-code`'
            New = ''
        }
        @{
            Old = '`codescene-quality`, `safeguarding-ai-generated-code`, '
            New = ''
        }
        @{
            Old = ', `codescene-quality`, `workflow guidance`, `guiding-refactoring-with-code-health`, `safeguarding-ai-generated-code`'
            New = ''
        }
        @{
            Old = '- a `code_health_review`, reviewer, or `./run.ps1` run flags maintainability problems'
            New = '- a reviewer or the repository quality loop flags maintainability problems'
        }
        @{
            Old = '- measuring or driving a single file''s score across steps — use `guiding-refactoring-with-code-health` for that'
            New = '- measuring or driving a single file''s score across steps — use the step-by-step workflow below for that'
        }
        @{
            Old = '. For risk-bearing files, also run `code_health_review` from the `safeguarding-ai-generated-code` skill.'
            New = '.'
        }
        @{
            Old = 'CommandInfo  = Get-Command -Module NovaModuleTools'
            New = 'CommandInfo  = Get-Command -Module {{ProjectName}}'
        }
        @{
            Old = '- Treating maintainability 9.x as the goal. Aim for 10.0 on touched files in this repository.'
            New = ''
        }
        @{
            Old = '- `code_health_review` and `pre_commit_code_health_safeguard` from `safeguarding-ai-generated-code` before suggesting a commit'
            New = ''
        }
        @{
            Old = '- `code_health_review` paired with `guiding-refactoring-with-code-health` when iterating on a single unhealthy file'
            New = ''
        }
        @{
            Old = ', or `nova` CLI route naming conventions.'
            New = '.'
        }
    )
}
