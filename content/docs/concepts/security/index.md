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

Istio aims to enhance the security of microservices and their communication
without requiring service code changes. It is responsible for:

- Providing each service with a strong identity that represents its role to
  enable interoperability across clusters and clouds

- Securing service to service communication and end-user to service
  communication

- Providing a key management system to automate key and certificate generation,
  distribution, rotation, and revocation

The following diagram shows Istio's security architecture, which includes three
primary components: identity, key management, and communication security. The
diagram shows how to use Istio to secure the service-to-service communication
between the `frontend` service running as the `frontend-team` service account
and the `backend` service running as the `backend-team` service account. Istio
supports services running on Kubernetes containers, virtual machines, and
bare-metal machines.

{{< image width="60%" ratio="52.44%"
    link="./auth.svg"
    alt="Components making up the Istio security model."
    caption="Istio Security Architecture"
    >}}

As illustrated in the diagram, Istio uses secret volume mounts to deliver
keys and certificates from Citadel to Kubernetes containers. For services
running on VMs or bare-metal machines, we introduce a node agent, which is a
process running on each VM or bare-metal machine. The node agent generates the
private key and the CSR (Certificate Signing Request) locally, sends the CSR to
Citadel for signing, and delivers the generated certificate together with the
private key to Envoy.

## Mutual TLS authentication

### Identity

