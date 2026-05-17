<!--
Thank you for contributing! Please fill in this template to help
reviewers understand and verify your changes.

For security-related fixes, please follow SECURITY.md and contact
the maintainer privately first.
-->

## Summary

<!-- One-paragraph description of what this PR does and why. -->

## Related issue

<!-- e.g. Fixes #123 / Refs #45 / N/A -->

## Type of change

<!-- Mark with [x] all that apply -->

- [ ] `fix` — bug fix (non-breaking change which fixes an issue)
- [ ] `feat` — new feature (non-breaking change which adds functionality)
- [ ] `refactor` — code restructuring without behaviour change
- [ ] `docs` — documentation only
- [ ] `test` — adding or fixing tests
- [ ] `chore` / `build` / `ci` — tooling, build, or CI changes
- [ ] `breaking change` — fix or feature that would cause existing functionality to change

## Which package(s) does this affect?

<!-- Mark with [x] all that apply -->

- [ ] `packages/dao-core` (反代 API)
- [ ] `packages/wam` (切号 WAM)
- [ ] `packages/dao-proxy-min` (提示词反代)
- [ ] tooling / scripts / docs / CI
- [ ] other (please describe)

## How was this tested?

<!--
Describe the tests you ran. At minimum, the full suite should pass:

  node tests/run_all.cjs

If you added or changed behaviour, please add tests in `tests/`.
-->

## Checklist

- [ ] My code follows the existing style in the codebase
- [ ] I have added tests for new behaviour (or explained why not applicable)
- [ ] All existing tests still pass (`node tests/run_all.cjs`)
- [ ] I have updated documentation where relevant
- [ ] I have not introduced new external dependencies (or explained why one was needed)
- [ ] I have not committed any tokens, keys, account credentials, or other secrets
- [ ] I agree to follow this project's [Code of Conduct](../CODE_OF_CONDUCT.md)

## Additional context

<!-- Anything else reviewers should know? Screenshots, logs, design notes, etc. -->
