# Application logging policy

## Purpose

cherry logs only the minimum fixed metadata needed to understand whether an operation succeeded or failed. Debug builds are not trusted environments. Release stripping is an additional safeguard, not the security control.

## Allow-list

Application code may log only:

- a fixed event name from `AppLogEvent`;
- a fixed level from `SafeLogLevel`;
- an approved HTTP method;
- a fixed HTTP operation name from `SafeHttpOperation`;
- an HTTP status code;
- elapsed milliseconds;
- a fixed error category;
- a non-sensitive count.

Unknown HTTP endpoints must be recorded as `unclassified_request`. They must never fall back to the original URL or path.

All application diagnostics must use `SafeLog`. HTTP diagnostics must pass a `SafeHttpLogRecord` to the sink. The sink cannot accept a Dio request, response or exception object.

## Prohibited data

Never log:

- bearer, ID, refresh or access tokens;
- cookies, session identifiers, passwords or authentication codes;
- names, email addresses, telephone numbers, user identifiers or postal addresses;
- payment secrets, payment method details or provider responses;
- API keys or credentials;
- identifiable order, donation or charity administration data;
- request or response headers, bodies, query parameters, fragments or complete URLs;
- arbitrary or dynamic path segments;
- redirects or redirect destinations;
- multipart fields, uploaded file paths, filenames or private image URLs;
- complete request, response or exception objects;
- raw exception messages or `toString()` output.

Redaction is not the primary control. Sensitive values must not reach the logging layer.

## Temporary diagnostics

Detailed body logging must not be added to a normal application build. If it is exceptionally required, use a separately reviewed endpoint and field allow-list, synthetic or controlled test data, and a time-limited change that cannot ship in a release.

## Review and testing

Every pull request must pass the safe logging source guard and focused regression tests. Reviewers should treat those checks as supporting safeguards, not proof that third-party SDKs or release artefacts are safe.

Android debug, profile and signed-release artefacts must be checked on a physical device before the security advisory is closed. iOS console and unified logging should also be checked because the Dart code is shared. Store only redacted evidence.

## Environment configuration

Anything bundled in `.env` is recoverable from the application. Only public client configuration may be included. Server-side credentials must never be shipped in the app.
