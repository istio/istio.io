---
title: Deployment and Configuration Guidelines
description: Provides specific deployment and configuration guidelines.
weight: 20
aliases:
    - /help/ops/traffic-management/deploy-guidelines
---

This section provides specific deployment or configuration guidelines to avoid networking or traffic management issues.

## Cross-namespace configuration sharing

A `VirtualService`, `DestinationRule`, or `ServiceEntry` configuration resource
can be defined in one namespace and then reused in other namespaces, if it is exported.
All traffic management resources are exported to all namespaces by default,
but the visibiltiy can be overriden using the `exportTo` field.
For example, the following virtual service can only be used by clients in the same namespace
as the configuration:

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
  ...
{{< /text >}}

{{< tip >}}
Visibility of a Kubernetes `Service` can similarly be controlled using the `networking.istio.io/exportTo` annotation.
{{< /tip >}}

The visibility of a `DestinationRule` resource in a particluar namespace, however, does not
guarantee it will be used. Exporting a destination rule to other namespaces enables it to be used
in those namespaces, but to actually be applied during a request the namespace also needs to be
on the following destination rule lookup path:

1. client namespace
1. service namespace
1. Istio configuration root (`istio-system` by default)

For example, consider the following destination rule:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews.default.svc.cluster.local
  subsets:
  - name: mysubset
    labels:
      version: myversion
{{< /text >}}

Let's assume you create this destination rule in namespace `ns1`.

If you send a request to the `reviews` service from a client in `ns1`, the destination
rule would be applied, because it is in the first namespace on the lookup path, that is,
in the client namespace.

If you now send the request from a different namespace, for example `ns2`,
the client is no longer in the same namespace as the destination rule, `ns1`.
Because the corresponding service, `reviews.default.svc.cluster.local`, is also not in `ns1`,
but rather in the `default` namespace, the destination rule will also not be found in
the second namespace of the lookup path, the service namespace.

Even if the `reviews` service is exported to all namespaces and therefore visible
in `ns2` and the destination rule is also exported to all namespaces, including `ns2`,
it will not be applied during the request from `ns2` because it's not in any
of the namespaces on the lookup path.

Istio uses this restricted destination rule lookup path for two reasons:

1. Prevent destination rules from being defined that can override the behavior of services
   in completely unrelated namespaces.
1. Have a clear lookup order in case there is more than one destination rule for
   the same host.

## Configuring multiple TLS hosts in a gateway

If you apply a `Gateway` configuration that has the same `selector` labels as another
existing `Gateway`, then if they both expose the same HTTPS port you must ensure that they have
unique port names. Otherwise, the configuration will be applied without an immediate error indication
but it will be ignored in the runtime gateway configuration. For example:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-certs/tls.key
    hosts:
    - "myhost.com"
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway2
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-certs/tls.key
    hosts:
    - "myhost2.com"
{{< /text >}}

With this configuration, requests to the second host, `myhost2.com`, will fail because
both gateway ports have `name: https`.
A _curl_ request, for example, will produce an error message something like this:

{{< text plain >}}
curl: (35) LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to myhost2.com:443
{{< /text >}}

You can confirm that this has happened by checking Pilot's logs for a message similar to the following:

{{< text bash >}}
$ kubectl logs -n istio-system $(kubectl get pod -l istio=pilot -n istio-system -o jsonpath={.items..metadata.name}) -c discovery | grep "non unique port"
2018-09-14T19:02:31.916960Z info    model   skipping server on gateway mygateway2 port https.443.HTTPS: non unique port name for HTTPS port
{{< /text >}}

To avoid this problem, ensure that multiple uses of the same `protocol: HTTPS` port are uniquely named.
For example, change the second one to `https2`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway2
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https2
      protocol: HTTPS
    tls:
      mode: SIMPLE
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-certs/tls.key
    hosts:
    - "myhost2.com"
{{< /text >}}

## Multiple virtual services and destination rules for the same host

In situations where it is inconvenient to define the complete set of route rules or policies for a particular
host in a single `VirtualService` or `DestinationRule` resource, it may be preferable to incrementally specify
the configuration for the host in multiple resources.
Starting with Istio 1.0.1, Pilot will merge such destination rules
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
See [Route rules have no effect on ingress gateway requests](/docs/ops/traffic-management/troubleshooting/#route-rules-have-no-effect-on-ingress-gateway-requests)
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

## Browser problem when multiple gateways configured with same TLS certificate

Configuring more than one gateway using the same TLS certificate will cause browsers
that leverage [HTTP/2 connection reuse](https://httpwg.org/specs/rfc7540.html#reuse)
(i.e., most browsers) to produce 404 errors when accessing a second host after a
connection to another host has already been established.

For example, let's say you have 2 hosts that share the same TLS certificate like this:

* Wildcard certificate `*.test.com` installed in `istio-ingressgateway`
* `Gateway` configuration `gw1` with host `service1.test.com`, selector `istio: ingressgateway`, and TLS using gateway's mounted (wildcard) certificate
* `Gateway` configuration `gw2` with host `service2.test.com`, selector `istio: ingressgateway`, and TLS using gateway's mounted (wildcard) certificate
* `VirtualService` configuration `vs1` with host `service1.test.com` and gateway `gw1`
* `VirtualService` configuration `vs2` with host `service2.test.com` and gateway `gw2`

Since both gateways are served by the same workload (i.e., selector `istio: ingressgateway`) requests to both services
(`service1.test.com` and `service2.test.com`) will resolve to the same IP. If `service1.test.com` is accessed first, it
will return the wildcard certificate (`*.test.com`) indicating that connections to `service2.test.com` can use the same certificate.
Browsers like Chrome and Firefox will consequently reuse the existing connection for requests to `service2.test.com`.
Since the gateway (`gw1`) has no route for `service2.test.com`, it will then return a 404 (Not Found) response.

You can avoid this problem by configuring a single wildcard `Gateway`, instead of two (`gw1` and `gw2`).
Then, simply bind both `VirtualServices` to it like this:

* `Gateway` configuration `gw` with host `*.test.com`, selector `istio: ingressgateway`, and TLS using gateway's mounted (wildcard) certificate
* `VirtualService` configuration `vs1` with host `service1.test.com` and gateway `gw`
* `VirtualService` configuration `vs2` with host `service2.test.com` and gateway `gw`
