---
applyTo: "**"
---

# Repository conventions

## Purpose

Canonical rule source for cross-cutting NovaModuleTools conventions that apply to every change. Topic-specific rules live in the other `.instructions.md` files; this file owns the rules that do not belong to one topic.

## Project layering

- Treat `project.json` as the source of truth for project metadata, build output, package settings, and release settings.
- Treat `project.json` `Manifest.PowerShellHostVersion` as the compatibility target for PowerShell code, tests, and examples. If a project targets `5.1`, do not introduce PowerShell 7.x-only syntax, cmdlets, parameters, or APIs unless the work explicitly adds guarded compatibility handling.
- Use Nova commands and repository wrappers for build, test, package, and release workflows; do not replace them with ad hoc PowerShell module build scripts.
- Do not create or maintain hand-written module `.psm1` or module `.psd1` files in source; Nova generates the built module root and manifest under `dist/NovaModuleTools/` from `project.json` and `src/**/*.ps1`.
- Preserve the distinction between PowerShell cmdlet UX and `nova` CLI UX.

## File ownership

- `src/public/` files own exactly one top-level function each. The file name matches the function name.
- `src/private/` files expose at most one externally called function per file. Additional helpers may stay as sibling top-level functions in the same file when they belong to that entry function. The file name matches the externally called function.
- PowerShell functions must not declare nested functions inside their bodies.
- Prefer existing helpers and support files over ad hoc duplication.
- Do not add raw infrastructure calls in public commands when an adapter/helper layer already exists.

## Validation expectations

Use the smallest validation set that proves the change, then run the repository quality loop before finishing code work:

- local quality loop: `pwsh -NoLogo -NoProfile -File ./run.ps1`
- test validation: `Invoke-NovaTest` for unit-test validation, then `Test-NovaBuild` for build-validation integration coverage
- analyzer only: `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`
- CI-parity coverage flow: `./scripts/build/ci/Invoke-NovaModuleToolsCI.ps1 -OutputDirectory ./artifacts`

If `run.ps1` or `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` reports findings, fix them before review, handoff, or commit. Do not treat a failing local quality loop as an acceptable stopping point.

When CodeScene tooling is available:

- run the pre-commit safeguard on AI-touched changes before suggesting a commit
- run a branch/change-set analysis before suggesting a PR or declaring a larger change ready
- if CodeScene reports a regression, refactor instead of treating the work as done

If CodeScene tooling is unavailable locally, continue with the normal repository validation flow; pull requests and CI remain the effective gate.

For documentation-only changes, executable validation may be skipped if no code path or workflow behavior changed.

## Documentation review

- Review `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, and `RELEASE_NOTE.md` after every meaningful change.
- Update tests when behavior changes.

## File formatting rule

- Before handoff, review every changed or created text file and ensure it ends with exactly one trailing newline and no extra blank lines at the bottom.
- Do not leave any edited file with extra blank lines at the end, even if the functional code change is already complete.
- Do not alter internal whitespace just to enforce the trailing newline rule.

## Safety constraints

- Do not publish packages, create tags, or push changes unless explicitly requested.
- Do not modify GitHub Actions release automation casually; `Publish.yml` mutates `main` and `develop`.
- Do not bypass warnings or guards silently; Nova uses explicit `-OverrideWarning` / `--override-warning`.

## Commit message guidance

- When you are asked to suggest or prepare a commit message, answer in English.
- Use Conventional Commit format.
- Extract the ticket number from `$GIT_BRANCH_NAME` and render it as `(#<number>)` immediately after the type when one is available.
- If `$GIT_BRANCH_NAME` starts with `hotfix/` or `bug/`, use `fix` as the type even when the implementation looks more like a feature. Use `fix!` if that branch change is also breaking.
- Otherwise estimate the type from the actual change:
    - `feat` for feature work
    - `fix` for bug fixes
    - `feat!` for breaking feature work
    - `fix!` for breaking fixes
- Keep the subject short, specific, and free of unnecessary detail.
- If you provide multiple commit message suggestions or summarize multiple change options, use bullet points.
- Do not invent a ticket number when `$GIT_BRANCH_NAME` does not contain one.

## Markdown output

When the output is intended to be copied as Markdown from the UI or written to a Markdown file, follow the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`). Apply that rule especially to release summaries, review summaries, contributor-facing Markdown docs, prompt output, and PR-template-shaped text.
