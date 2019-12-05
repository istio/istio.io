---
title: Traffic Management Best Practices
description: Configuration best practices to avoid networking or traffic management issues.
force_inline_toc: true
weight: 20
aliases:
  - /zh/help/ops/traffic-management/deploy-guidelines
  - /zh/help/ops/deploy-guidelines
  - /zh/docs/ops/traffic-management/deploy-guidelines
---

This section provides specific deployment or configuration guidelines to avoid networking or traffic management issues.

## Set default routes for services

Although the default Istio behavior conveniently sends traffic from any
source to all versions of a destination service without any rules being set,
creating a `VirtualService` with a default route for every service,
right from the start, is generally considered a best practice in Istio.

Even if you initially have only one version of a service, as soon as you decide
to deploy a second version, you need to have a routing rule in place **before**
the new version is started, to prevent it from immediately receiving traffic
in an uncontrolled way.

Another potential issue when relying on Istio's default round-robin routing is
due to a subtlety in Istio's destination rule evaluation algorithm.
When routing a request, Envoy first evaluates route rules in virtual services
to determine if a particular subset is being routed to.
If so, only then will it activate any destination rule policies corresponding to the subset.
Consequently, Istio only applies the policies you define for specific subsets if
you **explicitly** routed traffic to the corresponding subset.

For example, consider the following destination rule as the one and only configuration defined for the
*reviews* service, that is, there are no route rules in a corresponding `VirtualService` definition:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 100
{{< /text >}}

Even if Istio’s default round-robin routing calls "v1" instances on occasion,
maybe even always if "v1" is the only running version, the above traffic policy
will never be invoked.

You can fix the above example in one of two ways. You can either move the
traffic policy up a level in the `DestinationRule` to make it apply to any version:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
  subsets:
  - name: v1
    labels:
      version: v1
{{< /text >}}

Or, better yet, define a proper route rule for the service in the `VirtualService` definition.
For example, add a simple route rule for "reviews:v1":

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
{{< /text >}}

## Control configuration sharing across namespaces {#cross-namespace-configuration}

You can define virtual services, destination rules, or service entries
in one namespace and then reuse them in other namespaces, if they are exported
to those namespaces.
Istio exports all traffic management resources to all namespaces by default,
but you can override the visibility with the `exportTo` field.
For example, only clients in the same namespace can use the following virtual service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myservice
spec:
  hosts:
  - myservice.com
  exportTo:
  - "."
  http:
  - route:
    - destination:
        host: myservice
{{< /text >}}

{{< tip >}}
You can similarly control the visibility of a Kubernetes `Service` using the `networking.istio.io/exportTo` annotation.
{{< /tip >}}

Setting the visibility of destination rules in a particular namespace doesn't
guarantee the rule is used. Exporting a destination rule to other namespaces enables you to use it
in those namespaces, but to actually be applied during a request the namespace also needs to be
on the destination rule lookup path:

1. client namespace
1. service namespace
1. Istio configuration root (`istio-system` by default)

For example, consider the following destination rule:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: myservice
spec:
  host: myservice.default.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
{{< /text >}}

Let's assume you create this destination rule in namespace `ns1`.

If you send a request to the `myservice` service from a client in `ns1`, the destination
rule would be applied, because it is in the first namespace on the lookup path, that is,
in the client namespace.

If you now send the request from a different namespace, for example `ns2`,
the client is no longer in the same namespace as the destination rule, `ns1`.
Because the corresponding service, `myservice.default.svc.cluster.local`, is also not in `ns1`,
but rather in the `default` namespace, the destination rule will also not be found in
the second namespace of the lookup path, the service namespace.

Even if the `myservice` service is exported to all namespaces and therefore visible
in `ns2` and the destination rule is also exported to all namespaces, including `ns2`,
it will not be applied during the request from `ns2` because it's not in any
of the namespaces on the lookup path.

You can avoid this problem by creating the destination rule in the same namespace as
the corresponding service, `default` in this example. It would then get applied to requests
from clients in any namespace.
You can also move the destination rule to the `istio-system` namespace, the third namespace on
the lookup path, although this isn't recommended unless the destination rule is really a global
configuration that is applicable in all namespaces, and it would require administrator authority.

Istio uses this restricted destination rule lookup path for two reasons:

1. Prevent destination rules from being defined that can override the behavior of services
   in completely unrelated namespaces.
1. Have a clear lookup order in case there is more than one destination rule for
   the same host.

