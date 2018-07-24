---
title: Security
description: Describes Istio's authorization and authentication functionality.
weight: 30
keywords: [security,authentication,authorization,rbac,access-control]
aliases:
    - /docs/concepts/network-and-auth/auth.html
    - /docs/concepts/security/authn-policy/
    - /docs/concepts/security/mutual-tls/
    - /docs/concepts/security/rbac/
---

Istio offers strong security to the microservices and their communication.
For example, traffic encryption to defend against the man-in-the-middle attack,
mutual TLS and fine-grained access policies to provide flexible service access control
and auditing to detect who did what at what time.

This page gives an overview of how Istio security can be leveraged to secure your services, wherever you run them.
In particular, Istio security mitigates both insider and external threats against your data, endpoints, communication and platform.

{{< image width="80%" ratio="56.25%"
    link="./overview.svg"
    alt="Istio security overview."
    caption="Istio Security Architecture"
    >}}

Istio security provides strong identity, powerful policy, and transparent TLS encryption to protect your services and data
with AAA (authentication/authorization/audit). The goals of Istio security are:

* **Security by default**: no changes needed for application code and infrastructure

* **Defense in depth**: integrate with existing security systems to provide multiple layers of defense

* **Zero-trust network**: build security solutions on untrusted networks

This guide provides a high-level overview of Istio security; you can find more information about specific Istio security concepts
in other guides in this section.
To find out how to get started using Istio security with deployed services, see the [Mutual TLS Migration](docs/tasks/security/mtls-migration/).
For more detailed howto on security tasks, see our [Security Tasks](docs/tasks/security/).

## High-level architecture and features

Istio security involves multiple components, including Citadel for key and certificate management,
Envoy and perimeter proxies for implementing secure communication between clients and servers,
Pilot for distributing authentication policies and secure naming information to the proxies,
and Mixer for managing authorization and auditing.

{{< image width="80%" ratio="56.25%"
    link="./architecture.svg"
    alt="Istio architecture."
    caption="Istio Security Architecture"
    >}}

### PKI (Public Key Infrastructure)

Istio PKI, built on top of Istio Citadel,
is responsible for securely provisioning strong workload identities to to every workload.
The identities are in SPIFFE format, carried by X.509 certificates.
The PKI also automates the key & certificate rotation and revocation at scale.

### Authentication

Istio provides two different types of authentication:

* **Service-to-service Authentication** enables data-in-transit encryption and strong channel-level authentication using mutual TLS.

