---
title: Introducing the Istio v1beta1 Authorization Policy
description: Introduction, motivation and design principles for the Istio v1beta1 Authorization Policy.
publishdate: 2019-11-12
subtitle:
attribution: Yangmin Zhu (Google)
keywords: [security, RBAC, access control, authorization]
target_release: 1.4
---

Up until now, Istio has provided the role based access control (RBAC) policy for enforcing access control
on {{< gloss "service" >}}services{{< /gloss >}} using three configuration resources: `ClusterRbacConfig`, `ServiceRole` and `ServiceRoleBinding`.
With this API, users have been able to enforce access control in mesh-level, namespace-level and
service-level. Like any other RBAC policy, Istio RBAC uses the same concept of role and binding for granting
permissions to identities.

While this functionality has proven to be working for many customers, we have also realized there are many
things that could be improved in the alpha policy.

For example, some users have had the wrong impression that the enforcement happens in service-level because
`ServiceRole` uses service to specify where to apply the policy, however, the policy is actually applied
in workload-level, the service is only used to find the corresponding {{< gloss "workload" >}}workload{{< /gloss >}}. This has some big impact, especially
when multiple services are referring to the same workload. A `ServiceRole` for service A will also affect
service B if the two services are referring to the same workload, this surprises customers and could result in
misconfigurations.

The other example is it's a little bit hard to maintain and manage the Istio RBAC configurations because user
needs to learn and manage three different resources in Istio RBAC. Istio has already had an issue that there
are too much CRDs to learn and manage, and the learning and maintenance burden of having three different configurations
in Istio RBAC turned out to be greater than its benefit.

To address these, and other issues, Istio 1.4 introduces the [`v1beta1` authorization policy](/docs/reference/config/authorization/authorization-policy/)
which will completely replace the previous `v1alpha1` RBAC policy going forward. The `v1beta1` policy provides
more features but is not backward compatible and will require manual conversion from the old API (we
will provide tool to help automate the conversion).

In this article, we will introduce the new `v1beta1` authorization policy, talk about its design principles
and the migration from `v1alpha1` RBAC policy.

## Design principles

A few key design principles played a role in the `v1beta1` authorization policy:

