---
applyTo: "src/**/*.ps1,tests/**/*.ps1"
---

# Agentic code quality matrix

## Purpose

Use this file as the best-effort code quality matrix for generated and reviewed code in this repository.

The matrix translates the repository's preferred `src/**` and `tests/**` maintainability thresholds into agent guidance, so agents can shape code toward the expected quality from the start. This guidance does **not** require a `.codescene/code-health-rules.json` file in generated projects.

## How to use the matrix

- Treat warning thresholds as the default design ceiling for new or heavily changed code.
- Treat alert thresholds as refactor-now signals for new or heavily changed code.
- When a threshold has no alert value, stay below the warning threshold by default.
- When a threshold is marked `not used`, do not optimize around it; focus on the other limits instead.
- If a change must exceed a threshold, call it out in the handoff and explain the trade-off clearly.

## Source code matrix (`**/src/**`)

| Threshold                                          | Warning          | Alert | Best-effort authoring guidance                                                                               |
|----------------------------------------------------|------------------|-------|--------------------------------------------------------------------------------------------------------------|
| `constructor_max_arguments`                        | `4`              | —     | Extract parameter objects or workflow-context objects before constructors exceed four inputs.                |
| `file_mean_cyclomatic_complexity_warning`          | `26`             | —     | Split growing files or extract helpers before the file's average complexity drifts past this point.          |
| `function_complex_conditional_branches_warning`    | `6`              | `11`  | Break up long boolean expressions before complex branch conditions become hard to read.                      |
| `function_cyclomatic_complexity_warning`           | `6`              | `11`  | Extract helpers and flatten control flow before a function becomes a local hotspot.                          |
| `function_duplication_min_lines_of_code_for_check` | `6 lines`        | —     | Treat six or more repeated lines as an extraction candidate.                                                 |
| `function_duplication_min_similarity_percentage`   | `89% similarity` | —     | Consolidate near-copy/paste logic even when names or literals differ slightly.                               |
| `function_lines_of_code_warning`                   | `16`             | `31`  | Keep new or heavily changed functions short; extract helpers before they drift beyond the warning threshold. |
| `function_max_arguments`                           | `4`              | —     | Introduce context objects, parameter objects, or helper abstractions before functions exceed four inputs.    |
| `function_nesting_depth_warning`                   | `6`              | —     | Flatten nested control flow early; do not let new logic grow into deep indentation towers.                   |

## Test code matrix (`**/tests/**`)

| Threshold                                          | Warning    | Alert                        | Best-effort authoring guidance                                                                                           |
|----------------------------------------------------|------------|------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| `constructor_max_arguments`                        | `5`        | —                            | Keep test helper constructors simple; prefer factory helpers or setup objects before they sprawl.                        |
| `file_lines_of_code_for_warning`                   | `1000`     | `5000` (`critical`: `10000`) | Split oversized test files by source ownership or behavior before they become hard to review.                            |
| `file_mean_cyclomatic_complexity_warning`          | `4`        | —                            | Refactor test helpers or `BeforeAll` setup when a file becomes too branch-heavy overall.                                 |
| `file_primitive_obsession_percentage_for_warning`  | `0.3`      | —                            | Extract builders, fixtures, or named data objects when tests lean too heavily on raw strings, ints, and hashtables.      |
| `function_bumpy_road_bumps_for_warning`            | `2`        | —                            | Keep each test focused on one logical path; extract setup helpers when the flow breaks into many chunks.                 |
| `function_bumpy_road_nesting_level_depth`          | `2`        | —                            | Keep test logic shallow and linear; avoid nested setup trees in individual test functions.                               |
| `function_complex_conditional_branches_warning`    | `2`        | `10`                         | Prefer separate tests or helper functions over highly conditional test logic.                                            |
| `function_cyclomatic_complexity_warning`           | `9`        | `100`                        | Split test helpers or parameterized cases before one test function turns into control-flow-heavy code.                   |
| `function_embedded_content_lines_of_code_warning`  | `not used` | `not used`                   | Do not optimize for this metric; focus on the other thresholds instead.                                                  |
| `function_lines_of_code_warning`                   | `70`       | `500`                        | Keep new or heavily changed test functions compact; extract setup and assertion helpers when they grow too large.        |
| `function_max_arguments`                           | `4`        | —                            | Keep helper/test function signatures tight; prefer fixtures or context objects over long parameter lists.                |
| `function_nesting_depth_warning`                   | `4`        | —                            | Flatten nested assertions and setup paths before they become difficult to follow.                                        |
| `unit_test_consecutive_asserts_for_large_block`    | `4`        | —                            | Split assertion helpers or use richer comparison helpers before an assertion block grows past four consecutive asserts.  |
| `unit_test_suite_number_of_large_assertion_blocks` | `4`        | —                            | If a suite accumulates multiple large assertion blocks, extract reusable assertion helpers instead of copy/paste growth. |

## Review expectations

- PowerShell implementation agents should use the source code matrix while shaping `src/**/*.ps1`.
- Test-focused agents should use the test code matrix while shaping `tests/**/*.ps1`.
- Review agents should flag new or heavily changed code that ignores the warning thresholds without a clear, justified reason.
