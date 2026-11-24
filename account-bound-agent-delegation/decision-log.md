# Design decisions

This log summarizes the current [editor's draft](draft-steele-oauth-account-bound-agent-delegation.md).
It does not add requirements.

- **Keep the account grant in the broker.** The agent proposes a task; the
  broker holds the account grant and calls the service with a restricted token.
- **Use the same authorization server and presenter in the baseline.** This
  avoids inventing a token format or requiring support for cross-issuer
  exchange or for handing a token to an executor with a different key.
- **Treat action approval separately.** Key possession alone does not approve
  a cancellation, bind its terms, or make it single-use.
- **Make unlinking effective for new issuance.** A previously issued token
  can remain usable until expiry unless the service checks current authority.
