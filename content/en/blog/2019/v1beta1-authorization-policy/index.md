---
title: Introducing the Istio v1beta1 Authorization Policy
description: Introduction, motivation and design principles for the Istio v1beta1 Authorization Policy.
publishdate: 2019-11-11
subtitle:
attribution: Yangmin Zhu (Google)
keywords: [security, RBAC, access control, authorization]
target_release: 1.4
---

Up until now, Istio has provided the role based access control (RBAC) policy for enforcing access control
on services using three configuration resources: `ClusterRbacConfig`, `ServiceRole` and `ServiceRoleBinding`.
With this API, users have been able to enforce access control in mesh-level, namespace-level and
service-level. Like any other RBAC policy, Istio RBAC uses the same concept of role and binding for granting
permissions to identities.

While this functionality has proven to be working for many customers, we have also recognised
some shortcomings in its design that is causing many confusions and preventing its further adoption.

For example, some users have had the wrong impression that the enforcement happens in service-level because
`ServiceRole` uses service to specify where to apply the policy, however, the policy is actually applied
in workload-level, the service is only used to find the corresponding workload. This has some big impact, especially
when multiple services are referring to the same workload. A `ServiceRole` for service A will also affect
service B if the two services are referring to the same workload, this surprises customers and could even cause
security vulnerability.

The other example is it's a little bit hard to maintain and manage the Istio RBAC configurations because three
are three different customer resource definitions in Istio RBAC. Istio has already had an issue that there
are too much CRDs to learn and manage, and the learning and maintenance burden of having three different configurations
in Istio RBAC turned out to be greater than its benefit.

To address these, and other issues, Istio 1.4 introduces the `v1beta1` authorization policy which will
completely replace the previous `v1alpha1` RBAC policy going forward. The `v1beta1` policy provides
more features but is not backward compatible and will require manual conversion from the old API (we
will provide tool to help automate the conversion).

In this article, we will introduce the new `v1beta1` authorization policy, talk about its design principle
and the migration from the `v1alpha1` RBAC policy.

## Design principles

A few key design principles played a role in the `v1beta1` authorization policy:

* Align with [Istio Configuration Model](https://goo.gl/x3STjD). The configuration model
provides a unified way for configuration hierarchy, resolution, target selection and etc.

* Improve user experience by simplifying the API. It's much easier to manage one custom resource
definition (CRD) that includes all access control specification instead of looking at multiple
different CRDs.

* Make policy semantics more flexible without introducing much complexity. For example, it's
very useful to apply the policy to the edge (ingress/egress gateway) to enforce access control
for all traffic entering/exiting the mesh.

## Authorization Policy

An `AuthorizationPolicy` enables access control on workloads. This section gives
a high level overview of the new changes in the `v1beta1` authorization policy.

An `AuthorizationPolicy` includes a `selector` and a list of `rule`. The `selector`
is used to decide where to apply the policy, the `rule` is used to decide **who**
could do **what** under which **conditions**.

The `selector` replaces the functionality provided by `ClusterRbacConfig`
and the `services` field in `ServiceRole`. The `rule` includes `from`, `to` and
`when` which replaces the other fields in `ServiceRole` and `ServiceRoleBinding`.

### Example

The following authorization policy applies to workloads with label `app: httpbin`
and `version: v1` in namespace `foo`:

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

That's all you need to enable access control for a workload, compared to the `v1alpha1`
RBAC policy, you would need to configure three resources to achieve the same result:

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
`default` and `bookinfo` namespace. The root namespace is configured to `istio-config`.
The following policy will apply to workloads in every namespace including `default`,
`bookinfo` and also the `istio-system`.

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

The `v1beta1` authorization policy also supports to be applied on ingress/egress
gateway to enforce access control on traffic entering/leaving the mesh, you just
need to change the `selector` to make the policy to select the ingress/egress workload.

The following policy applies to the workload with label `app: istio-ingressgateway` in
`istio-system` namespace:

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

### Comparision

The following table highlights the key differences between the old `v1alpha1` RBAC policies and
the new `v1beta1` authorization policy.

| Feature | `v1alpha1` RBAC policy | `v1beta1` Authorization Policy |
|---------|------------------------|--------------------------------|
| Number of CRDs | Three: `ClusterRbacConfig`, `ServiceRole` and `ServiceRoleBinding` | Only One: `AuthorizationPolicy` |
| Mechanism to specify where to apply the policy | Specify by **service** | Specify by **workload** |
| Deny-by-default behavior | Enabled **explicitly** by configuring `ClusterRbacConfig` | Enabled **implicitly** with `AuthorizationPolicy` |
| API stability | `alpha`: **No** backward compatible | `beta`: backward compatible **guaranteed** |
| `"*"` in policy | Match all contents (empty and non-empty) | Match non-empty contents only |
| Ingress/Egress gateway support | Not supported | Supported |

Beyond all the differences, the `v1beta1` policy is enforced by the same engine in Envoy
and supports the same authenticated identity (mutual TLS or JWT), condition and other
primitives (e.g. IP, port and etc.) as the `v1alpha1` policy.

See [authorization concept page](/docs/concepts/security/#authorization) for a detailed
in-depth explanation of the `AuthorizationPolicy`.

## Migration

Istio 1.4 supports both `v1alpha` and `v1beta1` policies at the same time. The `v1beta1` policy
overrides the `v1alpha1` policy if they are both applied to the same workload:

1. If any `v1beta1` policies apply to the workload, the `v1beta1` policy is used and
   the `v1alpha1` policies on the same workload will all be ignored
1. If no `v1beta1` policy applies to the workload, the `v1alpha1` policy is used if
   there is any

{{< warning >}}
This means when migrating to the `v1beta1`, you need to make sure the converted
`v1beta1` policy covers all the `v1alpha1` policies applied to the same workload. The
`v1alpha1` policies applied for the workload will be ignored after you applied the `v1beta1` policies.
{{< /warning >}}

It's recommended to migrate the `v1alpha1` policy workload-by-workload to make sure you don't
forget any `v1alpha1` policies:

1. For a given workload, find out all the `v1alpha1` policies applied to it
1. Convert all the `v1alpha1` policies to `v1beta1` for the workload
1. Apply the `v1beta1` policy and monitor the traffic to make sure the new policy is working as expected
1. Continue the process for the next workload until all `v1alpha1` policies are converted
1. Now you can remove all your `v1alpha1` policies

To help ease the migration, Istio provides the command `istioctl x auth migrate` to automate the
conversion from `v1alpha1` to `v1beta1`. The command fetches all the `v1alpha1` policies currently
applied in the mesh and converts them to the `v1beta1` policy. The tool finds out the service-workload
mapping by looking at the current services applied in the mesh.

The command does the conversion at its best effort but may not be able to handle some
corner cases. In this case, the tool will return an error and you will need to manually convert
the policies.

## Summary

The Istio `v1beta1` authorization policy is a major update to the current `v1alpha1` RBAC policy
with the design principle of aligning with Istio configuration model, improving user
experience by simplifying the API and making policy semantics more flexible without
introducing much complexity.

The `v1beta1` policy is not backward compatible and requires a one time manual conversion. A tool
is provided to automate this process.

The previous configuration resources `ClusterRbacConfig`, `ServiceRole`, and `ServiceRoleBinding`
will not be supported from Istio 1.6 onwards.

## Acknowledgements

Credit for the policy redesign and implementation work goes to the following people
(in alphabetical order):

* Limin Wang (Google)
* Phillip Le (Google)
* Yangmin Zhu (Google)
