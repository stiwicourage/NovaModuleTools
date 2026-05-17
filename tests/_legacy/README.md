# `tests/_legacy/` — retired coverage-bucket suites

These files were the broad pre-migration coverage buckets (`CoverageGaps*`,
`CoverageCompletion*`, `Remaining*Coverage*`, broad `NovaCommandModel*`)
that existed before each `src/**/*.ps1` helper got its own mirrored test
file under `tests/public/` and `tests/private/<domain>/`.

After the source-mirrored test migration (issues #200 – #206), their
assertions are covered by the mirrored tests. They are kept here, with
the `.Tests.ps1` suffix renamed to `.LegacyReference.ps1`, so:

- Pester discovery (which only picks up `*.Tests.ps1`) skips them and they
  no longer run as part of `Test-NovaBuild` or the repository quality
  loop.
- If a behavior is later found to be missing from the mirrored suites,
  the original assertion is still readable here as a reference and can
  be ported to the right mirrored or cross-cutting test home.

A second batch of legacy dist-requiring integration and guardrail tests
(`BuildOptions`, `CiCoverage`, `CliHelperCoverage`, `CliSharedParser`,
`Module`, `OutputFiles`, `PackageLatestPolicy`, `PreambleBuild`,
`UpdateNotification`) was retired here too. They imported the built
`dist/NovaModuleTools` module and depended on a prior `Invoke-NovaBuild`,
which conflicted with the source-mirrored test model where `nova test`
must run directly against `src/**/*.ps1` without a build step.
Their behavior is now covered by the mirrored tests for each touched
helper, so the assertions are preserved as references rather than as
discovered tests.

These files are not maintained. They will be deleted once coverage
measurement is re-enabled and confirms no regression against the
mirrored test layout.