* Align with [Istio Configuration Model](https://goo.gl/x3STjD) for better clarity on the policy target.
The configuration model provides a unified way for configuration hierarchy, resolution, target selection and etc.

* Improve user experience by simplifying the API. It's much easier to manage one custom resource
definition (CRD) that includes all access control specification instead of looking at multiple
different CRDs.

* Support more use cases without introducing much complexity. For example, allow the policy
to be applied on Ingress/Egress gateway to enforce access control for traffic entering/exiting the mesh.

## `AuthorizationPolicy`

An [`AuthorizationPolicy` custom resource](/docs/reference/config/authorization/authorization-policy/)
enables access control on workloads. This section gives a high level overview of the
new changes in the `v1beta1` authorization policy.

An `AuthorizationPolicy` includes a `selector` and a list of `rule`. The `selector`
specifies which workload to apply the policy and the list of `rule` specifies the
detail access control rule for the workload.

The `rule` is additive which means a request is allowed if any of the `rule` allows
the request. Each `rule` includes a list of `from`, `to` and `when` which specifies **who**
is allowed to do **what** under which **conditions**.

The `selector` replaces the functionality provided by `ClusterRbacConfig`
and the `services` field in `ServiceRole`. The `rule` replaces the other fields
in the `ServiceRole` and `ServiceRoleBinding`.

This blog gives a high level overview of the `v1beta1` authorization policy, see
[authorization concept page](/docs/concepts/security/#authorization) for a detailed
in-depth explanation of the `v1beta1` authorization policy.

### Example

The following authorization policy applies to workloads with `app: httpbin` and
`version: v1` label in the `foo` namespace:

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

The policy allows principal `cluster.local/ns/default/sa/sleep` to access the workload
using `GET` method when the request includes a `version` header of value `v1` or `v2`.
Any requests not matched with the policy will be denied by default.

Assuming the `httpbin` service is defined like the following:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: foo
spec:
  selector:
    app: httpbin
    version: v1
  ports:
    # omitted
{{< /text >}}

You would need to configure three resources to achieve the same result in `v1alpha1`:

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ClusterRbacConfig
metadata:
  name: default
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    services: ["httpbin.foo.svc.cluster.local"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: httpbin
  namespace: foo
spec:
  rules:
  - services: ["httpbin.foo.svc.cluster.local"]
    methods: ["GET"]
    constraints:
    - key: request.headers[version]
      values: ["v1", "v2"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: httpbin
  namespace: foo
spec:
  subjects:
  - user: "cluster.local/ns/default/sa/sleep"
  roleRef:
    kind: ServiceRole
    name: "httpbin"
{{< /text >}}

### Workload selector

One major change in the `v1beta1` authorization policy is it now uses workload selector
to specify where to apply the policy. This is the same workload selector used in
the `Gateway`, `Sidecar` and `EnvoyFilter` configurations.

The workload selector makes it clear that the policy is applied and enforced on workloads
instead of services. If a policy applies to a workload that is used by multiple different
services, the same policy will affect the traffic to all the different services.

You can simply leave the `selector` empty to apply the policy to all workloads
in a namespace. The following policy applies to all workloads in the namespace `bar`:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: policy
 namespace: bar
spec:
 rules:
 # omitted
{{< /text >}}

### Root namespace

A policy in the root namespace applies to all workloads in the mesh in every namespaces.
The root namespace is configurable in the [`MeshConfig`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig)
and has the default value of `istio-system`.

For example, you installed Istio in `istio-system` namespace and deployed workloads in
`default` and `bookinfo` namespace. The root namespace is changed to `istio-config` from
the default value. The following policy will apply to workloads in every namespace
including `default`, `bookinfo` and the `istio-system`:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: policy
 namespace: istio-config
spec:
 rules:
 # omitted
{{< /text >}}

### Ingress/Egress Gateway support

The `v1beta1` authorization policy can also be applied on ingress/egress
gateway to enforce access control on traffic entering/leaving the mesh, you just
need to change the `selector` to make select the ingress/egress workload.

The following policy applies to workloads with the `app: istio-ingressgateway` label:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: ingress
 namespace: istio-system
spec:
 selector:
   matchLabels:
     app: istio-ingressgateway
 rules:
 # omitted
{{< /text >}}

Remember the authorization policy only applies to workloads in the same namespace as the
policy unless the policy is applied in the root namespace:

* If you don't change the default root namespace value (i.e. `istio-system`), the above policy
  will apply to workloads with the `app: istio-ingressgateway` label in **every** namespace.

* If you have changed the root namespace to a different value, the above policy will only
  apply to workloads with the `app: istio-ingressgateway` label only in the `istio-system` namespace.

### Comparison

The following table highlights the key differences between the old `v1alpha1` RBAC policies and
the new `v1beta1` authorization policy.

#### Feature

| Feature | `v1alpha1` RBAC policy | `v1beta1` Authorization Policy |
|---------|------------------------|--------------------------------|
| API stability | `alpha`: **No** backward compatible | `beta`: backward compatible **guaranteed** |
| Number of CRDs | Three: `ClusterRbacConfig`, `ServiceRole` and `ServiceRoleBinding` | Only One: `AuthorizationPolicy` |
| Policy target | **service** | **workload** |
| Deny-by-default behavior | Enabled **explicitly** by configuring `ClusterRbacConfig` | Enabled **implicitly** with `AuthorizationPolicy` |
| Ingress/Egress gateway support | Not supported | Supported |
| The `"*"` value in policy | Match all contents (empty and non-empty) | Match non-empty contents only |

The following tables show the relationship between the `v1alpha1` and `v1beta1` API.

#### `ClusterRbacConfig`

| `ClusterRbacConfig.Mode` | `AuthorizationPolicy` |
|---------------------|-----------------------|
| `OFF` | No policy applied |
| `ON` | A deny-all policy applied in root namespace |
| `ON_WITH_INCLUSION` | policies should be applied to namespaces or workloads included by `ClusterRbacConfig` |
| `ON_WITH_EXCLUSION` | policies should be applied to namespaces or workloads excluded by `ClusterRbacConfig` |

#### `ServiceRole`

| `ServiceRole` | `AuthorizationPolicy` |
|---------------|-----------------------|
| `services` | `selector` |
| `paths` | `paths` in `to` |
| `methods` | `methods` in `to` |
| `destination.ip` in constraint | Not supported |
| `destination.port` in constraint | `ports` in `to` |
| `destination.labels` in constraint | `selector` |
| `destination.namespace` in constraint | Replaced by the namespace of the policy, i.e. the `namespace` in metadata |
| `destination.user` in constraint | Not supported |
| `experimental.envoy.filters` in constraint | `experimental.envoy.filters` in `when` |
| `request.headers` in constraint | `request.headers` in `when` |

#### `ServiceRoleBinding`

| `ServiceRoleBinding` | `AuthorizationPolicy` |
|----------------------|-----------------------|
| `user`  | `principals` in `from` |
| `group` | `paths` in `to` |
| `source.ip` in property | `ipBlocks` in `from` |
| `source.namespace` in property | `namespaces` in `from` |
| `source.principal` in property | `principals` in `from` |
| `request.headers` in property | `request.headers` in `when` |
| `request.auth.principal` in property | `requestPrincipals` in `from` or `request.auth.principal` in `when` |
| `request.auth.audiences` in property | `request.auth.audiences` in `when` |
| `request.auth.presenter` in property | `request.auth.presenter` in `when` |
| `request.auth.claims` in property | `request.auth.claims` in `when` |

Beyond all the differences, the `v1beta1` policy is enforced by the same engine in Envoy
and supports the same authenticated identity (mutual TLS or JWT), condition and other
primitives (e.g. IP, port and etc.) as the `v1alpha1` policy.

## Future of the `v1alpha1` policy

The `v1alpha1` RBAC policy (`ClusterRbacConfig`, `ServiceRole`, and `ServiceRoleBinding`) is
deprecated by the `v1beta1` authorization policy and will not be supported from Istio 1.6 onwards.

Istio 1.4 and 1.5 will continue to support the `v1alpha1` RBAC policy to give you enough
time to move away from the alpha policies.

## Migration from the `v1alpha1` policy

Istio only supports one of the two versions for a given workload:

* If there is only `v1beta1` policy for a workload, the `v1beta1` policy will be used.
* If there is only `v1alpha1` policy for a workload, the `v1alpha1` policy will be used.
* If there are both `v1beta1` and `v1alpha1` policies for a workload, only the `v1beta1` policy will
be used and the the `v1alpha1` policy will be ignored.

### General Guideline

{{< warning >}}
When migrating to use `v1beta1` policy for a given workload, make sure the new `v1beta1` policy
covers all the existing `v1alpha1` policies applied for the workload because the `v1alpha1`
policies applied for the workload will be ignored after you applied the `v1beta1` policies.
{{< /warning >}}

The typical flow of migrating to `v1beta1` policy is to start by checking the
`ClusterRbacConfig` to decide which namespace or service is enabled with RBAC.

For each service enabled with RBAC:

1. Get the workload selector from the service definition.
1. Create a `v1beta1` policy with the workload selector.
1. Update the `v1beta1` policy for each `ServiceRole` and `ServiceRoleBinding` applied to the service.
1. Apply the `v1beta1` policy and monitor the traffic to make sure the policy is working as expected.
1. Repeat the process for the next service enabled with RBAC.

For each namespace enabled with RBAC:

1. Apply a `v1beta1` policy that denies all traffic to the given namespace.

### Migration Example

Assume you have the following `v1alpha1` policies for the `httpbin` service in the `foo` namespace:

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ClusterRbacConfig
metadata:
  name: default
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["foo"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: httpbin
  namespace: foo
spec:
  rules:
  - services: ["httpbin.foo.svc.cluster.local"]
    methods: ["GET"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: httpbin
  namespace: foo
spec:
  subjects:
  - user: "cluster.local/ns/default/sa/sleep"
  roleRef:
    kind: ServiceRole
    name: "httpbin"
{{< /text >}}

You migrate the above policies to `v1beta1` in the following ways:

1. Assume the `httpbin` service has the following workload selector:

    {{< text yaml >}}
    selector:
      app: httpbin
      version: v1
    {{< /text >}}

1. Create a `v1beta1` policy with the workload selector:

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
    {{< /text >}}

1. Update the `v1beta1` policy with each `ServiceRole` and `ServiceRoleBinding`
applied to the service:

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
    {{< /text >}}

1. Apply the `v1beta1` policy and monitor the traffic to make sure it works as expected

1. Apply the following `v1beta1` policy that denies all traffic to the `foo` namespace
because the `foo` namespace is enabled with RBAC:

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
     name: deny-all
     namespace: foo
    spec:
     {}
    {{< /text >}}

Make sure the `v1beta1` policy is working as expected and then you can delete the `v1alpha1` policies
from the cluster.

### Automation of the Migration

To help ease the migration, we're working on a tool `istioctl x authz convert` to automate the
conversion. The tool is still under active development and doesn't support all `v1alpha1` semantics
so we recommend to do the migration manually in Istio 1.4.

The tool will be ready for use in Istio 1.5 and will be able to fetch all the
`v1alpha1` policies in the cluster and convert them to the `v1beta1` policy
automatically.

## Summary

The Istio `v1beta1` authorization policy is a major update to the previous `v1alpha1` RBAC policy
with the design principle of aligning with Istio configuration model, improving user
experience by simplifying the API and supporting more use cases (e.g. Ingress/Egress gateway support)
without introducing much complexity.

The `v1beta1` policy is not backward compatible and requires a one time conversion. A tool
is provided to automate this process.

The previous configuration resources `ClusterRbacConfig`, `ServiceRole`, and `ServiceRoleBinding`
will not be supported from Istio 1.6 onwards.
