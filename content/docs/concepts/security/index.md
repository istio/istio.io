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

Istio aims to enhance the security of microservices and their communication without requiring service code changes. It is responsible for:

* Providing each service with a strong identity that represents its role to enable interoperability across clusters and clouds

* Securing service to service communication and end-user to service communication

* Providing a key management system to automate key and certificate generation, distribution, rotation, and revocation

The diagram below shows Istio's security-related architecture, which includes three primary components: identity, key management, and communication
security. This diagram describes how Istio is used to secure the service-to-service communication between service 'frontend' running
as the service account 'frontend-team' and service 'backend' running as the service account 'backend-team'. Istio supports services running
on both Kubernetes containers and VM/bare-metal machines.

{{< image width="80%" ratio="56.25%"
    link="./auth.svg"
    alt="Components making up the Istio security model."
    caption="Istio Security Architecture"
    >}}

As illustrated in the diagram, Istio leverages secret volume mount to deliver keys/certs from Citadel to Kubernetes containers. For services running on
VM/bare-metal machines, we introduce a node agent, which is a process running on each VM/bare-metal machine. It generates the private key and CSR (certificate
signing request) locally, sends CSR to Citadel for signing, and delivers the generated certificate together with the private key to Envoy.

## Mutual TLS authentication

### Identity

Istio uses [Kubernetes service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) to identify who runs the service:

*   A service account in Istio has the format "spiffe://\<_domain_\>/ns/\<_namespace_>/sa/\<_serviceaccount_\>".

    * _domain_ is currently _cluster.local_. We will support customization of domain in the near future.
    * _namespace_ is the namespace of the Kubernetes service account.
    * _serviceaccount_ is the Kubernetes service account name.

*   A service account is **the identity (or role) a workload runs as**, which represents that workload's privileges. For systems requiring strong security, the
amount of privilege for a workload should not be identified by a random string (i.e., service name, label, etc), or by the binary that is deployed.

    * For example, let's say we have a workload pulling data from a multi-tenant database. If Alice ran this workload, she will be able to pull
    a different set of data than if Bob ran this workload.

* Service accounts enable strong security policies by offering the flexibility to identify a machine, a user, a workload, or a group of workloads (different
workloads can run as the same service account).

* The service account a workload runs as won't change during the lifetime of the workload.

* Service account uniqueness can be ensured with domain name constraint

### Communication security

