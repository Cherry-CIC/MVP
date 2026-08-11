# Sensitive logging incident assessment

This record supports the private security advisory. Do not add tokens, personal data, complete logs or unredacted screenshots.

## Confirmed facts

- The vulnerable source was present in application version `0.1.0+8`.
- `PrettyDioLogger` received complete Dio network objects in every build mode.
- Request headers, bodies, response bodies and errors were enabled.
- The `/api/auth/profile` exposure was observed while testing PR #466. PR #466 did not introduce the logger.
- The source remediation assigns patched application version `0.1.1+9`.

## Assessment still required before advisory closure

- [ ] Identify every distributed build and version containing the logger.
- [ ] Identify the developers and testers who generated logs.
- [ ] Check CI artefacts, issues, screenshots, recordings, chat and shared files for unredacted evidence.
- [ ] Establish whether any log was accessible outside the intended team.
- [ ] Establish which user sessions or tokens could have appeared.
- [ ] Check for evidence of unauthorised use.
- [ ] Record a proportionate session or refresh-token revocation decision.
- [ ] Record the personal-data incident decision and obtain specialist advice if third-party access is plausible.
- [ ] Reassess advisory severity and CVSS using the evidence above.
- [ ] Ask the reporter to retest where practical.

## Artefact verification still required

- [ ] Android debug build tested after a clean physical-device install.
- [ ] Android profile build tested after a clean physical-device install.
- [ ] Android signed-release build tested after a clean physical-device install.
- [ ] Unfiltered and process-specific Logcat reviewed from startup through sign-out.
- [ ] Authentication, profile, product, search, order, donation, upload, checkout, Stripe, validation, retry, redirect and account-switching paths exercised.
- [ ] iOS Xcode console, unified logging and device console reviewed, or the gap explicitly recorded.
- [ ] Only redacted evidence retained.

The source patch and automated tests cannot complete these operational and device checks on their own.
