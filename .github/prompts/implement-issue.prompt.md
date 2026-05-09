# Implement NovaModuleTools issue

Implement the issue in the NovaModuleTools repository using the repository-local instructions and skills.

## Required inputs

- Issue number or issue text
- Relevant files or failing behavior
- `$GIT_BRANCH_NAME` when a commit message suggestion is needed

## Required process

1. Read `README.md`, `CONTRIBUTING.md`, and `.github/pull_request_template.md`.
2. Inspect the relevant public command, matching private helper domain, tests, and docs.
3. If the issue is release-, workflow-, or coverage-related, also inspect the matching `.github/workflows/*.yml` and
   `scripts/build/ci/*.ps1` files.
4. Implement the smallest maintainable fix.
5. Add or update tests.
6. Review `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, help docs, and `docs/*.html` as applicable.
7. If a commit message is requested, derive it from `$GIT_BRANCH_NAME` and the implemented change using the repository's
   Conventional Commit rules.
8. Run the relevant validation, then summarize what changed, why, and how it was verified.
9. If that summary is returned as Markdown or copy-ready UI output, format it according to
   `markdown-authoring.skill.md`.

## Repository-specific reminders

- Keep PowerShell cmdlet UX and `nova` CLI UX distinct.
- Do not silently bypass warnings or release safeguards.
- Prefer reuse of existing helpers and test-support files over duplication.
- Follow `markdown-authoring.skill.md` when the issue summary or final handoff is intended to be pasted as Markdown.
- Commit message suggestions must:
    - be in English
    - use Conventional Commit format
    - extract the ticket number from `$GIT_BRANCH_NAME` and format it as `(#<number>)` when available
    - force `fix` / `fix!` when `$GIT_BRANCH_NAME` starts with `hotfix/` or `bug/`
    - otherwise estimate `feat`, `fix`, `feat!`, or `fix!` from the actual change
    - stay short and not overly verbose
    - use bullet points when presenting multiple commit message options or multiple grouped changes
