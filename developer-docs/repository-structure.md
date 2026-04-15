# Repository structure

This guide explains how the NovaModuleTools repository is organized and what each major area owns.

## See also

- [Developer docs hub](./README.md)
- [Contribution guide](../CONTRIBUTING.md)
- [Development workflow](./development-workflow.md)
- [CI/CD and release automation](./ci-cd-and-release.md)

## Top-level overview

```text
.
├── .github/                    # GitHub Actions workflows
├── developer-docs/             # contributor-focused documentation
├── docs/                       # GitHub Pages HTML + PlatyPS help markdown
├── scripts/                    # build, CI, and release automation
├── src/                        # production PowerShell code and packaged resources
├── tests/                      # Pester suites and reusable test helpers
├── project.json                # NovaModuleTools project definition
├── package.json                # semantic-release tooling for current publish automation
└── CHANGELOG.md                # release notes and unreleased change tracking
```

## Source code layout

### `src/public/`

Public cmdlets that make up the NovaModuleTools API surface, for example:

- `Invoke-NovaBuild`
- `Test-NovaBuild`
- `New-NovaModule`
- `Update-NovaModuleVersion`

### `src/private/`

Internal implementation helpers grouped by concern, including:

- `build/`
- `cli/`
- `quality/`
- `release/`
- `scaffold/`
- `shared/`

Keep new helpers small, focused, and near the concern they belong to.

### `src/resources/`

Packaged resources that ship with the module, including:

- schemas
- the standalone `nova` launcher
- the packaged example project under `src/resources/example/`

The example project is both a shipped resource and a maintained working reference.

## Test layout

### `tests/`

Repository-level Pester coverage for:

- public command behavior
- internal helper behavior
- build and packaging expectations
- CI/report generation flows

Shared test utilities live alongside the tests, for example:

- `GitTestSupport.ps1`
- `BuildOptions.TestSupport.ps1`
- `NovaCommandModel.TestSupport.ps1`

## Documentation layout

### [`README.md`](../README.md) and [`CONTRIBUTING.md`](../CONTRIBUTING.md)

These are the top-level GitHub entry points for contributors and maintainers.

### [`developer-docs/`](./README.md)

Structured contributor documentation for repository workflows, architecture, and CI/release behavior.

### `docs/`

This folder has two different responsibilities that must stay separated by file type:

- `docs/*.html` → GitHub Pages end-user guides
- `docs/NovaModuleTools/en-US/*.md` → PlatyPS command-help source

The build treats markdown under `docs/` as help input, so general-purpose markdown docs should not be added here.

## Scripts and automation

### `scripts/build/`

Build, analyzer, and CI helper scripts.

### `scripts/release/`

Release preparation and publish helpers used by the current release workflow.

These scripts are currently part of a wider GitHub Actions + semantic-release pipeline, not a standalone replacement for
it.