Service-to-service communication is tunneled through the client side [Envoy](https://envoyproxy.github.io/envoy/) and the server side Envoy. End-to-end communication is secured by:

* Local TCP connections between the service and Envoy

* Mutual TLS connections between proxies

* Secure Naming: during the handshake process, the client side Envoy checks that the service account provided by the server side certificate is allowed to run the target service

### Key management

Istio supports services running on both Kubernetes pods and VM/bare-metal machines. We use different key provisioning mechanisms for each scenario.

For services running on Kubernetes pods, the per-cluster Citadel (acting as Certificate Authority) automates the key & certificate management process. It mainly performs four critical operations:

* Generate a [SPIFFE](https://spiffe.github.io/docs/svid) key and certificate pair for each service account

* Distribute a key and certificate pair to each pod according to the service account

* Rotate keys and certificates periodically

* Revoke a specific key and certificate pair when necessary

For services running on VM/bare-metal machines, the above four operations are performed by Citadel together with node agents.

### Workflow

The Istio security workflow consists of two phases, deployment and runtime. For the deployment phase, we discuss the two
scenarios (i.e., in Kubernetes and VM/bare-metal machines) separately since they are different. Once the key and
certificate are deployed, the runtime phase is the same for the two scenarios. We briefly cover the workflow in this
section.

#### Deployment phase (Kubernetes Scenario)

1. Citadel watches the Kubernetes API Server, creates a [SPIFFE](https://spiffe.github.io/docs/svid) key and certificate
pair for each of the existing and new service accounts, and sends them to the API Server.

1. When a pod is created, API Server mounts the key and certificate pair according to the service account using [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/).

1. [Pilot](/docs/concepts/traffic-management/#pilot-and-envoy) generates the config with proper key and certificate and secure naming information,
which defines what service account(s) can run a certain service, and passes it to Envoy.

#### Deployment phase (VM/bare-metal Machines Scenario)

1. Citadel creates a gRPC service to take CSR request.

1. Node agent creates the private key and CSR, sends the CSR to Citadel for signing.

1. Citadel validates the credentials carried in the CSR, and signs the CSR to generate the certificate.

1. Node agent puts the certificate received from Citadel and the private key to Envoy.

1. The above CSR process repeats periodically for rotation.

#### Runtime phase

1. The outbound traffic from a client service is rerouted to its local Envoy.

1. The client side Envoy starts a mutual TLS handshake with the server side Envoy. During the handshake, it also does a secure naming check to verify that the service account presented in the server certificate can run the server service.

1. The traffic is forwarded to the server side Envoy after a mutual TLS connection is established, which is then forwarded to the server service through local TCP connections.

### Best practices

In this section, we provide a few deployment guidelines and then discuss a real-world scenario.

#### Deployment guidelines

* If there are multiple service operators (a.k.a. [SREs](https://en.wikipedia.org/wiki/Site_reliability_engineering)) deploying different services in a cluster (typically in a medium- or large-size cluster), we recommend creating a separate [namespace](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/) for each SRE team to isolate their access. For example, you could create a "team1-ns" namespace for team1, and "team2-ns" namespace for team2, such that both teams won't be able to access each other's services.

* If Citadel is compromised, all its managed keys and certificates in the cluster may be exposed. We *strongly* recommend running Citadel
on a dedicated namespace (for example, istio-citadel-ns), which only cluster admins have access to.

#### Example

Let's consider a 3-tier application with three services: photo-frontend, photo-backend, and datastore. Photo-frontend and photo-backend services are managed by the photo SRE team while the datastore service is managed by the datastore SRE team. Photo-frontend can access photo-backend, and photo-backend can access datastore. However, photo-frontend cannot access datastore.

In this scenario, a cluster admin creates 3 namespaces: istio-citadel-ns, photo-ns, and datastore-ns. Admin has access to all namespaces, and each team only has
access to its own namespace. The photo SRE team creates 2 service accounts to run photo-frontend and photo-backend respectively in namespace photo-ns. The
datastore SRE team creates 1 service account to run the datastore service in namespace datastore-ns. Moreover, we need to enforce the service access control
in [Istio Mixer](/docs/concepts/policies-and-telemetry/) such that photo-frontend cannot access datastore.

In this setup, Citadel is able to provide keys and certificates management for all namespaces, and isolate
microservice deployments from each other.

## Authentication policy

Istio authentication policy enables operators to specify authentication requirements for a service (or services). Istio authentication policy is composed of two parts:

* Peer: verifies the party, the direct client, that makes the connection. The common authentication mechanism for this is [mutual TLS](/docs/concepts/security/#mutual-tls-authentication).

* Origin: verifies the party, the original client, that makes the request (e.g end-users, devices etc). JWT is the only supported mechanism for origin authentication at the moment.

Istio configures the server side to perform authentication, however, it does not enforce the policy on the client side. For mutual TLS authentication, users can use [destination rules](/docs/concepts/traffic-management/#destination-rules) to configure client side to follow the expected protocol. For other cases, the application is responsible to acquire and attach the credential (e.g JWT) to the request.

Identities from both authentication parts, if applicable, are output to the next layer (e.g authorization, Mixer). To simplify the authorization rules, the policy can also specify which identity (peer or origin) should be used as 'the principal'. By default, it is set to the peer's identity.

Authentication policies are saved in Istio config store (in 0.7, the storage implementation uses Kubernetes CRD), and distributed by control plane. Depending on the size of the mesh, config propagation may take a few seconds to a few minutes. During the transition, you can expect traffic lost or inconsistent authentication results.

{{< image width="80%" ratio="75%"
    link="./authn.svg"
    caption="Authentication Policy Architecture"
    >}}

Policy is scoped to namespaces, with (optional) target selector rules to narrow down the set of services (within the same namespace as the policy) on which the policy should be applied. This aligns with the ACL model based on Kubernetes RBAC. More specifically, only the admin of the namespace can set policies for services in that namespace.

Authentication is implemented by the Istio sidecars. For example, with an Envoy sidecar, it is a combination of SSL setting and HTTP filters. If authentication
fails, requests will be rejected (either with SSL handshake error code, or http 401, depending on the type of authentication mechanism). If authentication succeeds,
the following authenticated attributes will be generated:

* `source.principal`: peer principal. If peer authentication is not used, the attribute is not set.
* `request.auth.principal`: depends on the policy principal binding, this could be peer principal (if `USE_PEER`) or origin principal (if `USE_ORIGIN`).
* `request.auth.audiences`: reflect the audience (`aud`) claim within the origin JWT (JWT that is used for origin authentication)
* `request.auth.presenter`: similarly, reflect the authorized presenter (`azp`) claim of the origin JWT.
* `request.auth.claims`: all raw string claims from origin-JWT.

Origin principal (principal from origin authentication) is not explicitly output. In general, it can always be reconstructed by joining (`iss`)
and subject (`sub`) claims with a "/" separator (for example, if `iss` and `sub` claims are "*googleapis.com*" and "*123456*" respectively, then
the origin principal is "*googleapis.com/123456*"). On the other hand, if principal binding is `USE_ORIGIN`, `request.auth.principal` carries the
same value as origin principal.

### Anatomy of a policy

#### Target selectors

Defines rules to find service(s) on which policy should be applied. If no rule is provided, the policy is matched to all services in the same namespace of the policy, so-called namespace-level policy (as opposed to service-level policies which have non-empty selector rules). Istio uses the service-level policy if available, otherwise it falls back to namespace-level policy. If neither is defined, it uses the default policy based on service mesh config and/or service annotation, which can only set mutual TLS setting (these are mechanisms before Istio 0.7 to configure mutual TLS for Istio service mesh). See [testing Istio mutual TLS](/docs/tasks/security/mutual-tls/).

> Starting with 0.8, authentication policy is the recommended way to enable/disable mutual TLS per service. The option to use service annotation will be removed in a future release.

Operators are responsible for avoiding conflicts, e.g create more than one service-level policy that matches to the same service(s) (or more than one namespace-level policy on the same namespace).

Example: rule to select product-page service (on any port), and reviews:9000.

{{< text yaml >}}
targets:
- name: product-page
- name: reviews
  ports:
  - number: 9000
{{< /text >}}

#### Peer authentication

Defines authentication methods (and associated parameters) that are supported for peer authentication. It can list more than one method; only one of them needs to be satisfied for the authentication to pass. However, starting with the 0.7 release, only mutual TLS is supported. Omit this if peer authentication is not needed.

Example of peer authentication using mutual TLS:

{{< text yaml >}}
peers:
- mtls:
{{< /text >}}

> Starting with Istio 0.7, the `mtls` settings doesn't require any parameters (hence `-mtls: {}`, `- mtls:` or `- mtls: null` declaration is sufficient). In future, it may carry arguments to provide different mutual TLS implementations.

#### Origin authentication

Defines authentication methods (and associated parameters) that are supported for origin authentication. Only JWT is supported for this, however, the policy can list multiple JWTs by different issuers. Similar to peer authentication, only one of the listed methods needs to be satisfied for the authentication to pass.

{{< text yaml >}}
origins:
- jwt:
    issuer: "https://accounts.google.com"
    jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
{{< /text >}}

### Principal binding

Defines what is the principal from the authentication. By default, this will be the peer's principal (and if peer authentication is not applied, it will be left unset). Policy writers can choose to overwrite it with USE_ORIGIN. In future, we will also support *conditional-binding* (e.g USE_PEER when peer is X, otherwise USE_ORIGIN)

## Authorization

Istio’s authorization feature - also known as Role-based Access Control (RBAC) - provides namespace-level,
service-level, and method-level access control for services in an Istio Mesh. It features:

* Role-Based semantics, which are simple and easy to use.
* Service-to-service and endUser-to-Service authorization.
* Flexibility through custom properties support (i.e., conditions) in roles and role-bindings.
* High performance, as Istio authorization is enforced natively on Envoy.

### Architecture

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
“default”, at most one `RbacConfig` instance is allowed to be used in the mesh. Like other Istio configuration objects it is defined
as a [Kubernetes `CustomResourceDefinition` (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) object.

In `RbacConfig` object, the operator can specify “mode”, which can be one of the following:

* **`OFF`**: Istio authorization is disabled.
* **`ON`**: Istio authorization is enabled for all services in the mesh.
* **`ON_WITH_INCLUSION`**: Istio authorization is enabled only for services and namespaces specified in “inclusion” field.
* **`ON_WITH_EXCLUSION`**: Istio authorization is enabled for all services in the mesh except the services and namespaces specified in “exclusion” field.

In the following example, authorization is enabled for the “default” namespace.

{{< text yaml >}}
apiVersion: “config.istio.io/v1alpha2”
kind: RbacConfig
metadata:
  name: default
  namespace: istio-system
spec:
  mode: ON_WITH_INCLUSION
  inclusion:
    namespaces: [“default”]
{{< /text >}}

### Policy

To configure an Istio authorization policy, you specify a `ServiceRole` and `ServiceRoleBinding`. Like other Istio
configuration objects they are defined as
[Kubernetes `CustomResourceDefinition` (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) objects.

* **`ServiceRole`** defines a group of permissions to access services.
* **`ServiceRoleBinding`** grants a `ServiceRole` to particular subjects, such as  a user, a group, or a service.

The combination of `ServiceRole` and `ServiceRoleBinding` specifies “**who** is allowed to do **what** under **which** conditions”. Specifically,

* "who" refers to “subjects” in `ServiceRoleBinding`.
* "what” refers to “permissions” in `ServiceRole`.
* “conditions” can be specified with [Istio attributes](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)
in either `ServiceRole` or `ServiceRoleBinding`.

#### `ServiceRole`

A `ServiceRole` specification includes a list of rules (i.e., permissions). Each rule has the following standard fields:

* **services**: A list of service names. Can be set to “*” to include all services in the specified namespace.
* **methods**: A list of HTTP method names. For permissions on gRPC requests, the HTTP verb is always “POST”. Can be set to “*” to include
all HTTP methods.
* **paths**: HTTP paths or gRPC methods. The gRPC methods should be in the form of “packageName.serviceName/methodName” (case sensitive).

A `ServiceRole` specification only applies to the namespace specified in the "metadata" section. The “services” and “methods” are required
fields in a rule. “paths” is optional. If not specified or set to “*“, it applies to “any” instance.

Here is an example of a simple role “service-admin”, which has full access to all services in the “default” namespace.

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: ServiceRole
metadata:
  name: service-admin
  namespace: default
spec:
  rules:
  - services: ["*"]
    methods: ["*"]
{{< /text >}}

Here is another role “products-viewer”, which has read (“GET” and “HEAD”) access to the service “products.default.svc.cluster.local” in the
“default” namespace.

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: ServiceRole
metadata:
  name: products-viewer
  namespace: default
spec:
  rules:
  - services: ["products.default.svc.cluster.local"]
    methods: ["GET", "HEAD"]
{{< /text >}}

In addition, you can use prefix and suffix matching for all fields in a rule. For example, you can define a “tester” role
that has the following permissions in the “default” namespace:
Full access to all services with prefix “test-” (e.g, “test-bookstore”, “test-performance”, “test-api.default.svc.cluster.local”).
Read (“GET”) access to all paths with “/reviews” suffix (e.g, “/books/reviews”, “/events/booksale/reviews”, “/reviews”) in service
“bookstore.default.svc.cluster.local”.

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
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

In a `ServiceRole`, the combination of `namespace`+`services`+`paths`+`methods` defines “how a service or services can be accessed”.
In some situations, you may need to specify additional conditions for your rules. For example, a rule may only apply to a certain
version of a service, or only apply to services that are labeled “foo”. You can easily specify these conditions using constraints.

For example, the following `ServiceRole` definition extends the previous “products-viewer” role by adding a constraint that
`request.headers[version]` is either “v1” or “v2”. Note that the supported “key” of a constraint are listed in the
[constraints and properties](/docs/reference/config/authorization/constraints-and-properties/) page.
In the case that the attribute is a “map” (e.g., `request.headers`), the “key” is an entry in the map (e.g., `request.headers[version]`).

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
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

A subject can be either an explicitly specified “user”, or represented by a set of “properties”.  A “property” in a `ServiceRoleBinding`
“subject” is similar to “constraints” in a `ServiceRole`, in that it lets you use conditions to specify a set of accounts that should
be assigned to this role. It contains “key” and allowed “values”, where supported “key” are listed in the
[constraints and properties](/docs/reference/config/authorization/constraints-and-properties/) page.

Here is an example of `ServiceRoleBinding` “test-binding-products”, which binds two subjects to the `ServiceRole` “product-viewer”:

* A service account representing service “a” (“service-account-a”).
* A service account representing the Ingress service (“istio-ingress-service-account”) **and** where the JWT “email” claim is “a@foo.com”.

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: ServiceRoleBinding
metadata:
  name: test-binding-products
  namespace: default
spec:
  subjects:
  - user: "service-account-a"
  - user: “istio-ingress-service-account”
    properties:
    - request.auth.claims[email]: “a@foo.com”
  roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}

In the case that you want to make a service(s) publicly accessible, you set the subject to user: "*". This assigns the `ServiceRole`
to all users and services.

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
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
