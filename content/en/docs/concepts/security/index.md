---
title: Security
description: Describes Istio's authorization and authentication functionality.
weight: 25
keywords: [security,policy,policies,authentication,authorization,rbac,access-control]
aliases:
    - /docs/concepts/network-and-auth/auth.html
    - /docs/concepts/security/authn-policy/
    - /docs/concepts/security/mutual-tls/
    - /docs/concepts/security/rbac/
    - /docs/concepts/security/mutual-tls.html
---

Breaking down a monolithic application into atomic services offers various benefits, including better agility, better scalability
and better ability to reuse services.
However, microservices also have particular security needs:

- To defend against the man-in-the-middle attack, they need traffic encryption.

- To provide flexible service access control, they need mutual TLS and fine-grained access policies.

- To audit who did what at what time, they need auditing tools.

Istio Security tries to provide a comprehensive security solution to solve all these issues.

This page gives an overview on how you can use Istio security features to secure your services, wherever you run them.
In particular, Istio security mitigates both insider and external threats against your data, endpoints, communication and platform.

{{< image width="80%" link="./overview.svg" caption="Istio Security Overview" >}}

The Istio security features provide strong identity, powerful policy, transparent TLS encryption, and authentication, authorization
and audit (AAA) tools to protect your services and data. The goals of Istio security are:

- **Security by default**: no changes needed for application code and infrastructure

- **Defense in depth**: integrate with existing security systems to provide multiple layers of defense

- **Zero-trust network**: build security solutions on untrusted networks

Visit our [Mutual TLS Migration docs](/docs/tasks/security/authentication/mtls-migration/) to start using Istio security features with your deployed services.
Visit our [Security Tasks](/docs/tasks/security/) for detailed instructions to use the security features.

## High-level architecture

Security in Istio involves multiple components:

- **Citadel** for key and certificate management

- **Sidecar and perimeter proxies** to implement secure communication between clients and servers