Istio uses [Kubernetes service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
to identify who runs the service:

- A service account in Istio has the format:
  `spiffe://\<_domain_\>/ns/\<_namespace_>/sa/\<_serviceaccount_\>`.

    - Replace `_domain_` with `_cluster.local_`. We will support customization
      of domain in the near future.
    - Replace `_namespace_` with the namespace of the Kubernetes service
      account.
    - Replace `_serviceaccount_` with the Kubernetes service account name.

- A service account is **the identity or role a workload runs as**. The service
  account represents that workload's privileges. For systems requiring strong
  security, neither a random string, such as a service name, label, etc., nor
  the deployed binary should identify the amount of privilege for a workload.
  For example, let's say we have a workload pulling data from a multi-tenant
  database. If Alice runs this workload, she pulls a different set of data than
  if Bob runs this workload.

- To enable strong security policies, service accounts offer the flexibility
  to identify a machine, a user, a workload, or a group of workloads. Different
  workloads can even run as the same service account.

- The service account a workload runs as won't change during the lifetime of
  the workload.

- With domain name constraint, you can ensure service account uniqueness.

### Communication security

Istio tunnels service-to-service communication through the client side
[Envoy](https://envoyproxy.github.io/envoy/) and the server side Envoy.
Istio secures end-to-end communication via:

- **Local TCP** connections between the service and Envoy.

- **Mutual TLS** connections between proxies.

- **Secure Naming**: during the handshake process, the client side Envoy checks
  that the service account the server side certificate provided is allowed
  to run the target service.

### Key management

Istio supports services running on Kubernetes pods, virtual machines, and
bare-metal machines. We use different key provisioning mechanisms for each
scenario.

For services running on Kubernetes pods, the per-cluster Citadel, acting as
*Certificate Authority*, automates the key and certificate management process.
Citadel mainly performs four critical operations:

- **Generate** a [SPIFFE](https://spiffe.github.io/docs/svid) key and
  certificate pair for each service account

- **Distribute** a key and certificate pair to each pod according to the
  service account

- **Rotate** keys and certificates periodically

- **Revoke** a specific key and certificate pair when necessary

For services running on VMs or bare-metal machines, Citadel performs the above
four operations together with node agents.

### Workflow

The Istio security workflow consists of two phases: deployment and runtime. The
deployment phase is different for the workflow in Kubernetes and for the
workflow in VMs or bare-metal machines. However, once the key and certificate
are deployed, the runtime phase is the same. The following sections briefly
cover the workflow.

#### Deployment phase in Kubernetes

1. Citadel watches the Kubernetes API Server.

1. Citadel creates a [SPIFFE](https://spiffe.github.io/docs/svid) key and
   certificate pair for each of the existing and new service accounts.

1. Citadel sends them to the API Server.

1. When a pod is created, the API Server mounts the key and certificate pair
   according to the service account using
   [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/).

1. [Pilot](/docs/concepts/traffic-management/#pilot-and-envoy) generates the
   configuration file with the proper key, certificate, and secure naming
   information, which defines what service account(s) can run a certain
   service, and passes the configuration on to Envoy.

#### Deployment phase in VMs or bare-metal Machines

1. Citadel creates a gRPC service to take the CSR.

1. The node agent creates the private key and CSR

1. The node agent sends the CSR to Citadel for signing.

1. Citadel validates the credentials carried in the CSR

1. Citadel signs the CSR to generate the certificate.

1. The node agent sends both, the certificate received from Citadel and the
   private key, to Envoy.

1. The above CSR process repeats periodically for rotation.

#### Runtime phase

1. The outbound traffic from a client service is rerouted to its local Envoy.

1. The client side Envoy starts a mutual TLS handshake with the server side
   Envoy. During the handshake, it also does a secure naming check to verify
   that the service account presented in the server certificate can run the
   server service.

1. The client side Envoy and the server side Envoy establish a mutual TLS
   connection.

1. The client side Envoy forwards the traffic to the server side Envoy

1. The server side Envoy forwards the traffic to the server service
   through local TCP connections.

### Best practices

In this section, we provide a few deployment guidelines and discuss a
real-world scenario.

#### Deployment guidelines

If there are multiple service operators, a.k.a.
[SREs](https://en.wikipedia.org/wiki/Site_reliability_engineering)),
deploying different services in a medium- or large-size cluster, we recommend
creating a separate
[namespace](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/)
for each SRE team to isolate their access. For example, you can create a
`team1-ns` namespace for `team1`, and `team2-ns` namespace for `team2`, such
that both teams can't access each other's services.

> {{< warning_icon >}} If Citadel is compromised, all its managed keys and certificates in the
cluster may be exposed. We **strongly** recommend running Citadel in a
dedicated namespace, for example `istio-citadel-ns`, to restrict access to
the cluster to only administrators.

#### Example

Let us consider a three-tier application with three services: `photo-frontend`,
`photo-backend`, and `datastore`. The photo SRE team manages the
`photo-frontend` and `photo-backend` services while the datastore SRE team
manages the `datastore` service. The `photo-frontend` can access
`photo-backend`, and the `photo-backend` service can access `datastore`.
However, the `photo-frontend` service cannot access `datastore`.

In this scenario, a cluster administrator creates three namespaces:
`istio-citadel-ns`, `photo-ns`, and `datastore-ns`. The administrator has
access to all namespaces and each team only has access to its own namespace.
The photo SRE team creates two service accounts to run `photo-frontend` and
`photo-backend` respectively in the `photo-ns` namespace. The datastore SRE
team creates one service account to run the `datastore` service in the
`datastore-ns` namespace. Moreover, we need to enforce the service access
control in [Istio Mixer](/docs/concepts/policies-and-telemetry/) such that
`photo-frontend` cannot access datastore.

In this setup, Citadel can provide both key  management and certificate
management for all namespaces and isolate microservice deployments from each
other.

## Authentication

Istio provides two types of authentication:

- Transport authentication, also known as service-to-service authentication:
  verifies the direct client making the connection. Istio offers mutual TLS
  (mTLS) as a full stack solution for transport authentication. You can
  easily turn on this feature without requiring service code changes. This
  solution:

    - Provides each service with a strong identity representing its role to
      enable interoperability across clusters and clouds.
    - Secures service-to-service communication and end-user-to-service
      communication.
    - Provides a key management system to automate key and certificate
      generation, distribution, rotation, and revocation.

- Origin authentication, also known as end-user authentication: verifies the
  original client making the request as an end-user or device. Istio
  supports authentication with JSON Web Token (JWT) validation.

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
the [PKI and identity section](/docs/concepts/security/#identity).
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
[PKI and identity section](/docs/concepts/security/mutual-tls/).

{{< image width="60%" ratio="67.12%"
    link="./authn.svg"
    caption="Authentication Architecture"
    >}}

Istio outputs identities with both types of authentication, as well as other
claims in the credential if applicable, to the next layer:
[authorization](/docs/concepts/security/#authorization). Additionally,
operators can specify which identity, either from transport or origin
authentication, should Istio use as ‘the principal’.

### Authentication policies

This section provides more details about how Istio authentication policies
work. As you’ll remember from the [Architecture section](/docs/concepts/security/#authentication-architecture),
authentication policies apply to requests that a service **receives**. To
specify client-side authentication rules in mutual TLS, you need to specify the
`TLSSettings` in the `DestinationRule`. You can find more information in our
[TLS settings reference docs](/docs/reference/config/istio.networking.v1alpha3/#TLSSettings).
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

- Mesh-scope policy is specified with a value of `"MeshPolicy"` for the `kind`
  field and the name `"default"`. For example:

    {{< text yaml >}}
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "MeshPolicy"
    metadata:
      name: "default"
    spec:
      peers:
      * mtls: {}
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
      + mtls: {}
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

An authentication policy’s targets specify the service or services to which the
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

#### Transport authentication

The `peers:` section defines the authentication methods and associated
parameters supported for transport authentication in a policy. The section can
list more than one method and only one method must be satisfied for the
authentication to pass. However, as of the Istio 0.7 release, the only
transport authentication method currently supported is mutual TLS. If you don't
need transport authentication, skip this section entirely.

The following example shows the `peers:` section enabling transport
authentication using mutual TLS.

{{< text yaml >}}
 peers:
  - mtls: {}
{{< /text >}}

Currently, the mutual TLS setting doesn’t require any parameters. Hence,
`-mtls: {}`, `- mtls:` or `- mtls: null` declarations are treated the same. In
the future, the mutual TLS setting may carry arguments to provide different
mutual TLS implementations.

#### Origin authentication

The `origins:` section defines authentication methods and associated parameters
supported for origin authentication. Istio only supports JWT origin
authentication. However, a policy can list multiple JWTs by different issuers.
Similar to peer authentication, only one of the listed methods must be
satisfied for the authentication to pass.

The following example policy specifies an `origins:` section for origin
authentication that accepts JWTs issued by Google:

{{< text yaml >}}
origins:
- jwt:
    issuer: "https://accounts.google.com"
    jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
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
to the endpoints almost in real time. However, Istio can't guarantee that all
endpoints receive a new policy at the same time. The following are
recommendations to avoid disruption when updating your authentication policies:

- To enable or disable mutual TLS: Use a temporary policy with a `mode:` key
  and a `PERMISSIVE` value. This configures receiving services to accept both
  types of traffic: plain text and TLS. Thus, no request is dropped. Once all
  clients switch to the expected protocol, with or without mTLS, you can
  replace the `PERMISSIVE` policy with the final policy. For more information,
  visit the [Mutual TLS Migration tutorial](/docs/tasks/security/mtls-migration).

{{< text yaml >}}
peers:
- mTLS:
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

### Authorization architecture

{{< image width="90%" ratio="56.25%"
    link="./authz.svg"
    alt="Istio Authorization"
    caption="Istio Authorization Architecture"
    >}}

The above diagram shows the basic Istio authorization architecture. Operators
specify Istio authorization policies using `.yaml` files. Once deployed, Istio
saves the policies in the `Istio Config Store`.

Pilot watches for changes to Istio authorization policies. It fetches the
updated authorization policies if it sees any changes. Pilot distributes Istio
authorization policies to the Envoy proxies that are co-located with the
service instances.

Each Envoy proxy runs an authorization engine that authorizes requests at
runtime. When a request comes to the proxy, the authorization engine evaluates
the request context against the current authorization policies, and returns the
authorization result, `ALLOW` or `DENY`.

### Enabling authorization

You enable Istio Authorization using a `RbacConfig` object. The `RbacConfig`
object is a mesh-wide singleton with a fixed name value of `default`. You can
only use one `RbacConfig` instance in the mesh. Like other Istio configuration
objects, `RbacConfig` is defined as a
Kubernetes `CustomResourceDefinition`
[(CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) object.

In the `RbacConfig` object, the operator can specify a `mode` value, which can
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
apiVersion: "config.istio.io/v1alpha2"
kind: RbacConfig
metadata:
  name: default
  namespace: istio-system
spec:
  mode: ON_WITH_INCLUSION
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

- **who** refers to the `subjects:` section in `ServiceRoleBinding`.
- **what** refers to the `permissions:` section in `ServiceRole`.
- **which conditions** refers to the `conditions:` section you can specify with
  the [Istio attributes](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)
  in either `ServiceRole` or `ServiceRoleBinding`.

#### `ServiceRole`

A `ServiceRole` specification includes a list of `rules:`, AKA permissions.
Each rule has the following standard fields:

- **`services:`** A list of service names. You can set the value to `*` to
  include all services in the specified namespace.

- **`methods:`** A list of HTTP method names, for permissions on gRPC requests,
  the HTTP verb is always `POST`. You can set the value to `*` to include all
  HTTP methods.

- **`paths:`** HTTP paths or gRPC methods. The gRPC methods must be in the
   form of `/packageName.serviceName/methodName` and are case sensitive.

A `ServiceRole` specification only applies to the namespace specified in the
`metadata` section. The `services:` and `methods:` fields are required in a
rule. `paths:` is optional. If a rule is not specified or if it is set to `*`,
it applies to any instance.

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
    methods: ["*"]
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

In a `ServiceRole`, the combination of `namespace:` + `services:` + `paths:` +
`methods:` defines **how a service or services are accessed**. In some
situations, you may need to specify additional conditions for your rules. For
example, a rule may only apply to a certain **version** of a service, or only
apply to services with a specific **label**, like `"foo"`. You can easily
specify these conditions using `constraints:`.

For example, the following `ServiceRole` definition adds a constraint that
`request.headers["version"]` is either `"v1"` or `"v2"` extending the previous
`products-viewer` role. The supported `key:` values of a constraint are listed
in the [constraints and properties page](/docs/reference/config/authorization/constraints-and-properties/).
In the case that the attribute is a `map`, for example `request.headers`, the
`key` is an entry in the map, for example `request.headers["version"]`.

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
-  A list of **`subjects:`** that are assigned to the role.

You can either explicitly specify a *subject* with a `user:` or with a set of
`properties:`.  A *property* in a `ServiceRoleBinding` *subject* is similar to
a *constraint* in a `ServiceRole` specification. A *property* also lets you use
conditions to specify a set of accounts assigned to this role. It contains a
`key:` and its allowed *values*. The supported `key:` values of a constraint
are listed in the
[constraints and properties page](/docs/reference/config/authorization/constraints-and-properties/).

The following example shows a `ServiceRoleBinding` named
`test-binding-products`, which binds two subjects to the `ServiceRole` named
`"product-viewer"` and has the following `subjects:`

- A service account representing service **a**, `"service-account-a"`.
- A service account representing the Ingress service
  `"istio-ingress-service-account"` **and** where the JWT `"email"` claim is
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
    - request.auth.claims[email]: "a@foo.com"
  roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}

In case you want to make a services publicly accessible, you can set the
`subject` to `user: "*"`. This value assigns the `ServiceRole` to **all** users
and services, for example:

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
