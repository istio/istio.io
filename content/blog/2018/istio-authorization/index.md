---
title: Micro-Segmentation with Istio Authorization
description: Describe Istio's authorization feature and how to use it in various use cases.
publishdate: 2018-07-20
subtitle:
attribution: Limin Wang
weight: 87
keywords: [authorization,Role Based Access Control,security]
---

Micro-segmentation is a security technique that creates secure zones in cloud deployments and allows organizations to
isolate workloads from one another and secure them individually.
[Istio's authorization feature](/docs/concepts/security/#authorization), also known as Istio Role Based Access Control,
provides micro-segmentation for services in an Istio mesh. It features:

* Authorization at different levels of granularity, including namespace level, service level, and method level.
* Service-to-service and end-user-to-service authorization.
* High performance, as it is enforced natively on Envoy.
* Role-based semantics, which makes it easy to use.
* High flexibility as it allows users to define conditions using
[combinations of attributes](/docs/reference/config/authorization/constraints-and-properties/).

In this blog post, you'll learn about the main authorization features and how to use them in different situations.

## Characteristics

### RPC level authorization

Authorization is performed at the level of individual RPCs. Specifically, it controls "who can access my `bookstore` service”,
or "who can access method `getBook` in my `bookstore` service”. It is not designed to control access to application-specific
resource instances, like access to "storage bucket X” or access to "3rd book on 2nd shelf”. Today this kind of application
specific access control logic needs to be handled by the application itself.

### Role-based access control with conditions

Authorization is a [role-based access control (RBAC)](https://en.wikipedia.org/wiki/Role-based_access_control) system,
contrast this to an [attribute-based access control (ABAC)](https://en.wikipedia.org/wiki/Attribute-based_access_control)
system. Compared to ABAC, RBAC has the following advantages:

* **Roles allow grouping of attributes.** Roles are groups of permissions, which specifies the actions you are allowed
to perform on a system. Users are grouped based on the roles within an organization. You can define the roles and reuse
them for different cases.

* **It is easier to understand and reason about who has access.** The RBAC concepts map naturally to business concepts.
For example, a DB admin may have all access to DB backend services, while a web client may only be able to view the
frontend service.

* **It reduces unintentional errors.** RBAC policies make otherwise complex security changes easier. You won't have
duplicate configurations in multiple places and later forget to update some of them when you need to make changes.

On the other hand, Istio's authorization system is not a traditional RBAC system. It also allows users to define **conditions** using
[combinations of attributes](/docs/reference/config/authorization/constraints-and-properties/). This gives Istio
flexibility to express complex access control policies. In fact, **the "RBAC + conditions” model
that Istio authorization adopts, has all the benefits an RBAC system has, and supports the level of flexibility that
normally an ABAC system provides.** You'll see some [examples](#examples) below.

### High performance

Because of its simple semantics, Istio authorization is enforced on Envoy as a native authorization support. At runtime, the
authorization decision is completely done locally inside an Envoy filter, without dependency to any external module.
This allows Istio authorization to achieve high performance and availability.

### Work with/without primary identities

Like any other RBAC system, Istio authorization is identity aware. In Istio authorization policy, there is a primary
identity called `user`, which represents the principal of the client.

In addition to the primary identity, you can also specify any conditions that define the identities. For example,
you can specify the client identity as "user Alice calling from Bookstore frontend service”, in which case,
you have a combined identity of the calling service (`Bookstore frontend`) and the end user (`Alice`).

To improve security, you should enable [authentication features](/docs/concepts/security/#authentication),
and use authenticated identities in authorization policies. However, strongly authenticated identity is not required
for using authorization. Istio authorization works with or without identities. If you are working with a legacy system,
you may not have mutual TLS or JWT authentication setup for your mesh. In this case, the only way to identify the client is, for example,
through IP. You can still use Istio authorization to control which IP addresses or IP ranges are allowed to access your service.

## Examples

The [authorization task](/docs/tasks/security/role-based-access-control/) shows you how to
use Istio's authorization feature to control namespace level and service level access using the
[BookInfo application](/docs/examples/bookinfo/). In this section, you'll see more examples on how to achieve
micro-segmentation with Istio authorization.

### Namespace level segmentation via RBAC + conditions

Suppose you have services in the `frontend` and `backend` namespaces. You would like to allow all your services
in the `frontend` namespace to access all services that are marked `external` in the `backend` namespace.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: external-api-caller
  namespace: backend
spec:
  rules:
  - services: ["*"]
    methods: ["*”]
    constraints:
    - key: "destination.labels[visibility]”
      values: ["external"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: external-api-caller
  namespace: backend
spec:
  subjects:
  - properties:
      source.namespace: "frontend”
  roleRef:
    kind: ServiceRole
    name: "external-api-caller"
{{< /text >}}

The `ServiceRole` and `ServiceRoleBinding` above expressed "*who* is allowed to do *what* under *which conditions*”
(RBAC + conditions). Specifically:

* **"who”** are the services in the `frontend` namespace.
* **"what”** is to call services in `backend` namespace.
* **"conditions”** is the `visibility` label of the destination service having the value `external`.

### Service/method level isolation with/without primary identities

Here is another example that demonstrates finer grained access control at service/method level. The first step
 is to define a `book-reader` `ServiceRole` that allows READ access to `/books/*` resource in `bookstore` service.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: book-reader
  namespace: default
spec:
  rules:
  - services: ["bookstore.default.svc.cluster.local"]
    paths: ["/books/*”]
    methods: ["GET”]
{{< /text >}}

#### Using authenticated client identities

Suppose you want to grant this `book-reader` role to your `bookstore-frontend` service. If you have enabled
[mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) for your mesh, you can use a
service account to identify your `bookstore-frontend` service. Granting the `book-reader` role to the `bookstore-frontend`
service can be done by creating a `ServiceRoleBinding` as shown below:

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: book-reader
  namespace: default
spec:
  subjects:
  - user: "spiffe://cluster.local/ns/default/sa/bookstore-frontend”
  roleRef:
    kind: ServiceRole
    name: "book-reader"
{{< /text >}}

You may want to restrict this further by adding a condition that "only users who belong to the `qualified-reviewer` group are
allowed to read books”. The `qualified-reviewer` group is the end user identity that is authenticated by
[JWT authentication](/docs/concepts/security/#authentication). In this case, the combination of the client service identity
(`bookstore-frontend`) and the end user identity (`qualified-reviewer`) is used in the authorization policy.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: book-reader
  namespace: default
spec:
  subjects:
  - user: "spiffe://cluster.local/ns/default/sa/bookstore-frontend”
    properties:
      request.auth.claims[group]: "qualified-reviewer”
  roleRef:
    kind: ServiceRole
    name: "book-reader"
{{< /text >}}

#### Client does not have identity

Using authenticated identities in authorization policies is strongly recommended for security. However, if you have a
legacy system that does not support authentication, you may not have authenticated identities for your services.
You can still use Istio authorization to protect your services even without authenticated identities. The example below
shows that you can specify allowed source IP range in your authorization policy.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: book-reader
  namespace: default
spec:
  subjects:
  - properties:
      source.ip: 10.20.0.0/9
  roleRef:
    kind: ServiceRole
    name: "book-reader"
{{< /text >}}

## Summary

Istio’s authorization feature provides authorization at namespace-level, service-level, and method-level granularity.
It adopts "RBAC + conditions” model, which makes it easy to use and understand as an RBAC system, while providing the level of
flexibility that an ABAC system normally provides. Istio authorization achieves high performance as it is enforced
natively on Envoy. While it provides the best security by working together with
[Istio authentication features](/docs/concepts/security/#authentication), Istio authorization can also be used to
provide access control for legacy systems that do not have authentication.
