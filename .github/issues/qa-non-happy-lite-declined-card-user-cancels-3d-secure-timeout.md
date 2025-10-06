# QA (non-happy, lite): declined card, user cancels 3-D Secure, timeout

## Description
We need to run a focused QA sweep on high-risk payment failure paths: declined cards, users canceling the 3-D Secure challenge, and checkout sessions that time out. The objective is to validate that Cherry handles these failure flows gracefully and consistently—surfacing clear messaging, protecting the user's trust, and keeping our ledgers clean.

## Why non-happy path testing matters for Cherry
- **User trust**: Clear, friendly messaging and recoverable flows help users understand what went wrong and try again without abandoning Cherry.
- **Financial integrity**: Verifying that failed payments do not create inconsistent ledgers or pending balances keeps our books accurate.
- **Compliance**: Confirming that we respect payment network requirements (e.g., 3-D Secure handling) reduces regulatory risk.
- **Stability**: Exercising edge cases improves resilience, ensuring retries, logs, and telemetry stay healthy even when processors respond with errors or delays.

## Scope & Acceptance Criteria
- Declined card flows display the correct reason, log the event, and offer actionable next steps (e.g., retry, choose another method).
- When the shopper cancels the 3-D Secure challenge, we surface a clear cancellation state and reset the checkout session safely.
- Gateway or network timeouts prompt a helpful message, avoid duplicate charges, and trigger retry/rollback logic as designed.

## Additional Notes
Document observed behavior, screenshots, logs, and any discrepancies so engineering can triage follow-ups quickly.