- **Pilot** to distribute [authentication policies](/docs/concepts/security/#authentication-policies)
  and [secure naming information](/docs/concepts/security/#secure-naming) to the proxies

- **Mixer** to manage authorization and auditing

{{< image width="80%" link="./architecture.svg" caption="Istio Security Architecture" >}}

In the following sections, we introduce the Istio security features in detail.

## Istio identity

Identity is a fundamental concept of any security infrastructure. At the beginning of a service-to-service communication,
the two parties must exchange credentials with their identity information for mutual authentication purposes.
On the client side, the server's identity is checked against the [secure naming](/docs/concepts/security/#secure-naming)
information to see if it is an authorized runner of the service.
On the server side, the server can determine what information the client can access based on the
[authorization policies](/docs/concepts/security/#authorization-policy),
audit who accessed what at what time, charge clients based on the services they used,
and reject any clients who failed to pay their bill from accessing the services.

In the Istio identity model, Istio uses the first-class service identity to determine the identity of a service.
This gives great flexibility and granularity to represent a human user, an individual service, or a group of services.
On platforms that do not have such identity available,
Istio can use other identities that can group service instances, such as service names.

Istio service identities on different platforms:

- **Kubernetes**: Kubernetes service account

- **GKE/GCE**: may use GCP service account

- **GCP**: GCP service account

- **AWS**: AWS IAM user/role account

- **On-premises (non-Kubernetes)**: user account, custom service account, service name, Istio service account, or GCP service account.
  The custom service account refers to the existing service account just like the identities that the customer's Identity Directory manages.

### Istio security vs SPIFFE

The [SPIFFE](https://spiffe.io/) standard provides a specification for a framework capable of bootstrapping and issuing identities to services
across heterogeneous environments.

Istio and SPIFFE share the same identity document: [SVID](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE-ID.md) (SPIFFE Verifiable Identity Document).
For example, in Kubernetes, the X.509 certificate has the URI field in the format of
`spiffe://<domain>/ns/<namespace>/sa/<serviceaccount>`.
This enables Istio services to establish and accept connections with other SPIFFE-compliant systems.

Istio security and [SPIRE](https://spiffe.io/spire/), which is the implementation of SPIFFE, differ in the PKI implementation details.
Istio provides a more comprehensive security solution, including authentication, authorization, and auditing.

## PKI

The Istio PKI is built on top of Istio Citadel and securely provisions strong identities to every workload.
Istio uses X.509 certificates to carry the identities in [SPIFFE](https://spiffe.io/) format.
The PKI also automates the key & certificate rotation at scale.

Istio supports services running on both Kubernetes pods and on-premises machines.
Currently we use different certificate key provisioning mechanisms for each scenario.

### Kubernetes scenario

1. Citadel watches the Kubernetes `apiserver`, creates a SPIFFE certificate and key pair for each of the existing and new service accounts.
   Citadel stores the certificate and key pairs as
   [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/).

1. When you create a pod, Kubernetes mounts the certificate and key pair to the pod according to its service account via
   [Kubernetes secret volume](https://kubernetes.io/docs/concepts/storage/volumes/#secret).

1. Citadel watches the lifetime of each certificate, and automatically rotates the certificates by rewriting the Kubernetes secrets.

1. Pilot generates the [secure naming](/docs/concepts/security/#secure-naming) information,
   which defines what service account or accounts can run a certain service.
   Pilot then passes the secure naming information to the sidecar Envoy.

### On-premises machines scenario

1. Citadel creates a gRPC service to take [Certificate Signing Requests](https://en.wikipedia.org/wiki/Certificate_signing_request) (CSRs).

1. Node agent generates a private key and CSR, and sends the CSR with its credentials to Citadel for signing.

1. Citadel validates the credentials carried with the CSR, and signs the CSR to generate the certificate.

1. The node agent sends both the certificate received from Citadel and the
   private key to Envoy.

1. The above CSR process repeats periodically for certificate and key rotation.

### Node agent in Kubernetes

Istio provides the option of using node agent in Kubernetes for certificate and key provisioning, as shown in the figure below.
Note that the identity provisioning flow for on-premises machines will be similar in the near future, we only describe the Kubernetes scenario here.

{{< image width="80%" link="./node_agent.svg" caption="PKI with node agents in Kubernetes"  >}}

The flow goes as follows:

1. Citadel creates a gRPC service to take CSR requests.

1. Envoy sends a certificate and key request via Envoy secret discovery service (SDS) API.

1. Upon receiving the SDS request, the node agent creates the private key and CSR before sending the CSR with its credentials to Citadel for signing.

1. Citadel validates the credentials carried in the CSR and signs the CSR to generate the certificate.

1. The node agent sends the certificate received from Citadel and the private key to Envoy via the Envoy SDS API.

1. The above CSR process repeats periodically for certificate and key rotation.

{{< idea >}}
Use the node agent debug endpoint to view the secrets a node agent is actively serving to its client proxies. Navigate to `/debug/sds/workload` on the agent's port `8080` to dump active workload secrets, or `/debug/sds/gateway` to dump active gateway secrets.
{{< /idea >}}

## Authentication

Istio provides two types of authentication:

- **Transport authentication**, also known as **service-to-service authentication**:
  verifies the direct client making the connection. Istio offers [mutual TLS](https://en.wikipedia.org/wiki/Mutual_authentication)
  as a full stack solution for transport authentication. You can
  easily turn on this feature without requiring service code changes. This
  solution:

    - Provides each service with a strong identity representing its role to
      enable interoperability across clusters and clouds.
    - Secures service-to-service communication and end-user-to-service
      communication.
    - Provides a key management system to automate key and certificate
      generation, distribution, and rotation.

- **Origin authentication**, also known as **end-user authentication**: verifies the
  original client making the request as an end-user or device.
  Istio enables request-level authentication with JSON Web Token (JWT) validation
  and a streamlined developer experience for open source OpenID Connect provider
  [ORY Hydra](https://www.ory.sh), [Keycloak](https://www.keycloak.org),
  [Auth0](https://auth0.com/),
  [Firebase Auth](https://firebase.google.com/docs/auth/),
  [Google Auth](https://developers.google.com/identity/protocols/OpenIDConnect), and custom auth.

In both cases, Istio stores the authentication policies in the `Istio config store` via a custom Kubernetes API.
Pilot keeps them up-to-date for each proxy, along with the keys where appropriate.
Additionally, Istio supports authentication in permissive mode to help you understand how a policy change can affect your security posture
before it becomes effective.

### Mutual TLS authentication

Istio tunnels service-to-service communication through the client side and server side [Envoy proxies](https://envoyproxy.github.io/envoy/).
For a client to call a server with mutual TLS authentication:

1. Istio re-routes the outbound traffic from a client to the client's local sidecar Envoy.

1. The client side Envoy starts a mutual TLS handshake with the server side Envoy.
   During the handshake, the client side Envoy also does a [secure naming](/docs/concepts/security/#secure-naming) check to verify that
   the service account presented in the server certificate is authorized to run the target service.

1. The client side Envoy and the server side Envoy establish a mutual TLS connection,
   and Istio forwards the traffic from the client side Envoy to the server side Envoy.

1. After authorization, the server side Envoy forwards the traffic to the server service through local TCP connections.

#### Permissive mode

Istio mutual TLS has a permissive mode, which allows a service to accept
both plaintext traffic and mutual TLS traffic at the same time. This
feature greatly improves the mutual TLS onboarding experience.

Many non-Istio clients communicating with a non-Istio server presents a
problem for an operator who wants to migrate that server to Istio with
mutual TLS enabled. Commonly, the operator cannot install an Istio sidecar
for all clients at the same time or does not even have the permissions to
do so on some clients. Even after installing the Istio sidecar on the
server, the operator cannot enable mutual TLS without breaking existing
communications.

With the permissive mode enabled, the server accepts both plaintext and
mutual TLS traffic. The mode provides great flexibility for the
on-boarding process. The server's installed Istio sidecar takes mutual TLS
traffic immediately without breaking existing plaintext traffic. As a
result, the operator can gradually install and configure the client's
Istio sidecars to send mutual TLS traffic. Once the configuration of the
clients is complete, the operator can configure the server to mutual TLS
only mode. For more information, visit the
[Mutual TLS Migration tutorial](/docs/tasks/security/authentication/mtls-migration).

#### Secure naming

The secure naming information contains *N-to-N* mappings from the server identities, which are encoded in certificates,
to the service names that are referred by discovery service or DNS.
A mapping from identity `A` to service name `B` means "`A` is allowed and authorized to run service `B`".
Pilot watches the Kubernetes `apiserver`, generates the secure naming information, and distributes it securely to the sidecar Envoys.
The following example explains why secure naming is critical in authentication.

Suppose the legitimate servers that run the service `datastore` only use the `infra-team` identity.
A malicious user has certificate and key for the `test-team` identity.
The malicious user intends to impersonate the service to inspect the data sent from the clients.
The malicious user deploys a forged server with the certificate and key for the `test-team` identity.
Suppose the malicious user successfully hijacked (through DNS spoofing, BGP/route hijacking, ARP
spoofing, etc.) the traffic sent to the `datastore` and redirected it to the forged server.

When a client calls the `datastore` service, it extracts the `test-team` identity from the server's certificate,
and checks whether `test-team` is allowed to run `datastore` with the secure naming information.
The client detects that `test-team` is **not** allowed to run the `datastore` service and the authentication fails.

Secure naming is able to protect against general network hijackings for HTTPS traffic. It can also
protect TCP traffic from general network hijackings except for DNS spoofing. It would fail to work
for TCP traffic if the attacker hijacks the DNS and modifies the IP address of the destination. This
is because TCP traffic does not contain the hostname information and we can only rely on the IP
address for routing. And this DNS hijack can happen even before the client-side Envoy receives the
traffic.

### Authentication architecture

You can specify authentication requirements for services receiving requests in
an Istio mesh using authentication policies. The mesh operator uses `.yaml`
files to specify the policies. The policies are saved in the Istio
configuration storage once deployed. Pilot, the Istio controller, watches the
configuration storage. Upon any policy changes, Pilot translates the new policy
to the appropriate configuration telling the Envoy sidecar proxy how to perform
the required authentication mechanisms. Pilot may fetch the public key and
attach it to the configuration for JWT validation. Alternatively, Pilot
provides the path to the keys and certificates the Istio system manages and
installs them to the application pod for mutual TLS. You can find more info in
the [PKI section](/docs/concepts/security/#pki).
Istio sends configurations to the targeted endpoints asynchronously. Once the
proxy receives the configuration, the new authentication requirement takes
effect immediately on that pod.

Client services, those that send requests, are responsible for following
the necessary authentication mechanism. For origin authentication (JWT), the
application is responsible for acquiring and attaching the JWT credential to
the request. For mutual TLS, Istio provides a [destination rule](/docs/concepts/traffic-management/#destination-rules).
The operator can use the destination rule to instruct client proxies to make
initial connections using TLS with the certificates expected on the server
side. You can find out more about how mutual TLS works in Istio in
[Mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication).

{{< image width="60%" link="./authn.svg" caption="Authentication Architecture" >}}

Istio outputs identities with both types of authentication, as well as other
claims in the credential if applicable, to the next layer:
[authorization](/docs/concepts/security/#authorization). Additionally,
operators can specify which identity, either from transport or origin
authentication, should Istio use as ‘the principal'.

### Authentication policies

This section provides more details about how Istio authentication policies
work. As you'll remember from the [Architecture section](/docs/concepts/security/#authentication-architecture),
authentication policies apply to requests that a service **receives**. To
specify client-side authentication rules in mutual TLS, you need to specify the
`TLSSettings` in the `DestinationRule`. You can find more information in our
[TLS settings reference docs](/docs/reference/config/networking/destination-rule/#TLSSettings).
Like other Istio configuration, you can specify authentication policies in
`.yaml` files. You deploy policies using `kubectl`.

The following example authentication policy specifies that transport
authentication for the `reviews` service must use mutual TLS:

{{< text yaml >}}
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "reviews"
spec:
  targets:
  - name: reviews
  peers:
  - mtls: {}
{{< /text >}}

#### Policy storage scope

Istio can store authentication policies in namespace-scope or mesh-scope
storage:

- Mesh-scope policy is specified with a value of `MeshPolicy` for the `kind`
  field and the name `"default"`. For example:

    {{< text yaml >}}
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "MeshPolicy"
    metadata:
      name: "default"
    spec:
      peers:
      - mtls: {}
    {{< /text >}}

- Namespace-scope policy is specified with a value of `"Policy"` for the `kind`
  field and a specified namespace. If unspecified, the default namespace is
  used. For example for namespace `ns1`:

    {{< text yaml >}}
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "default"
      namespace: "ns1"
    spec:
      peers:
      - mtls: {}
    {{< /text >}}

Policies in the namespace-scope storage can only affect services in the same
namespace. Policies in mesh-scope can affect all services in the mesh. To
prevent conflict and misuse, only one policy can be defined in mesh-scope
storage. That policy must be named `default` and have an empty
`targets:` section. You can find more information on our
[target selectors section](/docs/concepts/security/#target-selectors).

Kubernetes currently implements the Istio configuration on Custom Resource
Definitions (CRDs). These CRDs correspond to namespace-scope and
cluster-scope `CRDs` and automatically inherit access protection via the
Kubernetes RBAC. You can read more on the
[Kubernetes CRD documentation](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)

#### Target selectors

An authentication policy's targets specify the service or services to which the
policy applies. The following example shows a `targets:` section specifying
that the policy applies to:

- The `product-page` service on any port.
- The reviews service on port `9000`.

{{< text yaml >}}
targets:
 - name: product-page
 - name: reviews
   ports:
   - number: 9000
{{< /text >}}

If you don't provide a `targets:` section, Istio matches the policy to all
services in the storage scope of the policy. Thus, the `targets:` section can
help you specify the scope of the policies:

- Mesh-wide policy: A policy defined in the mesh-scope storage with no target
  selector section. There can be at most **one** mesh-wide policy **in the
  mesh**.

- Namespace-wide policy: A policy defined in the namespace-scope storage with
  name `default` and no target selector section. There can be at most **one**
  namespace-wide policy **per namespace**.

- Service-specific policy: a policy defined in the namespace-scope storage,
  with non-empty target selector section. A namespace can have **zero, one, or
  many** service-specific policies.

For each service, Istio applies the narrowest matching policy. The order is:
**service-specific > namespace-wide > mesh-wide**. If more than one
service-specific policy matches a service, Istio selects one of them at
random. Operators must avoid such conflicts when configuring their policies.

To enforce uniqueness for mesh-wide and namespace-wide policies, Istio accepts
only one authentication policy per mesh and one authentication policy per
namespace. Istio also requires mesh-wide and namespace-wide policies to have
the specific name `default`.

If a service has no matching policies, both transport authentication and
origin authentication are disabled.

#### Transport authentication

The `peers:` section defines the authentication methods and associated
parameters supported for transport authentication in a policy. The section can
list more than one method and only one method must be satisfied for the
authentication to pass. However, as of the Istio 0.7 release, the only
transport authentication method currently supported is mutual TLS.

The following example shows the `peers:` section enabling transport
authentication using mutual TLS.

{{< text yaml >}}
peers:
  - mtls: {}
{{< /text >}}

The mutual TLS setting has an optional `mode` parameter that defines the
strictness of the peer transport authentication. These modes are documented
in the [Authentication Policy reference document](/docs/reference/config/security/istio.authentication.v1alpha1/#MutualTls-Mode).

The default mutual TLS mode is `STRICT`. Therefore, `mode: STRICT` is equivalent to all of the following:

- `- mtls: {}`
- `- mtls:`
- `- mtls: null`

When you do not specify a mutual TLS mode, peers cannot use transport
authentication, and Istio rejects mutual TLS connections bound for the sidecar.
At the application layer, services may still handle their own mutual TLS sessions.

#### Origin authentication

The `origins:` section defines authentication methods and associated parameters
supported for origin authentication. Istio only supports JWT origin
authentication. You can specify allowed JWT issuers, and enable or disable JWT authentication for a
specific path. If all JWTs are disabled for a request path, authentication also passes as if there is
none defined.
Similar to peer authentication, only one of the listed methods must be
satisfied for the authentication to pass.

The following example policy specifies an `origins:` section for origin authentication that accepts
JWTs issued by Google. JWT authentication for path `/health` is disabled.

{{< text yaml >}}
origins:
- jwt:
    issuer: "https://accounts.google.com"
    jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
    trigger_rules:
    - excluded_paths:
      - exact: /health
{{< /text >}}

#### Principal binding

The principal binding key-value pair defines the principal authentication for a
policy. By default, Istio uses the authentication configured in the `peers:`
section. If no authentication is configured in the `peers:` section, Istio
leaves the authentication unset. Policy writers can overwrite this behavior
with the `USE_ORIGIN` value. This value configures Istio to use the origin's
authentication as the principal authentication instead. In future, we will
support conditional binding, for example: `USE_PEER` when peer is X, otherwise
`USE_ORIGIN`.

The following example shows the `principalBinding` key with a value of
`USE_ORIGIN`:

{{< text yaml >}}
principalBinding: USE_ORIGIN
{{< /text >}}

### Updating authentication policies

You can change an authentication policy at any time and Istio pushes the change
to the endpoints almost in real time. However, Istio cannot guarantee that all
endpoints receive a new policy at the same time. The following are
recommendations to avoid disruption when updating your authentication policies:

- To enable or disable mutual TLS: Use a temporary policy with a `mode:` key
  and a `PERMISSIVE` value. This configures receiving services to accept both
  types of traffic: plaintext and TLS. Thus, no request is dropped. Once all
  clients switch to the expected protocol, with or without mutual TLS, you can
  replace the `PERMISSIVE` policy with the final policy. For more information,
  visit the [Mutual TLS Migration tutorial](/docs/tasks/security/authentication/mtls-migration).

{{< text yaml >}}
peers:
- mtls:
    mode: PERMISSIVE
{{< /text >}}

- For JWT authentication migration: requests should contain new JWT before
  changing policy. Once the server side has completely switched to the new
  policy, the old JWT, if there is any, can be removed. Client applications
  need to be changed for these changes to work.

## Authorization

Istio's authorization feature provides mesh-level, namespace-level, and workload-level
access control on workloads in an Istio Mesh. It provides:

- **Workload-to-workload and end-user-to-workload authorization**.
- **A Simple API**, it includes a single [`AuthorizationPolicy` CRD](/docs/reference/config/security/authorization-policy/), which is easy to use and maintain.
- **Flexible semantics**, operators can define custom conditions on Istio attributes.
- **High performance**, as Istio authorization is enforced natively on Envoy.
- **High compatibility**, supports HTTP, HTTPS and HTTP2 natively, as well as any plain TCP protocols.

### Authorization architecture

{{< image width="90%" link="./authz.svg"
    alt="Istio Authorization"
    caption="Istio Authorization Architecture"
    >}}

The above diagram shows the basic Istio authorization architecture. Operators
specify Istio authorization policies using `.yaml` files.

Each Envoy proxy runs an authorization engine that authorizes requests at
runtime. When a request comes to the proxy, the authorization engine evaluates
the request context against the current authorization policies, and returns the
authorization result, `ALLOW` or `DENY`.

### Implicit enablement

There is no need to explicitly enable Istio's authorization feature, you just apply
the `AuthorizationPolicy` on **workloads** to enforce access control.

If no `AuthorizationPolicy` applies to a workload, no access control will be enforced,
In other words, all requests will be allowed.

If any `AuthorizationPolicy` applies to a workload, access to that workload is
denied by default, unless explicitly allowed by a rule declared in the policy.

Currently `AuthorizationPolicy` only supports `ALLOW` action. This means that if
multiple authorization policies apply to the same workload, the effect is additive.

### Authorization policy

To configure an Istio authorization policy, you create an
[`AuthorizationPolicy` resource](/docs/reference/config/security/authorization-policy/).

An authorization policy includes a selector and a list of rules. The selector
specifies the **target** that the policy applies to, while the rules specify **who**
is allowed to do **what** under which **conditions**. Specifically:

- **target** refers to the `selector` section in the `AuthorizationPolicy`.
- **who** refers to the `from` section in the `rule` of the `AuthorizationPolicy`.
- **what** refers to the `to` section in the `rule` of the `AuthorizationPolicy`.
- **conditions** refers to the `when` section in the `rule` of the `AuthorizationPolicy`.

Each rule has the following standard fields:

- **`from`**: A list of sources.
- **`to`**: A list of operations.
- **`when`**: A list of custom conditions.

The following example shows an `AuthorizationPolicy` that allows two sources
(service account `cluster.local/ns/default/sa/sleep` and namespace `dev`) to access the
workloads with labels `app: httpbin` and `version: v1` in namespace foo when the request
is sent with a valid JWT token.

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep"]
   - source:
       namespaces: ["dev"]
   to:
   - operation:
       methods: ["GET"]
   when:
   - key: request.auth.claims[iss]
     values: ["https://accounts.google.com"]
{{< /text >}}

#### Policy Target

Policy scope (target) is determined by `metadata/namespace` and an optional `selector`.

The `metadata/namespace` tells which namespace the policy applies to. If set to the
root namespace, the policy applies to all namespaces in a mesh. The value of
root namespace is configurable, and the default is `istio-system`. If set to a
normal namespace, the policy will only apply to the specified namespace.

A workload `selector` can be used to further restrict where a policy applies.
The `selector` uses pod labels to select the target workload. The workload
selector contains a list of `{key: value}` pairs, where the `key` is the name of the label.
If not set, the authorization policy will be applied to all workloads in the same namespace
as the authorization policy.

The following example policy `allow-read` allows `"GET"` and `"HEAD"` access to
the workload with label `app: products` in the `default` namespace.

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-read
  namespace: default
spec:
  selector:
    matchLabels:
      app: products
  rules:
  - to:
    - operation:
         methods: ["GET", "HEAD"]
{{< /text >}}

#### Value matching

Exact match, prefix match, suffix match, and presence match are supported for most
of the field with a few exceptions (e.g., the `key` field under the `when` section,
the `ipBlocks` under the `source` section and the `ports` field under the `to` section only support exact match).

- **Exact match**. i.e., exact string match.
- **Prefix match**. A string with an ending `"*"`. For example, `"test.abc.*"` matches `"test.abc.com"`, `"test.abc.com.cn"`, `"test.abc.org"`, etc.
- **Suffix match**. A string with a starting `"*"`. For example, `"*.abc.com"` matches `"eng.abc.com"`, `"test.eng.abc.com"`, etc.
- **Presence match**. `*` is used to specify anything but not empty. You can specify a field must be present using the format `fieldname: ["*"]`.
This means that the field can match any value, but it cannot be empty. Note that it is different from leaving a field unspecified, which means anything including empty.

The following example policy allows access at paths with prefix `"/test/"` or suffix `"/info"`.

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: tester
  namespace: default
spec:
  selector:
    matchLabels:
      app: products
  rules:
  - to:
    - operation:
        paths: ["/test/*", "*/info"]
{{< /text >}}

#### Allow-all and deny-all

The example below shows a simple policy `allow-all` which allows full access to all
workloads in the `default` namespace.

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-all
  namespace: default
spec:
  rules:
  - {}
{{< /text >}}

The example below shows a simple policy `deny-all` which denies access to all workloads
in the `admin` namespace.

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: admin
spec:
  {}
{{< /text >}}

#### Custom conditions

You can also use the `when` section to specify additional conditions. For example, the following
`AuthorizationPolicy` definition includes a condition that `request.headers[version]` is either `"v1"` or `"v2"`.
In this case, the key is `request.headers[version]`, which is an entry in the Istio attribute `request.headers`,
which is a map.

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep"]
   to:
   - operation:
       methods: ["GET"]
   when:
   - key: request.headers[version]
     values: ["v1", "v2"]
{{< /text >}}

The supported `key` values of a condition are listed in the
[conditions page](/docs/reference/config/security/conditions/).

#### Authenticated and unauthenticated identity

If you want to make a workload publicly accessible, you need to leave the
`source` section empty. This allows sources from **all (both authenticated and
unauthenticated)** users and workloads, for example:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 rules:
 - to:
   - operation:
       methods: ["GET", "POST"]
{{< /text >}}

To allow only **authenticated** users, set `principal` to `"*"` instead, for example:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 rules:
 - from:
   - source:
       principals: ["*"]
   to:
   - operation:
       methods: ["GET", "POST"]
{{< /text >}}

### Using Istio authorization on plain TCP protocols

Istio authorization supports workloads using any plain TCP protocols, such as MongoDB. In this case,
you configure the authorization policy in the same way you did for the HTTP workloads.
The difference is that certain fields and conditions are only applicable to HTTP workloads.
These fields include:

- The `request_principals` field in the source section of the authorization policy object
- The `hosts`, `methods` and `paths` fields in the operation section of the authorization policy object

The supported conditions are listed in the [conditions page](/docs/reference/config/security/conditions/).

If you use any HTTP only fields for a TCP workload, Istio will ignore HTTP only fields in the
authorization policy.

Assuming you have a MongoDB service on port 27017, the following example configures an authorization
policy to only allow the `bookinfo-ratings-v2` service in the Istio mesh to access the MongoDB workload.

{{< text yaml >}}
apiVersion: "security.istio.io/v1beta1"
kind: AuthorizationPolicy
metadata:
  name: mongodb-policy
  namespace: default
spec:
 selector:
   matchLabels:
     app: mongodb
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/bookinfo-ratings-v2"]
   to:
   - operation:
       ports: ["27017"]
{{< /text >}}

### Using other authorization mechanisms

While we strongly recommend using the Istio authorization mechanisms,
Istio is flexible enough to allow you to plug in your own authentication and authorization mechanisms via the Mixer component.
To use and configure plugins in Mixer, visit our [policies and telemetry adapters docs](/docs/reference/config/policy-and-telemetry/adapters).
