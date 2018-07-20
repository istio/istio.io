---
title: Micro-Segmentation with Istio Authorization
description: Describe Istio authorization characterics and how it can be used for different use cases.
publishdate: 2018-07-20
subtitle:
attribution: Limin Wang
weight: 87
---

[Istio's authorization feature](/docs/concepts/security/#authorization), also known as Istio Role Based Access Control,
provides access control for services in an Istio mesh. Istio authorization is Istio’s native authorization support.
It can be used on any platform that Istio supports. It features:

* Authorization at different levels of granularity, including namespace level, service level, and method level.
* Service-to-service and end-user-to-service authorization.
* High performance, as it is enforced natively on Envoy.
* Role-based semantics, which makes it easy to use.
* High flexibility as it allows users to define conditions using
[combination of Istio attributes](/docs/reference/config/authorization/constraints-and-properties/).

In this blog post, we first elaborate Istio authorization characteristics, next we show how you could use Istio
authorization policy in different use cases.

## Istio Authorization Characteristics

### RPC Level Authorization

Istio authorization feature provides RPC level authorization. Specifically, it controls “who can access my `bookstore` service”,
or “who can access method `getBook` in my `bookstore` service”. It is not designed to control access to application-specific
resource instances, like access to “storage bucket X” or access to “3rd book on 2nd shelf”. Today this kind of application
specific access control logic needs to be handled by the application itself.

### Role Based Access Control + Conditions

Istio authorization is Role-Based Access Control (RBAC) system. Compared to Attribute-Based Access Control (ABAC),
RBAC has the following advantages:

* **Roles allow grouping of attributes.** Roles are groups of permissions, which specifies the actions you are allowed
to perform on a system. Users are grouped based on the roles within an organization. You can define the roles and reuse
them for different cases.

* **It is easier to understand and reason about who has access.** The RBAC concepts maps naturally to the business concepts.
For example, a DB admin may have all access to DB backend services, while a web client may only be able to view the
frontend service.

* **It reduces unintentional errors.** RBAC policies make the originally complicated security changes easy. You won't have
duplicate configurations in multiple places and later forget to update some of them when you need to make changes.

On the other hand, Istio authorization is not a traditional RBAC system. It also allows users to define **conditions** using
[combination of Istio attributes](/docs/reference/config/authorization/constraints-and-properties/). This gives Istio
authorization plenty of flexibility to express complex access control policies. In fact, **the “RBAC + conditions” model
that Istio authorization adopts, has all the benefits an RBAC system has, and supports the level of flexibility that
normally an ABAC system provides.** We will show some examples in the [Examples section](#examples).

### High Performance

Because of its simple semantics, Istio authorization is enforced on Envoy as a native authorization support. At runtime, the
authorization decision is completely done locally inside an Envoy filter, without dependency to any external module.
This allows Istio authorization to achieve high performance and availability.

### Work With/Without Primary Identities

Like any other RBAC system, Istio authorization is identity aware. In Istio authorization policy, there is a primary
identity called `user`, which represents the principal of the client.

In addition to the primary identity, you can also specify any conditions that define the identities. For example,
you can specify the client identity as “user Alice calling from Bookstore frontend service”, in which case,
you have a combined identity of the calling service (`Bookstore frontend`) and the end user (`Alice`).

However, strongly authenticated identity is not required for using Istio authorization. Istio authorization work with or
without identities. If you are working with a legacy system, you may not have mutual TLS or JWT authentication setup for
your mesh. In this case, the only way to identify the client is, say, through IP. You can still use Istio authorization
to control which IP addresses or IP ranges are allowed to access your service.

## Examples

In [Istio authorization task page](/docs/tasks/security/role-based-access-control/), we show how you can use Istio
authorization feature to control namespace level and service level access using [BookInfo application](/docs/examples/bookinfo/).
In this section, we will walk through a few additional examples to show how you can achieve micro-segmentation with
Istio authorization.

### Namespace Level Segmentation via RBAC + Conditions

Suppose you have services in `frontend` namespace and `backend` namespace. You would like to allow all your services
in `frontend` namespace to access all services that are marked `external` in `backend` namespace.

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
    - key: “destination.labels[visibility]”
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
      source.namespace: “frontend”
  roleRef:
    kind: ServiceRole
    name: "external-api-caller"
{{< /text >}}

The `ServiceRole` and `ServiceRoleBinding` above expressed “*who* is allowed to do *what* under *which conditions*”
(RBAC + conditions). Specifically,

* **“who”** is services in `frontend` namespace.
* **“what”** is to call services in `backend` namespace.
* **“conditions”** is `visibility` label of the destination service is `external`.

### Service/Method Level Isolation With/Without Primary Identities

Let’s look at another example where we show finer grained access control at service/method level. We first define a
`book-reader` `ServiceRole` that allows READ access to `/books/*` resource in `bookstore` service.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: book-reader
  namespace: default
spec:
  rules:
  - services: ["bookstore.default.svc.cluster.local"]
    paths: [“/books/*”]
    methods: ["GET”]
{{< /text >}}

#### Using authenticated client identities

Suppose you want to grant this `book-reader` role to your `bookstore-frontend` service. If you have enabled
[mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) for your mesh, you can use a
service account to identify your `bookstore-frontend` service. Granting the `book-reader` role to `bookstore-frontend`
service can be done by creating a `ServiceRoleBinding` as shown below.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: book-reader
  namespace: default
spec:
  subjects:
  - user: “spiffe://cluster.local/ns/default/sa/bookstore-frontend”
  roleRef:
    kind: ServiceRole
    name: "book-reader"
{{< /text >}}

You may want to restrict this further by adding a condition that “only users who belong to `qualified-reviewer` group are
allowed to read books”. In this case, the combination of the client service identity (`bookstore-frontend`) and the end
user identity (`qualified-reviewer`) is used in the authorization policy.

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: book-reader
  namespace: default
spec:
  subjects:
  - user: “spiffe://cluster.local/ns/default/sa/bookstore-frontend”
    properties:
      request.auth.claims[group]: “qualified-reviewer”
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
It adopts “RBAC + conditions” model, which makes it easy to use and understand as an RBAC system, while providing the level of
flexibility that an ABAC system normally provides. Istio authorization achieves high performance as it is enforced
natively on Envoy. While it provides the best security by working together with
[Istio authentication features](/docs/concepts/security/#authentication), Istio authorization can also be used to
provide access control for legacy systems that do not have authentication.
