# NovaModuleTools | [![CodeScene general](https://codescene.io/images/analyzed-by-codescene-badge.svg)](https://codescene.io/projects/78904) ![WorkFlow Status][WorkFlowStatus]

NovaModuleTools is an enterprise-focused evolution of ModuleTools, designed for large-scale PowerShell projects with a
strong emphasis on structure, maintainability, and automated CI/CD pipelines that make up the Nova workflow.

This `README.md` is intentionally a **short contributor entry page**. Detailed developer guidance lives under
`developer-docs/` and should not be duplicated here.

If you are looking for **user guides** to NovaModuleTools, proceed to https://www.novamoduletools.com/ for more
information.

## Documentation split

| Audience                     | Location          | Purpose                                                   |
|------------------------------|-------------------|-----------------------------------------------------------|
| Contributors and maintainers | GitHub repository | Build, test, debug, document, and release NovaModuleTools |
| End users                    | GitHub Pages      | Install NovaModuleTools and follow guided usage workflows |

## Contributor docs in this repository

- `CONTRIBUTING.md` — contribution expectations and review checklist
- `developer-docs/README.md` — developer documentation hub
- `developer-docs/development-workflow.md` — local setup, build, test, reload, and quality loop
- `developer-docs/repository-structure.md` — repository architecture and ownership
- `developer-docs/ci-cd-and-release.md` — CI, semantic-release, and publish pipeline responsibilities

## End-user docs on GitHub Pages

- `docs/index.html` — landing page
- `docs/getting-started.html` — install and first project setup
- `docs/core-workflows.html` — scaffold, build, test, bump, and release flows
- `docs/working-with-modules.html` — import and reload usage
- `docs/troubleshooting.html` — common issues and fixes
- `docs/advanced.html` — advanced usage and CI/CD-oriented user guidance

## Repository overview

High-level responsibilities:

- `src/public/` — public cmdlets
- `src/private/` — internal helpers
- `src/resources/` — packaged resources
- `tests/` — Pester coverage and test helpers
- `scripts/` — build, CI, and release automation
- `docs/NovaModuleTools/en-US/` — PlatyPS command-help source

For structure and ownership details, use `developer-docs/repository-structure.md`.

## Start here as a contributor

1. Read `CONTRIBUTING.md`
2. Use `developer-docs/README.md` as the developer docs hub
3. Follow `developer-docs/development-workflow.md` for local build, test, reload, and quality flows
4. Use `developer-docs/ci-cd-and-release.md` when your change touches workflows, release automation, or publishing

## Documentation ownership rules

- Keep detailed contributor workflow documentation under `developer-docs/`
- Keep `README.md` short and navigation-focused
- Keep `docs/NovaModuleTools/en-US/*.md` focused on command-help source material
- Keep `docs/*.html` focused on end-user guides
- Do not duplicate the same workflow or setup prose across `README.md` and `developer-docs/`

## License

This project is licensed under the MIT License. See `LICENSE` for details.

[WorkFlowStatus]: https://img.shields.io/github/actions/workflow/status/stiwicourage/NovaModuleTools/Tests.yml
