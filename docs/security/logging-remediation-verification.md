# Logging remediation verification

Verification date: 7 August 2026

Only synthetic secret markers were used. No credentials or personal data were stored as evidence.

## Source and automated checks

| Check | Result | Notes |
| --- | --- | --- |
| Safe logging source guard | Passed | No full-object Dio logger, unsafe logging option or direct application logging sink found. |
| `flutter analyze` | Passed | No issues found. |
| Focused logging regression suite | Passed | 10 tests passed. |
| Complete Flutter suite | Passed | 147 tests passed. |
| Dependency search | Passed | `pretty_dio_logger` is absent from the resolved dependency graph. |
| Source search | Passed | No `PrettyDioLogger`, unsafe header/body option or package reference remains. |
| Diff whitespace check | Passed | No whitespace errors found. |

The focused suite covers mixed-case bearer headers, captured debug output, nested request and error data, query strings, URI fragments, dynamic route values, unknown endpoints, redirects, the two-attempt retry failure path, multipart fields and filenames, exact approved metadata, and a failing logging sink.

## Build checks

| Artefact | Result | Notes |
| --- | --- | --- |
| Android debug APK | Built | Clean build completed. |
| Android profile APK | Built | Clean build completed. |
| Android release APK | Built, unsigned | Version `0.1.1`, build `9`. No local release signing key was available. |
| Android release manifest | Inspected | Application ID `uk.org.cherry.app`; required network permission is present. |
| Android profile and release binary marker search | Passed | Removed logger names and the synthetic secret marker were absent. |
| iOS debug device app, no codesign | Built | Xcode build completed. |
| iOS profile device app, no codesign | Blocked | Xcode requires a Development Team and provisioning profile for the deployable artefact. |
| iOS release device app, no codesign | Blocked | Xcode requires a Development Team and provisioning profile for the deployable artefact. |

Android builds reported an existing future Kotlin Gradle Plugin migration warning for third-party plugins. It did not fail the builds and is not caused by this remediation.

## Required manual checks

The following checks have not been completed and remain advisory-closure requirements:

- sign the Android release with cherry's release key;
- clean-install debug, profile and signed-release Android artefacts on a physical device;
- exercise the authentication, profile, donation, upload, order, checkout, Stripe, retry, redirect, sign-out and account-switching paths;
- inspect unfiltered and process-specific Logcat for credentials and personal data;
- select the correct Apple Development Team, build signed iOS artefacts and inspect Xcode, unified and device logs;
- complete the historical exposure and session-revocation assessment in `logging-incident-assessment.md`;
- request reporter retesting where practical.

Source tests and successful builds do not prove the behaviour of third-party SDKs on physical devices.