## Split large virtual services and destination rules into multiple resources {#split-virtual-services}

In situations where it is inconvenient to define the complete set of route rules or policies for a particular
host in a single `VirtualService` or `DestinationRule` resource, it may be preferable to incrementally specify
the configuration for the host in multiple resources.
Pilot will merge such destination rules
and merge such virtual services if they are bound to a gateway.

Consider the case of a `VirtualService` bound to an ingress gateway exposing an application host which uses
path-based delegation to several implementation services, something like this:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service1
    route:
    - destination:
        host: service1.default.svc.cluster.local
  - match:
    - uri:
        prefix: /service2
    route:
    - destination:
        host: service2.default.svc.cluster.local
  - match:
    ...
{{< /text >}}

The downside of this kind of configuration is that other configuration (e.g., route rules) for any of the
underlying microservices, will need to also be included in this single configuration file, instead of
in separate resources associated with, and potentially owned by, the individual service teams.
See [Route rules have no effect on ingress gateway requests](/zh/docs/ops/common-problems/network-issues/#route-rules-have-no-effect-on-ingress-gateway-requests)
for details.

To avoid this problem, it may be preferable to break up the configuration of `myapp.com` into several
`VirtualService` fragments, one per backend service. For example:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-service1
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service1
    route:
    - destination:
        host: service1.default.svc.cluster.local
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-service2
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service2
    route:
    - destination:
        host: service2.default.svc.cluster.local
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-...
{{< /text >}}

When a second and subsequent `VirtualService` for an existing host is applied, `istio-pilot` will merge
the additional route rules into the existing configuration of the host. There are, however, several
caveats with this feature that must be considered carefully when using it.

1. Although the order of evaluation for rules in any given source `VirtualService` will be retained,
   the cross-resource order is UNDEFINED. In other words, there is no guaranteed order of evaluation
   for rules across the fragment configurations, so it will only have predictable behavior if there
   are no conflicting rules or order dependency between rules across fragments.
1. There should only be one "catch-all" rule (i.e., a rule that matches any request path or header) in the fragments.
   All such "catch-all" rules will be moved to the end of the list in the merged configuration, but
   since they catch all requests, whichever is applied first will essentially override and disable any others.
1. A `VirtualService` can only be fragmented this way if it is bound to a gateway.
   Host merging is not supported in sidecars.

A `DestinationRule` can also be fragmented with similar merge semantic and restrictions.

1. There should only be one definition of any given subset across multiple destination rules for the same host.
   If there is more than one with the same name, the first definition is used and any following duplicates are discarded.
   No merging of subset content is supported.
1. There should only be one top-level `trafficPolicy` for the same host.
   When top-level traffic policies are defined in multiple destination rules, the first one will be used.
   Any following top-level `trafficPolicy` configuration is discarded.
1. Unlike virtual service merging, destination rule merging works in both sidecars and gateways.

## Avoid 503 errors while reconfiguring service routes

When setting route rules to direct traffic to specific versions (subsets) of a service, care must be taken to ensure
that the subsets are available before they are used in the routes. Otherwise, calls to the service may return
503 errors during a reconfiguration period.

Creating both the `VirtualServices` and `DestinationRules` that define the corresponding subsets using a single `kubectl`
call (e.g., `kubectl apply -f myVirtualServiceAndDestinationRule.yaml` is not sufficient because the
resources propagate (from the configuration server, i.e., Kubernetes API server) to the Pilot instances in an eventually consistent manner. If the
`VirtualService` using the subsets arrives before the `DestinationRule` where the subsets are defined, the Envoy configuration generated by Pilot would refer to non-existent upstream pools. This results in HTTP 503 errors until all configuration objects are available to Pilot.

To make sure services will have zero down-time when configuring routes with subsets, follow a "make-before-break" process as described below:

* When adding new subsets:

    1. Update `DestinationRules` to add a new subset first, before updating any `VirtualServices` that use it. Apply the rule using `kubectl` or any platform-specific tooling.

    1. Wait a few seconds for the `DestinationRule` configuration to propagate to the Envoy sidecars

    1. Update the `VirtualService` to refer to the newly added subsets.

* When removing subsets:

    1. Update `VirtualServices` to remove any references to a subset, before removing the subset from a `DestinationRule`.

    1. Wait a few seconds for the `VirtualService` configuration to propagate to the Envoy sidecars.

    1. Update the `DestinationRule` to remove the unused subsets.


