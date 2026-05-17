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

These files are not maintained. They will be deleted once coverage
measurement is re-enabled and confirms no regression against the
mirrored test layout.
