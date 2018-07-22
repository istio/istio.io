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
