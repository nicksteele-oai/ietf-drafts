# Design decisions

The [editor's draft](draft-steele-oauth-account-bound-agent-delegation.md)
defines the OAuth 2.0 Delegated Operation Grant (DOG).

- The user's authorization and the device or platform identity evidence
  must refer to the same transaction.
- The platform holds the signed grant and its proof key. The workload
  requests access through the platform.
- The service enforces the grant and any narrower limits on the resulting
  session or access token. Platform key binding does not carry over automatically.
- Workload access protocols are out of scope. A Workload Authorization
  Grant is one possible way to identify a remote workload.
- Revocation stops new issuance. Earlier cutoff of existing access requires
  enforcement at the service.
