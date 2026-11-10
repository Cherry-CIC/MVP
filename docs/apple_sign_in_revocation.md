# Sign in with Apple Token Revocation & Account Deletion

## Overview
According to Apple App Store Review Guidelines (Guideline 5.1.1(v)) and Apple Developer Technical Note [TN3194](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple), apps that support **Sign in with Apple** must revoke the user's authorization tokens with Apple whenever the user requests account deletion.

This repository implements token revocation during account deletion in compliance with these guidelines (Issue [#549](https://github.com/Cherry-CIC/MVP/issues/549)).

---

## Architecture & Flow

```
[User initiates Account Deletion]
               │
               ▼
   [Check linked providers]
        ├── 'apple.com' NOT linked ────────────────────────────────┐
        │                                                          │
        └── 'apple.com' IS linked                                  │
               │                                                   │
               ▼                                                   │
    [Prompt Apple Re-authentication]                               │
        │                                                          │
        ├── User cancelled ───────────► [Abort Deletion safely]    │
        │                                                          │
        ├── Technical error / failed ─► [Log Safe Warning] ────────┤
        │                                                          │
        └── Success (platform token/code obtained)                 │
               │                                                   │
               ▼                                                   │
    [Revoke Apple Token (Platform-Specific)]                       │
        ├── iOS / macOS: revokeTokenWithAuthorizationCode(code)    │
        ├── Android:     revokeAccessToken(accessToken)            │
        └── Web:         Identity Toolkit v2/accounts:revokeToken  │
               │                                                   │
               ▼                                                   │
    [Proceed to Backend Deletion: ApiEndpoints.deleteAccount] ◄────┘
               │
               ▼
    [Clear Local State & Preferences]
               │
               ▼
    [Navigate to Welcome Screen]
```

### Components
1. **`FirebaseAuthService.revokeAppleAccessIfLinked()`**:
   - Inspects `user.providerData` for `'apple.com'`.
   - Prompts for Apple re-authentication (`reauthenticateWithProvider` on native platforms or `reauthenticateWithPopup` on Web).
   - Executes platform-specific token revocation with bounded retries:
     - **iOS / macOS**: Extracts `userCredential.additionalUserInfo?.authorizationCode` and calls `firebaseAuth.revokeTokenWithAuthorizationCode(authorizationCode)`.
     - **Android**: Extracts `userCredential.credential?.accessToken` (since Android's `AdditionalUserInfo` does not populate `authorizationCode`) and calls `firebaseAuth.revokeAccessToken(accessToken)`.
     - **Web**: Extracts `userCredential.credential?.accessToken` and revokes it via the Firebase Identity Toolkit REST endpoint (`POST https://identitytoolkit.googleapis.com/v2/accounts:revokeToken`) with `tokenType: 'ACCESS_TOKEN'`.
   - Classifies outcome into `RevokeAppleTokenResult`: `skipped`, `success`, `userCancelled`, or `failedNonBlocking`.
2. **`LoginRepository.revokeAppleAccessIfLinked()`**:
   - Exposes revocation to domain and presentation layers.
3. **`AuthViewModel.deleteAccount()`**:
   - Executes token revocation prior to invoking the backend deletion endpoint.
   - If the user cancels the Apple prompt, resets deletion state and returns `'Account deletion was cancelled.'`
   - If revocation succeeds or encounters a technical error (`failedNonBlocking`), proceeds to call `apiService.delete(ApiEndpoints.deleteAccount)`.

---

## Error Handling & Resiliency
- **Bounded Timeout and Retry for Transient Errors**: Each revocation call has a bounded per-attempt timeout (15 seconds by default) so stalled requests cannot hang account deletion indefinitely. If token revocation (`revokeTokenWithAuthorizationCode`, `revokeAccessToken`, or the Web Identity Toolkit request) encounters a transient network or server error (e.g. `network-request-failed`, `timeout`, `internal-error`, `too-many-requests`), it executes a bounded retry (up to 3 total attempts) with safe logging (`AppLogEvent.networkRetryStarted` / `networkRetryFailed`). Permanent errors (e.g. `invalid-credential`) fail immediately on the first attempt without redundant retries.
- **Non-blocking Deletion**: If retries are exhausted or a non-retryable technical failure occurs, the error is safely caught and mapped to `failedNonBlocking`. This ensures account deletion proceeds smoothly on the backend so users are never trapped in an undeletable account state.
- **Safe Logging**: Authorization codes, client secrets, and sensitive tokens are strictly excluded from logs and error payloads.

---

## Firebase Console & Apple Developer Configuration

To enable server-to-server token revocation between Firebase and Apple, the project must have OAuth Code Flow credentials configured in Firebase:

### 1. Apple Developer Portal
1. Go to **Certificates, Identifiers & Profiles** -> **Identifiers**.
2. Select **Services IDs** from the dropdown and register a new Services ID (e.g. `com.cherry.app.signin`).
   - Enable **Sign in with Apple**.
   - Configure your Web Authentication domain and redirect URL (Firebase Auth redirect URI: `https://<FIREBASE_PROJECT_ID>.firebaseapp.com/__/auth/handler`).
3. Go to **Keys** and create a new key:
   - Check **Sign in with Apple**.
   - Associate it with your Primary App ID.
   - Download the `.p8` key file. Note your **Key ID** and **Team ID**.

### 2. Firebase Console
1. Open the [Firebase Console](https://console.firebase.google.com/) for the Cherry project.
2. Navigate to **Build** -> **Authentication** -> **Sign-in method**.
3. Under **Sign-in providers**, edit **Apple**:
   - Enter your **Services ID**.
   - Enter your **Apple Team ID**.
   - Enter your **Key ID**.
   - Upload the private **`.p8` key file**.
4. Click **Save**.
