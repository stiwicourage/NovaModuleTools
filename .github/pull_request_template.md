## Summary

- What changed?
- Why was this change needed?
- Link the issue, discussion, or follow-up work (for example `Closes #123`).

## Affected area

- [ ] `nova` CLI or command routing
- [ ] Public PowerShell cmdlet behavior
- [ ] Scaffolding or `project.json` handling
- [ ] Build, test, analyzer, coverage, or CI helper flow
- [ ] Package, raw upload, or package metadata workflow
- [ ] Publish, release, semantic-release, or GitHub Actions automation
- [ ] Self-update or notification preference behavior
- [ ] Contributor documentation (`README.md`, `CONTRIBUTING.md`, repository workflow docs)
- [ ] End-user docs (`docs/*.html`)
- [ ] Command help (`docs/NovaModuleTools/en-US/*.md`)
- [ ] `src/resources/example/`
- [ ] Dependency or manifest changes (`package.json`, workflow dependencies, release tooling)
- [ ] Security-sensitive change
- [ ] Documentation-only change
- [ ] Other

## Review guidance

- Highlight the main code path or workflow reviewers should start with.
- Call out the primary files or folders changed (for example `src/public/`, `src/private/cli/`, `scripts/build/ci/`,
  `.github/workflows/`, `docs/`, or `src/resources/example/`).
- Call out any trade-offs, follow-up work, or known limitations.

## Validation

- [ ] `Invoke-NovaBuild`
- [ ] `Test-NovaBuild`
- [ ] `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`
- [ ] `./scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`
- [ ] Targeted Nova workflow validated (`nova build`, `nova test`, `nova pack`, `nova upload`, `nova publish`,
  `nova release`, `nova update`, `nova notification`, or `nova init` as relevant)
- [ ] Docs/example only; executable validation not needed

Validation notes:

```text
Paste the most relevant commands, outputs, artifact paths, or justification here.
If you skipped checks, explain why.
If package/upload/release behavior changed, note the exact scenario you exercised.
```

## Documentation and release follow-up

- [ ] `README.md` reviewed and updated if contributor workflow, architecture, CI, release, or automation changed
- [ ] `CONTRIBUTING.md` reviewed and updated if contribution expectations or review guidance changed
- [ ] `CHANGELOG.md` reviewed and updated if the change matters to users, maintainers, or contributors
- [ ] `docs/NovaModuleTools/en-US/` help updated if a public command or CLI behavior changed
- [ ] `docs/*.html` updated if end-user workflows or examples changed
- [ ] `src/resources/example/` reviewed and updated if the real-world project layout, package model, or upload workflow
  changed
- [ ] No documentation, changelog, or example updates were needed

## Maintainability, compatibility, and risk

- [ ] Code Health / maintainability impact considered
- [ ] No breaking change
- [ ] Breaking change
- [ ] Security-sensitive change
- [ ] CI, workflow, or release-pipeline impact
- [ ] Dependency-review impact

Risk, rollout, or rollback notes:

```text
Describe compatibility impact, migration notes, rollback steps, or maintainer follow-up if they matter.
Call out workflow-specific risk if this touches package upload, semantic-release, or GitHub Actions.
```

> [!IMPORTANT]
> Do not use a public pull request to disclose a vulnerability before coordinated handling.
> Use the private reporting path in `SECURITY.md` for new security issues.
