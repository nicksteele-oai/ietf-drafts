---
title: "OAuth 2.0 Delegated Operation Grant (DOG)"
abbrev: "Delegated Operation Grant"
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
  RFC7519:
  RFC7800:
  RFC8174:
  RFC8725:
  RFC9700:
informative:
  I-D.carleton-workload-authz-grant:
  I-D.rosomakho-oauth-txn-challenge:
...

--- abstract

This document defines the Delegated Operation Grant (DOG), an OAuth 2.0
authorization grant that lets an agent running in a less trusted environment
request access to a service on a user's behalf. After the user authenticates
and authorizes a set of operations, the authorization server verifies an
identity assertion or attestation from the user's device or platform. It
issues a signed JSON Web Token (JWT) binding the user's authorization to the
intended service and a key controlled by the trusted platform.

The platform stores the grant and can use it to authorize a web session for
an agent's cloud browser or an access token for a remote workload. It can
limit the operations and lifetime of either form of access for each task.
This document specifies the grant and its validation requirements. The
protocols for establishing runtime access are outside its scope.

--- middle

# Introduction

A user authorizes an agent on a personal device to read order history.
The agent opens the merchant's website in a cloud browser. How can the
merchant honor the user's decision without giving the browser the user's
password or a copy of the user's signed-in session?

The trusted platform is the OAuth client that requests and holds the
Delegated Operation Grant. The runtime is the environment in which the agent
performs a task. The platform vouches for a particular request from that
runtime. The service decides whether to allow the request and enforces the
resulting limits. The grant stays on the platform.

{::boilerplate bcp14-tagged}

# Authorization and Issuance

The platform initiates an OAuth authorization request at the authorization
server's authorization endpoint (illustrated here as `/authorize`) for a
service and a set of operations. The endpoint coordinates user authentication
and authorization and returns the OAuth authorization response to the
platform ({{RFC6749}}, {{RFC9700}}). This document leaves the sign-in and
consent procedures, response handling, and evidence format to the deployment.

Before issuing a DOG, the server MUST verify an identity assertion or
attestation from the user's device or platform under its trust policy.
It MUST establish that the authenticated user's approval, the verified
identity, and the platform's proof key belong to the same authorization
transaction. If the device and platform differ, the server MUST verify that
the device authorized that platform and key. Evidence of device identity
alone cannot establish user consent.

The server delivers the DOG to the authenticated platform over a protected
channel. For example, the authorization response can carry an authorization
code that the platform redeems at the token endpoint. The DOG MUST NOT
appear in a redirect URL. This document defines no new OAuth response type.

# Delegated Operation Grant

The authorization server signs the DOG as a JWT ({{RFC7519}}). The JWT
MUST contain the following claims.

* `iss` identifies the authorization server.
* `sub` identifies the user within the issuer's namespace.
* `aud` identifies the single service authorized to accept the grant.
* `client_id` identifies the trusted platform's OAuth client at the issuer.
* `cnf` identifies the platform's proof key ({{RFC7800}}).
* `scope` lists the approved operations as space-delimited OAuth scope
  values understood by the service.
* `exp` sets the latest time at which the grant can be used.
* `jti` identifies this grant instance for revocation.

The platform MUST protect the DOG and its private key from the runtime.
It MUST select the grant from authenticated user and tenant context and
reject ambiguous matches. The runtime cannot select another user's grant.

# Requesting Runtime Access

A runtime requests access for a task through the platform. The platform
checks the request against the user's task and current policy. It MAY
request fewer operations or a shorter lifetime than the DOG allows.

Before granting access, the service MUST validate the signature, issuer,
audience, required claims, expiry, and revocation status. It MUST apply
validation rules that distinguish a DOG from other JWTs ({{RFC8725}}).
It MUST verify fresh proof of possession of the platform key. The proof MUST
cover this grant, the intended runtime, and the requested limits. The service MUST
reject a replayed proof or a request whose limits it cannot enforce.

The service MUST limit access to the named user and to operations allowed
by the grant, the platform's request, and current service policy. Access
MUST expire by the earlier of the grant's expiry and any requested deadline.
Renewal MUST preserve these limits and requires a current authorization
decision. The service MUST NOT accept the DOG itself as an API access token.

For example, a merchant can establish a new session for the cloud browser
using a session cookie, or issue an OAuth access token for a remote workload.
With only `orders.read` authorized, the merchant allows either runtime to
read the user's orders and rejects cancellation, even through the website.

The proof format, runtime identification, and delivery of the session or
token are outside this document's scope. A Workload Authorization Grant
({{I-D.carleton-workload-authz-grant}}) could identify the remote workload
to an authorization server. A deployment combining the grants would need
to tie that workload to the platform's request under the user's DOG.

# Security and Privacy Considerations

Binding the DOG to the platform key does not bind a resulting session cookie
or access token to the runtime. A stolen bearer credential can be used
within its limits. The service MUST enforce those limits on each operation,
including any operation that could create a more privileged session.

Approval of a class of operations does not establish approval of specific
transaction terms. Where individual approval is required, the service MUST
check the target and arguments and prevent duplicate effects. See
{{I-D.rosomakho-oauth-txn-challenge}} for one approach.

When the user withdraws authorization, the platform MUST stop using the
grant, discard pending results, and request revocation. The service MUST
reject new requests under a revoked grant. Existing sessions or access
tokens may remain usable until expiry unless the service checks current
authority at the point of use. A new grant MUST NOT reactivate an old one.

The issuer SHOULD use service-specific user identifiers and omit raw device
evidence from the DOG. Implementations MUST keep credentials and private
keys out of logs.

# IANA Considerations

This document requests no IANA actions.
