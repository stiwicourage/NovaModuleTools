# NovaModuleTools PR Description Generator

## Purpose

Generate a complete, high-quality pull request description for NovaModuleTools based on a change summary, commits, or
diff.

The output MUST follow the NovaModuleTools PR template exactly and be concise, precise, and reviewer-focused.

---

## Inputs

- Change description, commit messages, or diff (required)
- Optional: issue number, workflow touched, commands affected

---

## Instructions

Analyze the provided input and:

1. Infer the intent of the change (bugfix, feature, refactor, CI, docs, etc.)
2. Identify impacted areas (CLI, PowerShell, CI/CD, packaging, docs, etc.)
3. Detect validation steps performed (or infer what should have been run)
4. Highlight reviewer entry points (key files, workflows, or commands)
5. Identify risks, breaking changes, or follow-ups

Be pragmatic: if information is missing, make reasonable assumptions but call them out briefly.

---

## Output format

You MUST return the PR description using this exact structure:

---

## Summary

- What changed?
- Why was this change needed?
- Link the issue, discussion, or follow-up work (for example `Closes #123`).

---

## Affected area

Select all relevant:

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

---

## Review guidance

- Highlight the main code path or workflow reviewers should start with.
- Call out the primary files or folders changed (for example `src/public/`, `src/private/cli/`, `scripts/build/ci/`,
  `.github/workflows/`, `docs/`, or `src/resources/example/`).
- Call out any trade-offs, follow-up work, or known limitations.

---

## Validation

Mark relevant checks:

- [ ] `Invoke-NovaBuild`
- [ ] `Test-NovaBuild`
- [ ] `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`
- [ ] `./scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`
- [ ] Targeted Nova workflow validated (`% nova build`, `% nova test`, `% nova merge`, `% nova deploy`,
  `% nova publish`,
  `% nova release`, `% nova update`, `% nova notification`, or `% nova init` as relevant)
- [ ] Docs/example only; executable validation not needed

Validation notes:

```
<Fill with commands, outputs, or justification>
```

---

## Documentation and release follow-up

- [ ] `README.md` reviewed and updated if needed
- [ ] `CONTRIBUTING.md` reviewed and updated if needed
- [ ] `CHANGELOG.md` reviewed and updated if relevant
- [ ] Command help updated if CLI or cmdlets changed
- [ ] End-user docs updated if workflows changed
- [ ] Examples updated if real usage changed
- [ ] No documentation updates needed

---

## Maintainability, compatibility, and risk

- [ ] Code Health / maintainability impact considered
- [ ] No breaking change
- [ ] Breaking change
- [ ] Security-sensitive change
- [ ] CI, workflow, or release-pipeline impact
- [ ] Dependency-review impact

Risk, rollout, or rollback notes:

```
<Describe impact, migration, rollback, or follow-up>
```

---

## Style rules

- Be concise and technical (no fluff)
- Prefer bullet points over paragraphs
- Be explicit about workflows (especially CI/CD and release flow)
- Always think like a reviewer: "Where do I start reading?"
- Never leave sections empty — infer or justify

---

## Example invocation

Generate PR description from:

- Commit: "fix: resolve ambiguous -w CLI parameter parsing"
- Files changed: `src/private/cli/Invoke-NovaCli.ps1`

---

## Expected behavior

The output should be ready to paste directly into a GitHub PR without edits.