---
title: Istio authentication policy
overview: Describes Istio Authentication policy

order: 10

layout: docs
type: markdown
---
{% include home.html %}

## Overview
Istio authentication policy enables admin to specify authentication requirements for a service (or services). Istio authentication policy is composed of two-parts authentication:

* Peer: verifies the party, the direct client, that makes the connection. The common authentication mechanism for this is [mutual TLS]({{home}}/docs/concepts/security/mutual-tls.html). Istio will be responsible for managing both client and server sides to enforce the policy.

* Origin: verifies the party, the original client, that makes the request (e.g end-users, devices etc). JWT is the only supported mechanism for origin authentication at the moment. Istio will configure the server side to perform authentication, but will not enforce the client side to send the required token.


Identities from both authentication parts, if applicable, will be output to the next layer (e.g authorization, mixer). To simplify the authorization rules, the policy can also specify which identity (peer or origin) should be used as 'the principal'. By default, it is set to the peer's identity.


## Architecture

Authentication policies are saved in Istio config store (in 0.7, the storage implementation uses Kubernetes CRD), and distributed by Pilot. Pilot continously monitors the config store. Upon any change, it fetches the new policy and translates it into appropriate (sidecar) configs that are needed to enforce the policy. These configs are sent down to sidecar via regular discovery service APIs. Depending on the size of the mesh, this process may take a few seconds to a few minutes. During the transition, it might expect traffic lost or inconsistent authentication results.

{% include figure.html width='80%' ratio='100%'
    img='./img/authn.png'
    alt='Istio authentication policy architecture'
    title='Istio authentication policy architecture'
    caption='Istio authentication policy architecture'
    %}



Policy is scoped at namespace level, with (optional) target selector rules to narrow down the set of services (within the same namespace as the policy) on which the policy should be applied. This aligns with the ACL model based on Kubernetes RBAC. More specifically, only admin of the namespace can set policies for services in that namespace.


Authentication engine is implemented on sidecars. For example, with Envoy sidecar, it is a combination of SSL settings and HTTP filters. If authentication fails, requests will be rejected (either with SLL handshake error code, or http 401, depending on the type of authencation mechanism). If authentication succeeds, the following authenticated attributes will be generated:

- **source.principal**: peer principal. If peer authentiation is not used, the attribute is not set.
- **request.auth.principal**: depends on the policy principal binding, this could be peer principal (if USE_PEER) or origin principal (if USE_ORIGIN).
- **request.auth.aud**: reflect the audience (*aud*) claim within the origin-JWT (JWT that is used for origin authentication)
- **request.auth.presenter**: similarly, reflect the authorize presenter (*azp*) claim.
- **request.auth.claims**: all raw string claims from origin-JWT.

Origin principal is not explicitely output. In general, it can always be reconstructed from issuer (*iss*) and subject (*sub*) claims. If principal binding is USE_ORIGIN, it is also the same as **request.auth.principal**.


## Anatomy of the policy

### Target selectors

Defines rule to find service(s) on which policy should be applied. If no rule provided, the policy will be matched to all services in the namespace, so call namespace-level policy (as opposed to service-level policies which have non-empty selector rules). Istio (pilot) will pick the service-level policy if available, otherwise fallback to namespace-level policy. If neither is define, it uses the default policy based on service mesh config.


Operators are responsible to avoid conflicts, e.g create more than one service-level policy that match to the same service(s) (or more than one namespace-level policy on the same namespace).


Example: rule to select product-page service (on any port), and reviews:9000.

```
 targets:
 - name: product-page
 - name: reviews
   ports:
   - number: 9000
```

### Peer authentication


Defines authentication methods (and associated parameters) that are supported for peer authentication. It can list more than one methods; only one of them needs to be satisfied for the authentication to pass. However, in 0.7 releases, only mutual TLS is supported. Omitting this if peer authentication is not needed.


Example of peer authentiation using mutual TLS:

```
  peers:
  - mtls:
```  

### Origin authentication

Defines authentication methods (and associated parameters) that are supported for for origin authentication. Only JWT is supported for this, however, the policy can list multiple JWTs by diffrent issuers. Same as peers authentication, only one of the listed methods need to be satisfied for the authenticaiton pass.

```
origins:
- jwt:
    issuer: "https://accounts.google.com"
    jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
```

### Principal binding

Defines what is the principal from the authentiation. By default, it will use the value of peer's principal (and if peer authentication is not applied, it would be left unset). Policy writer can choose to overwrite it with USE_ORIGIN. In future, we will also support *conditional-binding* (e.g USE_PEER when peer is X, otherwise USE_ORIGIN)

## What's next

Try out [Basic Istio authentiation policy]({{home}}/docs/tasks/security/authn-policy.html) tutorial.
