## Summary

- What changed?
- Why was this change needed?
- Link the issue, discussion, or follow-up work (for example `Closes #123`).

## Affected area

- [ ] `nova` CLI or command routing
- [ ] Public PowerShell cmdlet behavior
- [ ] Scaffolding or `project.json` handling
- [ ] Build, test, or quality flow
- [ ] Publish or release automation
- [ ] Documentation only
- [ ] `src/resources/example/`
- [ ] Other

## Review guidance

- Highlight the main code path or workflow reviewers should start with.
- Call out any trade-offs, follow-up work, or known limitations.

## Validation

- [ ] `Invoke-NovaBuild`
- [ ] `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`
- [ ] `Test-NovaBuild`
- [ ] Not run because this change is docs-only or otherwise does not affect executable behavior

Validation notes:

```text
Paste the most relevant commands, outputs, or justification here.
```

## Documentation and release follow-up

- [ ] `README.md` reviewed and updated if contributor workflow, architecture, or automation changed
- [ ] `CHANGELOG.md` reviewed and updated if the change matters to users, maintainers, or contributors
- [ ] `docs/NovaModuleTools/en-US/` help updated if a public command changed
- [ ] `docs/*.html` updated if end-user guidance changed
- [ ] `src/resources/example/` reviewed and updated if the real-world project layout or workflow changed
- [ ] No documentation or example updates were needed

## Compatibility and risk

- [ ] No breaking change
- [ ] Breaking change
- [ ] Security-sensitive change

Risk, rollout, or rollback notes:

```text
Describe compatibility impact, migration notes, or rollback steps if they matter.
```

> [!IMPORTANT]
> Do not use a public pull request to disclose a vulnerability before coordinated handling.
> Use the private reporting path in `SECURITY.md` for new security issues.