* **User Authentication** enables request-level authentication with JSON Web Token (JWT) validation
  and a streamlined developer experience for [Auth0](https://auth0.com/), [Firebase Auth](https://firebase.google.com/docs/auth/),
  [Google Auth](https://developers.google.com/identity/protocols/OpenIDConnect), and custom auth.

In both cases the authentication policies are stored in the Istio config store via a custom Kubernetes API,
and are kept up to date (along with keys where appropriate) for each proxy by Pilot.
Istio also supports authentication in permissive mode to understand how a policy change would affect your security posture
before it becomes effective.

For more details,  please read [authentication](docs/concepts/security/#authentication).

### Authorization & audit

Istio provides fine-grained access control to enable application-level control and auditing on who accesses your service, API, or resource,
using a variety of access control mechanisms.
They include attribute and role-based access control as well as authorization hooks.

Find out more about Istio authorization in the [authorization guide](docs/concepts/security/#authorization)

The guide for auditing is coming soon!

### Security configuration

Istio makes it simple to configure and enable security features using Istio’s rich yet easy-to-use policy creation
and centralized policy management.

Find out more about configuring security policies in the [authentication](docs/concepts/security/#authentication)
and [authorization](docs/concepts/security/#authorization) sections.

### Using other security mechanisms

While we strongly recommend using Istio security,
Istio is flexible enough to allow you to plug in your own authentication and authorization mechanisms via the Mixer component.
You can find out how to use and configure [Mixer plugins](/docs/concepts/policies-and-telemetry/#adapters) in Policies and Telemetry.

### Upcoming features

* Identity/CA pluggability to support bring-your-own-CA and bring-your-own-identity. I.e. Vault integration, Active Directory integration

* Perimeter security policies for Ingress/Egress proxy

* Advanced auditing to meet various compliance requirements

* Secure developer/operator access from CORP to production services

* Binary authorization integration to ensure the service is running with the trusted binary

## Istio identity

Identity is a fundamental concept of any security infrastructure. At the beginning of a service-to-service communication,
the two parties need to exchange credentials consisting of their identity information, for mutual authentication purposes.
Once the they have obtained each other’s identity,
on the client side, the server's identity is checked against the secure naming information to see if it is an authorized runner of the service.
On the server side, the server can determine what information the client can access based on the authorization policies,
audit who accessed what at what time, charge clients based on the services they used,
and reject any clients who failed to pay their bill from accessing the services.

In the Istio identity model, Istio uses the first-class service identity to be the identity of a service.
This gives great flexibility and granularity to represent a human user, an individual service, or a group of services.
On platforms that don’t have such identity available, Istio uses other identities that can group service instances, such as service name.

Istio service identities on different platforms:

* **Kubernetes**: Kubernetes service account

* **GKE/GCE**: may use GCP service account

* **GCP**: GCP service account

* **AWS**: AWS IAM user/role account

* **On-prem (non-Kubernetes)**: user account (custom service account), service name, istio service account, or GCP service account.
  Custom service account refers to the existing service account alike identities managed by customer’s Identity Directory.

### Istio security vs SPIFFE

The SPIFFE standard provides a specification for a framework capable of bootstrapping and issuing identity to services
across heterogeneous environments.

Istio and SPIFFE share the same identity document, i.e., SVID (SPIFFE Verifiable Identity Document).
For example, in Kubernetes, the X.509 certificate has URI field in the format of “spiffe://<domain>/ns/<namespace>/sa/<serviceaccount>”.
This enables Istio services to establish and accept connections with other SPIFFE-compliant systems.

However, Istio security and SPIFFE/SPIRE have differ in the PKI implementation details.
Moreover, Istio provides a more comprehensive security solution, including authentication, authorization, and auditing.

## PKI

### Istio Citadel and Kubernetes secret

Istio supports services running on both Kubernetes pods and on-prem machines.
Currently we use different key provisioning mechanisms for each scenario, which will be unified in a post-1.0 release.

The identity provisioning workflow consists of two phases, deployment and runtime.
For the deployment phase, we discuss the two scenarios (i.e., in Kubernetes and on-prem machines) separately since they are different.
Once the PKI is deployed, the runtime phase is the same for the two scenarios. We briefly cover the workflow in this section.

### Deployment phase (Kubernetes scenario)

1. Citadel watches the Kubernetes API Server, creates a SPIFFE certificate/key pair for each of the existing and new service accounts,
   and sends them to the API Server. The certificate/key pairs are stored as Kubernetes secrets.

1. When a pod is created, Kubernetes propagates the certificate/key pair according to the service account via Kubernetes secret volume.

1. Citadel watches the lifetime of each certificate, and automatically rotates the certificates in the Kubernetes secrets.

1. Pilot generates the secure naming information,
   which defines what service account(s) can run a certain service, and passes it to sidecar Envoy.

### Deployment phase (on-prem machines scenario)

1. Citadel creates a gRPC service to take CSR request.

1. Node agent generates a private key and CSR, and sends the CSR with its credentials to Citadel for signing.

1. Citadel validates the credentials carried in the CSR, and signs the CSR to generate the certificate.

1. Node agent propagates the certificate received from Citadel and the private key to sidecar Envoy.

1. The above CSR process repeats periodically for rotation.

### Runtime phase

The outbound traffic from a client is rerouted to its local sidecar Envoy.

The client side Envoy starts a mutual TLS handshake with the server side Envoy.
During the handshake, it also does a secure naming check to verify that the service account presented in the server certificate
is authorized to run the target service.

The traffic is forwarded to the server side Envoy after mTLS connection is established.
After the authorization check on Envoy, the traffic is forwarded to the server service through local TCP connections.

## Istio Citadel and Node Agent (upcoming)

In the near future, Istio will use node agent for certificate/key provision, as shown in the figure below.
Note that the deployment flow for on-prem machines is the same so we only describe K8s scenario.

{{< image width="80%" ratio="56.25%"
    link="./node_agent.svg"
    alt="PKI with node agents in Kubernetes."
    caption="Istio Security Architecture"
    >}}

### Deployment phase

1. Citadel creates a gRPC service to take CSR requests.

1. Envoy sends a key/certificate request via Envoy SDS (secret discovery service) API.

1. Upon receiving the SDS request, node agent creates the private key and CSR, sends the CSR with its credentials to Citadel for signing.

1. Citadel validates the credentials carried in the CSR, and signs the CSR to generate the certificate.

1. Node agent propagates the certificate received from Citadel and the private key to Envoy.

1. The above CSR process repeats periodically for rotation.

The runtime phase remains the same as the previous section.

## Best practices

In this section, we provide a few deployment guidelines and then discuss a real-world scenario.

### Deployment guidelines

* If there are multiple service operators (a.k.a. [SREs](https://en.wikipedia.org/wiki/Site_reliability_engineering))
  deploying different services in a cluster (typically in a medium- or large-size cluster), we recommend creating a separate
  [namespace](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/) for each SRE team to isolate their access.
  For example, you could create a "team1-ns" namespace for team1, and "team2-ns" namespace for team2, such that both teams won't
  be able to access each other's services.

* If Citadel is compromised, all its managed keys and certificates in the cluster may be exposed. We *strongly* recommend running Citadel
  on a dedicated namespace (for example, istio-citadel-ns), which only cluster admins have access to.

### Example

Let's consider a 3-tier application with three services: *photo-frontend*, *photo-backend*, and *datastore*.
*Photo-frontend* and *photo-backend* services are managed by the photo SRE team
while the *datastore* service is managed by the *datastore* SRE team.
*Photo-frontend* can access *photo-backend*, and *photo-backend* can access *datastore*.
However, *photo-frontend* cannot access *datastore*.

In this scenario, a cluster admin creates 3 namespaces: *istio-citadel-ns*, *photo-ns*, and *datastore-ns*.
Admin has access to all namespaces, and each team only has access to its own namespace.
The photo SRE team creates 2 service accounts to run *photo-frontend* and *photo-backend* respectively in namespace *photo-ns*.
The *datastore* SRE team creates 1 service account to run the *datastore* service in namespace *datastore-ns*.
Moreover, we need to enforce the service access control in [Istio Mixer](/docs/concepts/policies-and-telemetry/)
such that *photo-frontend* cannot access *datastore*.

With this setup, Citadel is able to provide certificate/key management for all namespaces, isolate the microservice deployments,
and control the service access privileges.

## Authentication

Istio provides two types of authentication:

*   Transport authentication (also known as service-to-service authentication): verifies the direct client that makes the connection. Istio offers
mutual TLS (mTLS) as a full stack solution for transport authentication. Customer can easily turn on this feature without requiring
service code changes. The solution includes:

    * Providing each service with a strong identity that represents its role to enable interoperability across clusters and clouds
    * Securing service to service communication and end-user to service communication
    * Providing a key management system to automate key and certificate generation, distribution, rotation, and revocation

*   Origin authentication (also known as end-user authentication): verifies the original client that makes the request, such as an end-user or device. Istio 1.0 supports
authentication with JSON Web Token (JWT) validation.

### Authentication architecture

Authentication requirements for services receiving requests in an Istio mesh are specified using authentication policies.
Policies are specified by the mesh operator using yaml files and saved in the Istio config store once deployed.
The Istio controller (Pilot) watches the config store. Upon any policy changes, it translates the new policy to appropriate
configuration that tells the Envoy sidecar proxy how to perform the required authentication mechanisms. It may also fetch
the public key and attach to the configuration for JWT validation, or provides the path to the keys and certificates that
are managed and installed to the application pod by Istio system for mutual TLS (see more in "PKI and identity” section).
Configurations are sent to the targeted endpoints asynchronously. Once the proxy receives the configuration, the new
authentication requirement takes effect immediately on that pod.

Client services (i.e those that send requests) are responsible for following the necessary authentication mechanism.
For origin authentication (JWT), the application is responsible for acquiring and attaching the JWT credential to the request.
For mutual TLS, Istio provides a [destination rule](/docs/concepts/traffic-management/#destination-rules) that the operator can use to instruct client proxies to make initial
connections using TLS with the certificates expected on the server side. You can find out more about how mutual TLS works in
Istio in "PKI and identity" section.

{{< image width="80%" ratio="75%"
    link="./authn.svg"
    caption="Authentication Architecture"
    >}}

Identities from both types of authentication, as well as other claims in the credential if applicable, are output to the
next layer (e.g., [authorization](/docs/concepts/security/#authorization)). Operators can also specify which identity
(either from transport or origin authentication) should be used as ‘the principal’.

### Anatomy of an authentication policy

This section provides more details about how Istio authentication policies work. As you’ll remember from the [Architecture
section](/docs/concepts/security/#authentication-architecture), authentication policies apply to requests that a service **receives**. For specifying client-side authentication
rules in mutual TLS, you need to specify
[`TLSSettings` in `DestinationRule`](/docs/reference/config/istio.networking.v1alpha3/#TLSSettings).
Authentication policies are specified in yaml files like other Istio configuration, and deployed using istioctl.

Here is a simple authentication policy that specifies that transport authentication for "reviews" service must use mutual TLS.

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

Authentication policies can be stored in namespace-scope or mesh-scope storage.

* Mesh-scope policy is specified with `kind` `MeshPolicy`, and the name "default”.

* Namespace-scope policy is specified with `kind` `Policy` and a specified namespace (or the default namespace if unspecified).

Here is an example of a mesh-scope policy.

{{< text yaml >}}
apiVersion: "authentication.istio.io/v1alpha1"
kind: "MeshPolicy"
metadata:
  name: "default"
spec:
  peers:
  - mtls: {}
{{< /text >}}

Here is an example of a namespace-scope policy for namespace `ns1`

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

Policy in namespace-scope storage can only affect services in the same namespace. Policy in mesh-scope can affect all services in the mesh.
To prevent conflict and misuse, only one policy can be defined in mesh-scope storage. That policy must be named `default` and have an
empty [targets](/docs/concepts/security/#target-selectors).

> With the current [`CustomResourceDefinitions`-based](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
implementation for Istio config, these correspond to namespace-scope and cluster-scope `CRDs`, and automatically
inherit access protection via Kubernetes RBAC.

#### Target selectors

An authentication policy’s targets: section specifies the service(s) to which this policy should be applied. The following example shows
a rule that specifies this policy applies to the product-page service on any port, and the reviews service on port 9000.

{{< text yaml >}}
targets:
 - name: product-page
 - name: reviews
   ports:
   - number: 9000
{{< /text >}}

If no targets: rule is provided, the policy is matched to all services in the storage scope of the policy:

* Mesh-wide policy: a policy defined in mesh-scope storage with no target selector rules. There is at most one mesh-wide policy in the mesh.

* Namespace-wide policy:  a policy defined in namespace-scope storage with name `default` and no target selector rules. There is at most one namespace-wide
policy per namespace.

* Service-specific policy: a policy defined in namespace-scope storage, with non-empty target selector rules. A namespace can have zero,
one or many service-specific policies.

For each service, Istio will apply the narrowest matching policy, where service-specific > namespace-wide > mesh-wide. If more than one
service-specific policy matches a service, one of them will be selected at random. Operators are responsible for avoiding such conflicts
when configuring their policies.

> Istio enforces uniqueness for mesh-wide and namespace-wide policies by accepting only one authentication policy per mesh/namespace and
requiring it to have a specific name "default”.

#### Transport authentication (also known as peers)

The `peers:` section defines the authentication methods (and associated parameters) that are supported for transport authentication in
this policy. It can list more than one method; only one of them needs to be satisfied for the authentication to pass. However, as of
Istio 0.7 release, only mutual TLS is currently supported as a transport authentication method. Omit this section entirely if transport
authentication is not needed.

Here is an example of transport authentication using mutual TLS.

{{< text yaml >}}
 peers:
  - mtls: {}
{{< /text >}}

> Currently mutual TLS setting doesn’t require any parameters (hence `-mtls: {}`, `- mtls:` or `- mtls: null` declaration is treated the same).
In future, it may carry arguments to provide different mutual TLS implementations.

#### Origin authentication (also known as origins)

The `origins:` section defines authentication methods (and associated parameters) that are supported for origin authentication. Only JWT is
supported for this, however, the policy can list multiple JWTs by different issuers. Similar to peer authentication, only one of the listed
methods needs to be satisfied for the authentication to pass.

Here is an example policy that specifies origin authentication accepts JWTs issued by Google.

{{< text yaml >}}
origins:
- jwt:
    issuer: "https://accounts.google.com"
    jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
{{< /text >}}

#### Principal binding

Defines what should be used as the principal (the entity to be authenticated) for this policy. By default, this will be the peer’s principal.
If peer authentication is not applied, it will be left unset. Policy writers can choose to overwrite it with `USE_ORIGIN`, whereupon the origin
will be used as the principal instead. In future, we will also support conditional binding (e.g `USE_PEER` when peer is X, otherwise `USE_ORIGIN`).

Here is an example of setting principal binding to `USE_ORIGIN`.

{{< text yaml >}}
principalBinding: USE_ORIGIN
{{< /text >}}

### Updating authentication policies

An authentication policy can be changed at any time and is pushed to endpoints almost in real time. However, Istio cannot
guarantee that all endpoints will receive a new policy at the same time. Here's how to avoid disruption when updating
your authentication policies:

* Enable (or disable) mutual TLS: a temporary policy with `PERMISSIVE` mode should be used. This configures receiving services
to accept both types of traffic (plain text and TLS), so no request is dropped. Once all clients switch to the expected
protocol (e.g TLS for the enabling case), operators can replace the `PERMISSIVE` policy with the final policy. For more
information, visit ["Mutual TLS Migration” tutorial](/docs/tasks/security/mtls-migration).

{{< text yaml >}}
peers:
- mTLS:
    mode: PERMISSIVE
{{< /text >}}

* For JWT authentication migration: requests should contain new JWT before changing policy. Once the server side has completely
switched to the new policy, the old JWT (if any) can be removed. Client applications need to be changed for these.

## Authorization

Istio’s authorization feature - also known as Role-based Access Control (RBAC) - provides namespace-level,
service-level, and method-level access control for services in an Istio Mesh. It features:

* Role-Based semantics, which are simple and easy to use.
* Service-to-service and endUser-to-Service authorization.
* Flexibility through custom properties support (i.e., conditions) in roles and role-bindings.
* High performance, as Istio authorization is enforced natively on Envoy.

### Authorization architecture

{{< image width="80%" ratio="56.25%"
    link="./authz.svg"
    alt="Istio Authorization"
    caption="Istio Authorization Architecture"
    >}}

The above diagram shows the basic Istio authorization architecture. Operators specify Istio authorization policies using yaml files.
Once deployed, the policies are saved in Istio Config Store.

Pilot watches for changes to authorization policies. It fetches the updated authorization policies if it sees any changes.
Pilot distributes authorization policies to Envoy proxies that are co-located with service instances.

Each Envoy proxy runs an authorization engine that authorizes requests at runtime. When a request comes to the proxy,
the authorization engine evaluates the request context against the current authorization policies, and returns the authorization
result (ALLOW or DENY).

### Enabling authorization

You enable authorization using a `RbacConfig` object. The `RbacConfig` object is a mesh global singleton with a fixed name
"default”, at most one `RbacConfig` instance is allowed to be used in the mesh. Like other Istio configuration objects it is defined
as a [Kubernetes `CustomResourceDefinition` (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) object.

In `RbacConfig` object, the operator can specify "mode”, which can be one of the following:

* **`OFF`**: Istio authorization is disabled.
* **`ON`**: Istio authorization is enabled for all services in the mesh.
* **`ON_WITH_INCLUSION`**: Istio authorization is enabled only for services and namespaces specified in "inclusion” field.
* **`ON_WITH_EXCLUSION`**: Istio authorization is enabled for all services in the mesh except the services and namespaces specified in "exclusion” field.

In the following example, authorization is enabled for the "default” namespace.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1”
kind: RbacConfig
metadata:
  name: default
  namespace: istio-system
spec:
  mode: ON_WITH_INCLUSION
  inclusion:
    namespaces: ["default”]
{{< /text >}}

### Authorization policy

To configure an Istio authorization policy, you specify a `ServiceRole` and `ServiceRoleBinding`. Like other Istio
configuration objects they are defined as
[Kubernetes `CustomResourceDefinition` (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) objects.

* **`ServiceRole`** defines a group of permissions to access services.
* **`ServiceRoleBinding`** grants a `ServiceRole` to particular subjects, such as  a user, a group, or a service.

The combination of `ServiceRole` and `ServiceRoleBinding` specifies "**who** is allowed to do **what** under **which** conditions”. Specifically,

* "who" refers to "subjects” in `ServiceRoleBinding`.
* "what” refers to "permissions” in `ServiceRole`.
* "conditions” can be specified with [Istio attributes](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)
in either `ServiceRole` or `ServiceRoleBinding`.

#### `ServiceRole`

A `ServiceRole` specification includes a list of rules (i.e., permissions). Each rule has the following standard fields:

* **services**: A list of service names. Can be set to "*” to include all services in the specified namespace.
* **methods**: A list of HTTP method names. For permissions on gRPC requests, the HTTP verb is always "POST”. Can be set to "*” to include
all HTTP methods.
* **paths**: HTTP paths or gRPC methods. The gRPC methods should be in the form of "packageName.serviceName/methodName” (case sensitive).

A `ServiceRole` specification only applies to the namespace specified in the "metadata" section. The "services” and "methods” are required
fields in a rule. "paths” is optional. If not specified or set to "*", it applies to "any” instance.

Here is an example of a simple role "service-admin”, which has full access to all services in the "default” namespace.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: service-admin
  namespace: default
spec:
  rules:
  - services: ["*"]
    methods: ["*"]
{{< /text >}}

Here is another role "products-viewer”, which has read ("GET” and "HEAD”) access to the service "products.default.svc.cluster.local” in the
"default” namespace.

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

In addition, you can use prefix and suffix matching for all fields in a rule. For example, you can define a "tester” role
that has the following permissions in the "default” namespace:
Full access to all services with prefix "test-” (e.g, "test-bookstore”, "test-performance”, "test-api.default.svc.cluster.local”).
Read ("GET”) access to all paths with "/reviews” suffix (e.g, "/books/reviews”, "/events/booksale/reviews”, "/reviews”) in service
"bookstore.default.svc.cluster.local”.

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

In a `ServiceRole`, the combination of `namespace`+`services`+`paths`+`methods` defines "how a service or services can be accessed”.
In some situations, you may need to specify additional conditions for your rules. For example, a rule may only apply to a certain
version of a service, or only apply to services that are labeled "foo”. You can easily specify these conditions using constraints.

For example, the following `ServiceRole` definition extends the previous "products-viewer” role by adding a constraint that
`request.headers[version]` is either "v1” or "v2”. Note that the supported "key” of a constraint are listed in the
[constraints and properties](/docs/reference/config/authorization/constraints-and-properties/) page.
In the case that the attribute is a "map” (e.g., `request.headers`), the "key” is an entry in the map (e.g., `request.headers[version]`).

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

* **roleRef** refers to a `ServiceRole` resource in the same namespace.
* A list of **subjects** that are assigned to the role.

A subject can be either an explicitly specified "user”, or represented by a set of "properties”.  A "property” in a `ServiceRoleBinding`
"subject” is similar to "constraints” in a `ServiceRole`, in that it lets you use conditions to specify a set of accounts that should
be assigned to this role. It contains "key” and allowed "values”, where supported "key” are listed in the
[constraints and properties](/docs/reference/config/authorization/constraints-and-properties/) page.

Here is an example of `ServiceRoleBinding` "test-binding-products”, which binds two subjects to the `ServiceRole` "product-viewer”:

* A service account representing service "a” ("service-account-a”).
* A service account representing the Ingress service ("istio-ingress-service-account”) **and** where the JWT "email” claim is "a@foo.com”.

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
    - request.auth.claims[email]: "a@foo.com"
  roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}

In the case that you want to make a service(s) publicly accessible, you set the subject to user: "*". This assigns the `ServiceRole`
to all users and services.

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
