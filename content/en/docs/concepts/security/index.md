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

Visit our [Mutual TLS Migration docs](/docs/tasks/security/mtls-migration/) to start using Istio security features with your deployed services.
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

## Best practices

In this section, we provide a few deployment guidelines and discuss a real-world scenario.

### Deployment guidelines

If there are multiple service operators (a.k.a. [SREs](https://en.wikipedia.org/wiki/Site_reliability_engineering))
deploying different services in a medium- or large-size cluster, we recommend creating a separate
[Kubernetes namespace](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/) for each SRE team to isolate their access.
For example, you can create a `team1-ns` namespace for `team1`, and `team2-ns` namespace for `team2`, such
that both teams cannot access each other's services.

{{< warning >}}
If Citadel is compromised, all its managed keys and certificates in the cluster may be exposed.
We **strongly** recommend running Citadel in a dedicated namespace (for example, `istio-citadel-ns`), to restrict access to
the cluster to only administrators.
{{< /warning >}}

### Example

Let us consider a three-tier application with three services: `photo-frontend`,
`photo-backend`, and `datastore`. The photo SRE team manages the
`photo-frontend` and `photo-backend` services while the datastore SRE team
manages the `datastore` service. The `photo-frontend` service can access
`photo-backend`, and the `photo-backend` service can access `datastore`.
However, the `photo-frontend` service cannot access `datastore`.

In this scenario, a cluster administrator creates three namespaces:
`istio-citadel-ns`, `photo-ns`, and `datastore-ns`. The administrator has
access to all namespaces and each team only has access to its own namespace.
The photo SRE team creates two service accounts to run `photo-frontend` and
`photo-backend` respectively in the `photo-ns` namespace. The datastore SRE
team creates one service account to run the `datastore` service in the
`datastore-ns` namespace. Moreover, we need to enforce the service access
control in [Istio Mixer](/docs/reference/config/policy-and-telemetry/) such that
`photo-frontend` cannot access datastore.

In this setup, Kubernetes can isolate the operator privileges on managing the services.
Istio manages certificates and keys in all namespaces
and enforces different access control rules to the services.

### How Citadel determines whether to create service account secrets

When a Citadel instance notices that a `ServiceAccount` is created in a namespace, it must decide whether it should generate an `istio.io/key-and-cert` secret for that `ServiceAccount`. In order to make that decision, Citadel considers three inputs (note: there can be multiple Citadel instances deployed in a single cluster, and the following targeting rules are applied to each instance):

1. `ca.istio.io/env` namespace label: *string valued* label containing the namespace of the desired Citadel instance

1. `ca.istio.io/override` namespace label: *boolean valued* label which overrides all other configurations and forces all Citadel instances either to target or ignore a namespace

1. [`enableNamespacesByDefault` security configuration](/docs/reference/config/installation-options/#security-options): default behavior if no labels are found on the `ServiceAccount`'s namespace

From these three values, the decision process mirrors that of the [`Sidecar Injection Webhook`](/docs/ops/setup/injection-concepts/). The detailed behavior is that:

- If `ca.istio.io/override` exists and is `true`, generate key/cert secrets for workloads.

- Otherwise, if `ca.istio.io/override` exists and is `false`, don't generate key/cert secrets for workloads.

- Otherwise, if a `ca.istio.io/env: "ns-foo"` label is defined in the service account's namespace, the Citadel instance in namespace `ns-foo` will be used for generating key/cert secrets for workloads in the `ServiceAccount`'s namespace.

- Otherwise, set `enableNamespacesByDefault` to `true` during installation. If it is `true`, the default Citadel instance will be used for generating key/cert secrets for workloads in the `ServiceAccount`'s namespace.

- Otherwise, no secrets are created for the `ServiceAccount`'s namespace.

This logic is captured in the truth table below:

| `ca.istio.io/override` value | `ca.istio.io/env` match | `enableNamespacesByDefault` configuration | Workload secret created |
|------------------------------|-------------------------|-------------------------------------------|-------------------------|
|`true`|yes|`true`|yes|
|`true`|yes|`false`|yes|
|`true`|no|`true`|yes|
|`true`|no|`false`|yes|
|`true`|unset|`true`|yes|
|`true`|unset|`false`|yes|
|`false`|yes|`true`|no|
|`false`|yes|`false`|no|
|`false`|no|`true`|no|
|`false`|no|`false`|no|
|`false`|unset|`true`|no|
|`false`|unset|`false`|no|
|unset|yes|`true`|yes|
|unset|yes|`false`|yes|
|unset|no|`true`|no|
|unset|no|`false`|no|
|unset|unset|`true`|yes|
|unset|unset|`false`|no|

{{< idea >}}
When a namespace transitions from _disabled_ to _enabled_, Citadel will retroactively generate secrets for all `ServiceAccounts` in that namespace. When transitioning from _enabled_ to _disabled_, however, Citadel will not delete the namespace's generated secrets until the root certificate is renewed.
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
[Mutual TLS Migration tutorial](/docs/tasks/security/mtls-migration).

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
in the [Authentication Policy reference document](/docs/reference/config/istio.authentication.v1alpha1/#MutualTls-Mode).

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
  visit the [Mutual TLS Migration tutorial](/docs/tasks/security/mtls-migration).

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

Istio's authorization feature - also known as Role-based Access Control (RBAC)
- provides namespace-level, service-level, and method-level access control for
services in an Istio Mesh. It features:

- **Role-Based semantics**, which are simple and easy to use.
- **Service-to-service and end-user-to-service authorization**.
- **Flexibility through custom properties support**, for example conditions,
  in roles and role-bindings.
- **High performance**, as Istio authorization is enforced natively on Envoy.
- **High compatibility**, supports HTTP, HTTPS and HTTP2 natively, as well as any plain TCP protocols.

### Authorization architecture

{{< image width="90%" link="./authz.svg"
    alt="Istio Authorization"
    caption="Istio Authorization Architecture"
    >}}

The above diagram shows the basic Istio authorization architecture. Operators
specify Istio authorization policies using `.yaml` files. Once deployed, Istio
saves the policies in the `Istio Config Store`.

Pilot watches for changes to Istio authorization policies. It fetches the
updated authorization policies if it sees any changes. Pilot distributes Istio
authorization policies to the Envoy proxies that are colocated with the
service instances.

Each Envoy proxy runs an authorization engine that authorizes requests at
runtime. When a request comes to the proxy, the authorization engine evaluates
the request context against the current authorization policies, and returns the
authorization result, `ALLOW` or `DENY`.

### Enabling authorization

You enable Istio Authorization using a `ClusterRbacConfig` object. The `ClusterRbacConfig`
object is a cluster-scoped singleton with a fixed name value of `default`. You can
only use one `ClusterRbacConfig` instance in the mesh. Like other Istio configuration
objects, `ClusterRbacConfig` is defined as a
Kubernetes `CustomResourceDefinition`
[(CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) object.

In the `ClusterRbacConfig` object, the operator can specify a `mode` value, which can
be:

- **`OFF`**: Istio authorization is disabled.
- **`ON`**: Istio authorization is enabled for all services in the mesh.
- **`ON_WITH_INCLUSION`**: Istio authorization is enabled only for services and
  namespaces specified in the `inclusion` field.
- **`ON_WITH_EXCLUSION`**: Istio authorization is enabled for all services in
  the mesh except the services and namespaces specified in the `exclusion`
  field.

In the following example, Istio authorization is enabled for the `default`
namespace.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ClusterRbacConfig
metadata:
  name: default
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["default"]
{{< /text >}}

### Authorization policy

To configure an Istio authorization policy, you specify a `ServiceRole` and
`ServiceRoleBinding`. Like other Istio configuration objects, they are
defined as
Kubernetes `CustomResourceDefinition` [(CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) objects.

- **`ServiceRole`** defines a group of permissions to access services.
- **`ServiceRoleBinding`** grants a `ServiceRole` to particular subjects, such
  as a user, a group, or a service.

The combination of `ServiceRole` and `ServiceRoleBinding` specifies: **who** is
allowed to do **what** under **which conditions**. Specifically:

- **who** refers to the `subjects` section in `ServiceRoleBinding`.
- **what** refers to the `permissions` section in `ServiceRole`.
- **which conditions** refers to the `conditions` section you can specify with
  the [Istio attributes](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)
  in either `ServiceRole` or `ServiceRoleBinding`.

#### `ServiceRole`

A `ServiceRole` specification includes a list of `rules`, AKA permissions.
Each rule has the following standard fields:

- **`services`**: A list of service names. You can set the value to `*` to
  include all services in the specified namespace.

- **`methods`**: A list of HTTP methods. You can set the value to `*` to include all
  HTTP methods. This field should not be set for TCP and gRPC services.

- **`paths`**: HTTP paths or gRPC methods. The gRPC methods must be in the
   form of `/packageName.serviceName/methodName` and are case sensitive.

A `ServiceRole` specification only applies to the namespace specified in the
`metadata` section. A rule requires the `services` field and the other fields are optional.
If you do not specify a field or if you set its value to `*`, Istio applies the field to all instances.

The example below shows a simple role: `service-admin`, which has full access
to all services in the `default` namespace.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: service-admin
  namespace: default
spec:
  rules:
  - services: ["*"]
{{< /text >}}

Here is another role: `products-viewer`, which has read, `"GET"` and `"HEAD"`,
access to the service `products.default.svc.cluster.local` in the `default`
namespace.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: products-viewer
  namespace: default
spec:
  rules:
  - services: ["products.default.svc.cluster.local"]
    methods: ["GET", "HEAD"]
{{< /text >}}

In addition, we support prefix matching and suffix matching for all the fields
in a rule. For example, you can define a `tester` role with the following
permissions in the `default` namespace:

- Full access to all services with prefix `"test-*"`, for example:
   `test-bookstore`, `test-performance`, `test-api.default.svc.cluster.local`.
- Read (`"GET"`) access to all paths with `"*/reviews"` suffix, for example:
   `/books/reviews`, `/events/booksale/reviews`, `/reviews` in service
   `bookstore.default.svc.cluster.local`.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: tester
  namespace: default
spec:
  rules:
  - services: ["test-*"]
    methods: ["*"]
  - services: ["bookstore.default.svc.cluster.local"]
    paths: ["*/reviews"]
    methods: ["GET"]
{{< /text >}}

In a `ServiceRole`, the combination of `namespace` + `services` + `paths` +
`methods` defines **how a service or services are accessed**. In some
situations, you may need to specify additional conditions for your rules. For
example, a rule may only apply to a certain **version** of a service, or only
apply to services with a specific **label**, like `"foo"`. You can easily
specify these conditions using `constraints`.

For example, the following `ServiceRole` definition adds a constraint that
`request.headers[version]` is either `"v1"` or `"v2"` extending the previous
`products-viewer` role. The supported `key` values of a constraint are listed
in the [constraints and properties page](/docs/reference/config/authorization/constraints-and-properties/).
In the case that the attribute is a `map`, for example `request.headers`, the
`key` is an entry in the map, for example `request.headers[version]`.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: products-viewer-version
  namespace: default
spec:
  rules:
  - services: ["products.default.svc.cluster.local"]
    methods: ["GET", "HEAD"]
    constraints:
    - key: request.headers[version]
      values: ["v1", "v2"]
{{< /text >}}

#### `ServiceRoleBinding`

A `ServiceRoleBinding` specification includes two parts:

-  **`roleRef`** refers to a `ServiceRole` resource in the same namespace.
-  A list of **`subjects`** that are assigned to the role.

You can either explicitly specify a *subject* with a `user` or with a set of
`properties`.  A *property* in a `ServiceRoleBinding` *subject* is similar to
a *constraint* in a `ServiceRole` specification. A *property* also lets you use
conditions to specify a set of accounts assigned to this role. It contains a
`key` and its allowed *values*. The supported `key` values of a constraint
are listed in the
[constraints and properties page](/docs/reference/config/authorization/constraints-and-properties/).

The following example shows a `ServiceRoleBinding` named
`test-binding-products`, which binds two subjects to the `ServiceRole` named
`"product-viewer"` and has the following `subjects`

- A service account representing service **a**, `"service-account-a"`.
- A service account representing the Ingress service
  `"istio-ingress-service-account"` **and** where the JWT `email` claim is
  `"a@foo.com"`.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: test-binding-products
  namespace: default
spec:
  subjects:
  - user: "service-account-a"
  - user: "istio-ingress-service-account"
    properties:
      request.auth.claims[email]: "a@foo.com"
  roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}

In case you want to make a service publicly accessible, you can set the
`subject` to `user: "*"`. This value assigns the `ServiceRole` to **all (both authenticated and
unauthenticated)** users and services, for example:

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: binding-products-allusers
  namespace: default
spec:
  subjects:
  - user: "*"
  roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}

To assign the `ServiceRole` to only **authenticated** users and services, use `source.principal: "*"`
instead, for example:

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: binding-products-all-authenticated-users
  namespace: default
spec:
  subjects:
  - properties:
      source.principal: "*"
  roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}

### Using Istio authorization on plain TCP protocols

The examples in [Service role](#servicerole) and [Service role binding](#servicerolebinding) show the
typical way to use Istio authorization on services using the HTTP protocol. In those examples, all fields
in a service role and service role binding are supported.

Istio authorization supports services using any plain TCP protocols, such as MongoDB. In this case,
you configure the service roles and service role bindings in the same way you did for the HTTP service.
The difference is that certain fields, constraints and properties are only applicable to HTTP services.
These fields include:

- The `paths` and `methods` fields in the service role configuration object.
- The `group` field in the service role binding configuration object.

The supported constraints and properties are listed in the [constraints and properties page](
/docs/reference/config/authorization/constraints-and-properties/).

If you use any HTTP only fields for a TCP service, Istio ignores the service role or service role
binding custom resources and the policies set within completely.

Assuming you have a MongoDB service on port 27017, the following example configures a service role and
a service role binding to only allow the `bookinfo-ratings-v2` in the Istio mesh to access the
MongoDB service.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: mongodb-viewer
  namespace: default
spec:
  rules:
  - services: ["mongodb.default.svc.cluster.local"]
    constraints:
    - key: "destination.port"
      values: ["27017"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: bind-mongodb-viewer
  namespace: default
spec:
  subjects:
  - user: "cluster.local/ns/default/sa/bookinfo-ratings-v2"
  roleRef:
    kind: ServiceRole
    name: "mongodb-viewer"
{{< /text >}}

### Authorization permissive mode

The authorization permissive mode is an experimental feature in Istio's 1.1 release. Its interface can change in future releases.

The authorization permissive mode allows you to verify authorization policies
before applying them in a production environment.

You can enable the authorization permissive mode on a global authorization
configuration and on individual policies. If you set the permissive mode on a global
authorization configuration, all policies switch to the permissive mode regardless
of their own set mode. If you set the global authorization mode to
`ENFORCED`, the enforcement mode set by the individual policies takes effect.
If you do not set a mode, both the global authorization configuration and the individual
policies are set to the `ENFORCED` mode by default.

To enable the permissive mode globally, set the value of the `enforcement_mode:` key in the global Istio RBAC authorization configuration to `PERMISSIVE` as shown in the following example.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ClusterRbacConfig
metadata:
  name: default
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["default"]
  enforcement_mode: PERMISSIVE
{{< /text >}}

To enable the permissive mode for a specific policy, set the value of the `mode:` key to `PERMISSIVE` in the policy configuration file as shown in the following example.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: bind-details-reviews
  namespace: default
spec:
  subjects:
    - user: "cluster.local/ns/default/sa/bookinfo-productpage"
  roleRef:
    kind: ServiceRole
    name: "details-reviews-viewer"
  mode: PERMISSIVE
{{< /text >}}

### Using other authorization mechanisms

While we strongly recommend using the Istio authorization mechanisms,
Istio is flexible enough to allow you to plug in your own authentication and authorization mechanisms via the Mixer component.
To use and configure plugins in Mixer, visit our [policies and telemetry adapters docs](/docs/reference/config/policy-and-telemetry/adapters).
