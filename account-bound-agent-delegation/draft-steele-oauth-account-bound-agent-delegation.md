---
title: "Account-Linked Delegation for OAuth 2.0 Agents"
abbrev: "Account-Linked Agent Delegation"
docname: draft-steele-oauth-account-bound-agent-delegation-latest
date:
v: 3
category: std
submissiontype: IETF
ipr: trust200902

author:
  - fullname: Nick Steele
    organization: OpenAI
    email: steele@openai.com

normative:
  RFC2119:
  RFC6749:
  RFC7636:
  RFC8174:
  RFC8693:
  RFC8707:
  RFC9449:
  RFC9700:
informative:
  RFC7009:
  I-D.ietf-oauth-identity-assertion-authz-grant:
  I-D.nandakumar-oauth-actor-bound-token-exchange:
  I-D.rosomakho-oauth-txn-challenge:
...

--- abstract

This document proposes an OAuth 2.0 authorization grant that lets a trusted
platform obtain access to a user's service account on behalf of an agent
running in a less trusted environment, such as a cloud browser.

With the user's consent, the platform requests a signed JSON Web Token
(JWT) that binds the delegated authority to the user's account, the intended
service, and the platform's public key. To redeem the grant, the
platform proves possession of the corresponding private key. The service
can then issue an OAuth access token or establish a web session for the agent
using a session cookie. The platform can request narrower permissions or a
shorter lifetime for each task. The service enforces these limits without
giving the agent the grant or the user's sign-in credentials.

--- middle

# Introduction

A user asks an agent to show their orders. The user wants the agent to read the orders, not to sign in as the user or acquire the ability to cancel them.

This profile separates linking an account from exercising authority over it. A trusted component of the agent platform, the broker, holds a revocable grant for the linked account. The agent proposes operations. The broker obtains and uses an access token; the agent receives neither credential nor a general-purpose signing interface. A separate executor that receives its own access token is outside the baseline ({{separate-executor}}).

{::boilerplate bcp14-tagged}

# Link the Account

The broker is a confidential client of the service's authorization server (AS). The user selects their service account and authorizes the broker through the authorization code grant with PKCE ({{RFC6749}}, {{RFC7636}}, {{RFC9700}}). Federated Credential Management (FedCM) may assist sign-in or account selection. It does not grant the broker API access.

The AS MUST bind the authorization code to the broker's DPoP key using {{RFC9449}}. This profile additionally requires the AS to retain the same key binding on the resulting refresh token, alongside its service account and broker client bindings. This is a requirement of this profile, not of base DPoP for confidential clients. The broker MUST start a new link if it loses that key.

The broker MUST resolve the link from authenticated platform state, scoped to the platform user and tenant as applicable, not from account identifiers supplied by the agent. It MUST keep the refresh token and its proof key outside the agent's context and MUST NOT use any access token returned at enrollment. The AS MUST NOT redeem the linked refresh token through a path that bypasses this profile's sender, scope, resource, or grant checks. Linking an account sets an upper bound on authority, not approval for every operation within it.

# Exercise the Grant

1. The broker checks the proposed operation against the user's task and local policy. It maps the operation to one configured resource and a scope the service can enforce. If it cannot express the requested limit, it MUST NOT request broader access instead.
2. The broker authenticates to the AS that issued the refresh token and exchanges it using {{RFC8693}}. It sends the refresh token as `subject_token` with `subject_token_type` set to `urn:ietf:params:oauth:token-type:refresh_token`. It sets `requested_token_type` to `urn:ietf:params:oauth:token-type:access_token`, and supplies one `resource` ({{RFC8707}}), the required `scope`, and a DPoP proof ({{RFC9449}}). DPoP does not replace client authentication.
3. The AS MUST verify the grant is active and matches the client and proof key, and that the requested resource and scope are permitted by the grant and current policy. It MUST issue only an access token for that resource bound to the same proof key. The response MUST set `issued_token_type` to `urn:ietf:params:oauth:token-type:access_token`, `token_type` to `DPoP`, and `expires_in` to at most 300 seconds. It MUST NOT return a refresh token. Exchange does not consume or rotate the refresh token. The broker MUST reject a bearer response or a response with broader authority. The AS MUST NOT accept the resulting access token as input to another exchange.
4. The broker calls the resource with the token and a fresh DPoP proof. The resource MUST validate the issuing AS, audience, expiry, and proof, including the access-token hash and confirmation key. It MUST enforce the granted scope and account against the actual operation.

For a service-defined `orders.read` scope, a valid request retrieves orders for the linked account. A cancellation, a read for a different account, and a read using the same token with a different key are all denied.

# Security and Privacy Considerations

DPoP proves possession of a key. It does not sign the request body or prove approval of a particular transaction. A resource that requires approval of specific terms MUST check the actual operation against those terms. A new DPoP proof can accompany a duplicate operation, so services requiring a single effect need transaction-level replay protection.

On unlink, the broker MUST first disable the link, discard any exchange response arriving after unlink, and initiate revocation (e.g., {{RFC7009}}). The AS MUST reject exchange of a revoked grant. An existing access token can remain valid until expiry; a service promising earlier cutoff needs a current authorization check at the point of effect. Do not log credentials, private keys, or raw user instructions.

# Related Work and Separate Executors {#separate-executor}

Cross-App Access ({{I-D.ietf-oauth-identity-assertion-authz-grant}}) uses an identity assertion or refresh token at an identity provider trusted by a resource AS. This profile starts with a direct grant from the service. A service that already downscopes a key-bound token on refresh gets no additional cryptographic protection from the exchange; the exchange distinguishes per-task issuance from session renewal. {{I-D.rosomakho-oauth-txn-challenge}} describes how a resource can request approval for an exact transaction.

Ordinary DPoP binds the token to the broker's proof key in this profile. If a different executor will present the token, the issuer needs evidence that the executor is authorized and holds the intended key. Actor-Bound Token Exchange ({{I-D.nandakumar-oauth-actor-bound-token-exchange}}) proposes such an exchange. This profile does not specify issuance to a separate executor or onward delegation.

# IANA Considerations

This document requests no IANA actions.
