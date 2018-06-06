---
title: Istio Role-Based Access Control (RBAC)
description: Describes Istio RBAC which provides access control for services in Istio Mesh.
weight: 20
---

## Overview

Istio Role-Based Access Control (RBAC) provides namespace-level, service-level, method-level access control for services in the Istio Mesh.
It features:

* Role-Based semantics, which is simple and easy to use.

* Service-to-service and endUser-to-Service authorization.

* Flexibility through custom properties support in roles and role-bindings.

## Architecture

The diagram below shows the Istio RBAC architecture. Operators specify Istio RBAC policies. The policies are saved in
the Istio config store.

{{< image width="80%" ratio="56.25%"
    link="../img/IstioRBAC.svg"
    alt="Istio RBAC"
    caption="Istio RBAC Architecture"
    >}}

The Istio RBAC engine does two things:
* **Fetch RBAC policy.** Istio RBAC engine watches for changes on RBAC policy. It fetches the updated RBAC policy if it sees any changes.
* **Authorize Requests.** At runtime, when a request comes, the request context is passed to Istio RBAC engine. RBAC engine evaluates the
request context against the RBAC policies, and returns the authorization result (ALLOW or DENY).

### Request context

In the current release, the Istio RBAC engine is implemented as a [Mixer adapter](/docs/concepts/policies-and-telemetry/overview/#adapters).
The request context is provided as an instance of the
[authorization template](/docs/reference/config/policy-and-telemetry/templates/authorization/). The request context
 contains all the information about the request and the environment that an authorization module needs to know. In particular, it has two parts:

* **subject** contains a list of properties that identify the caller identity, including `"user"` name/ID, `"groups"` the subject belongs to,
or any additional properties about the subject such as namespace, service name.
* **action** specifies "how a service is accessed". It includes `"namespace"`, `"service"`, `"path"`, `"method"` that the action is being taken on,
and any additional properties about the action.

Below we show an example "requestcontext".
```yaml
apiVersion: "config.istio.io/v1alpha2"
kind: authorization
metadata:
  name: requestcontext
  namespace: istio-system
spec:
  subject:
    user: source.user | ""
    groups: ""
    properties:
      service: source.service | ""
      namespace: source.namespace | ""
  action:
    namespace: destination.namespace | ""
    service: destination.service | ""
    method: request.method | ""
    path: request.path | ""
    properties:
      version: request.headers["version"] | ""
```

## Istio RBAC policy

Istio RBAC introduces `ServiceRole` and `ServiceRoleBinding`, both of which are defined as Kubernetes CustomResourceDefinition (CRD) objects.

* **`ServiceRole`** defines a role for access to services in the mesh.
* **`ServiceRoleBinding`** grants a role to subjects (e.g., a user, a group, a service).

### `ServiceRole`

A `ServiceRole` specification includes a list of rules. Each rule has the following standard fields:
* **services**: A list of service names, which are matched against the `action.service` field of the "requestcontext".
* **methods**: A list of method names which are matched against the `action.method` field of the "requestcontext". In the above "requestcontext",
this is the HTTP or gRPC method. Note that gRPC methods are formatted in the form of "packageName.serviceName/methodName" (case sensitive).
* **paths**: A list of HTTP paths which are matched against the `action.path` field of the "requestcontext". It is ignored in gRPC case.

A `ServiceRole` specification only applies to the **namespace** specified in `"metadata"` section. The "services" and "methods" are required
fields in a rule. "paths" is optional. If not specified or set to "*", it applies to "any" instance.

Here is an example of a simple role "service-admin", which has full access to all services in "default" namespace.

```yaml
apiVersion: "config.istio.io/v1alpha2"
kind: ServiceRole
metadata:
  name: service-admin
  namespace: default
spec:
  rules:
  - services: ["*"]
    methods: ["*"]
```

Here is another role "products-viewer", which has read ("GET" and "HEAD") access to service "products.default.svc.cluster.local"
in "default" namespace.

```yaml
apiVersion: "config.istio.io/v1alpha2"
kind: ServiceRole
metadata:
  name: products-viewer
  namespace: default
spec:
  rules:
  - services: ["products.default.svc.cluster.local"]
    methods: ["GET", "HEAD"]
```

In addition, we support **prefix matching** and **suffix matching** for all the fields in a rule. For example, you can define a "tester" role that
has the following permissions in "default" namespace:
* Full access to all services with prefix "test-" (e.g, "test-bookstore", "test-performance", "test-api.default.svc.cluster.local").
* Read ("GET") access to all paths with "/reviews" suffix (e.g, "/books/reviews", "/events/booksale/reviews", "/reviews")
in service "bookstore.default.svc.cluster.local".

```yaml
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
```

In `ServiceRole`, the combination of "namespace"+"services"+"paths"+"methods" defines "how a service (services) is allowed to be accessed".
In some situations, you may need to specify additional constraints that a rule applies to. For example, a rule may only applies to a
certain "version" of a service, or only applies to services that are labeled "foo". You can easily specify these constraints using
custom fields.

For example, the following `ServiceRole` definition extends the previous "products-viewer" role by adding a constraint on service "version"
being "v1" or "v2". Note that the "version" property is provided by `"action.properties.version"` in "requestcontext".

```yaml
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
    - key: "version"
      values: ["v1", "v2"]
```

### `ServiceRoleBinding`

A `ServiceRoleBinding` specification includes two parts:
* **roleRef** refers to a `ServiceRole` resource **in the same namespace**.
* A list of **subjects** that are assigned the role.

A subject can either be a "user", or a "group", or is represented with a set of "properties". Each entry ("user" or "group" or an entry
in "properties") must match one of fields ("user" or "groups" or an entry in "properties") in the "subject" part of the "requestcontext"
instance.

Here is an example of `ServiceRoleBinding` resource "test-binding-products", which binds two subjects to ServiceRole "product-viewer":
* user "alice@yahoo.com".
* "reviews.abc.svc.cluster.local" service in "abc" namespace.

```yaml
apiVersion: "config.istio.io/v1alpha2"
kind: ServiceRoleBinding
metadata:
  name: test-binding-products
  namespace: default
spec:
  subjects:
  - user: "alice@yahoo.com"
  - properties:
      service: "reviews.abc.svc.cluster.local"
      namespace: "abc"
  roleRef:
    kind: ServiceRole
    name: "products-viewer"
```

In the case that you want to make a service(s) publicly accessible, you can use set the subject to `user: "*"`. This will assign a `ServiceRole`
to all users/services.

```yaml
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
```

## Enabling Istio RBAC

Istio RBAC can be enabled by adding the following Mixer adapter rule. The rule has two parts. The first part defines a RBAC handler.
It has two parameters, `"config_store_url"` and `"cache_duration"`.
* The `"config_store_url"` parameter specifies where RBAC engine fetches RBAC policies. The default value for `"config_store_url"` is
`"k8s://"`, which means Kubernetes API server. Alternatively, if you are testing RBAC policy locally, you may set it to a local directory
such as `"fs:///tmp/testdata/configroot"`.
* The `"cache_duration"` parameter specifies the duration for which the authorization results may be cached on Mixer client (i.e., Istio proxy).
The default value for `"cache_duration"` is 1 minute.

The second part defines a rule, which specifies that the RBAC handler should be invoked with the "requestcontext" instance [defined
earlier in the document](#request-context).

In the following example, Istio RBAC is enabled for "default" namespace. And the cache duration is set to 30 seconds.

```yaml
apiVersion: "config.istio.io/v1alpha2"
kind: rbac
metadata:
  name: handler
  namespace: istio-system
spec:
  config_store_url: "k8s://"
  cache_duration: "30s"
---
apiVersion: "config.istio.io/v1alpha2"
kind: rule
metadata:
  name: rbaccheck
  namespace: istio-system
spec:
  match: destination.namespace == "default"
  actions:
  # handler and instance names default to the rule's namespace.
  - handler: handler.rbac
    instances:
    - requestcontext.authorization
```

## What's next

Try out the [Istio RBAC with Bookinfo](/docs/tasks/security/role-based-access-control/) sample.
