---
title: Deployment and Configuration Guidelines
description: Provides specific deployment and configuration guidelines.
weight: 5
---

This section provides specific deployment or configuration guidelines to avoid networking or traffic management issues.

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
$ kubectl logs -n istio-system -l istio=pilot -c discovery | grep "non unique port"
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
Starting in Istio 1.0.1, an experimental feature has been added to merge such destination rules
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
See [Route rules have no effect on ingress gateway requests](#route-rules-have-no-effect-on-ingress-gateway-requests)
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

## 503 errors after setting destination rule

If requests to a service immediately start generating HTTP 503 errors after you applied a `DestinationRule`
and the errors continue until you remove or revert the `DestinationRule`, then the `DestinationRule` is probably
causing a TLS conflict for the service.

For example, if you configure mutual TLS in the cluster globally, the `DestinationRule` must include the following `trafficPolicy`:

{{< text yaml >}}
trafficPolicy:
  tls:
    mode: ISTIO_MUTUAL
{{< /text >}}

Otherwise, the mode defaults to `DISABLED` causing client proxy sidecars to make plain HTTP requests
instead of TLS encrypted requests. Thus, the requests conflict with the server proxy because the server proxy expects
encrypted requests.

To confirm there is a conflict, check whether the `STATUS` field in the output of the `istioctl authn tls-check` command
is set to `CONFLICT` for your service. For example:

{{< text bash >}}
$ istioctl authn tls-check httpbin.default.svc.cluster.local
HOST:PORT                                  STATUS       SERVER     CLIENT     AUTHN POLICY     DESTINATION RULE
httpbin.default.svc.cluster.local:8000     CONFLICT     mTLS       HTTP       default/         httpbin/default
{{< /text >}}

Whenever you apply a `DestinationRule`, ensure the `trafficPolicy` TLS mode matches the global server configuration.

## 503 errors while reconfiguring service routes

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

## Route rules have no effect on ingress gateway requests

Let's assume you are using an ingress `Gateway` and corresponding `VirtualService` to access an internal service.
For example, your `VirtualService` looks something like this:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # or maybe "*" if you are testing without DNS using the ingress-gateway IP (e.g., http://1.2.3.4/hello)
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
  - match:
    ...
{{< /text >}}

You also have a `VirtualService` which routes traffic for the helloworld service to a particular subset:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
  - helloworld.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

In this situation you will notice that requests to the helloworld service via the ingress gateway will
not be directed to subset v1 but instead will continue to use default round-robin routing.

The ingress requests are using the gateway host (e.g., `myapp.com`)
which will activate the rules in the myapp `VirtualService` that routes to any endpoint in the helloworld service.
Internal requests with the host `helloworld.default.svc.cluster.local` will use the
helloworld `VirtualService` which directs traffic exclusively to subset v1.

To control the traffic from the gateway, you need to include the subset rule in the myapp `VirtualService`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # or maybe "*" if you are testing without DNS using the ingress-gateway IP (e.g., http://1.2.3.4/hello)
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    ...
{{< /text >}}

Alternatively, you can combine both `VirtualServices` into one unit if possible:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.com # cannot use "*" here since this is being combined with the mesh services
  - helloworld.default.svc.cluster.local
  gateways:
  - mesh # applies internally as well as externally
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
      gateways:
      - myapp-gateway #restricts this rule to apply only to ingress gateway
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    - gateways:
      - mesh # applies to all services inside the mesh
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

## Route rules have no effect on my application

If route rules are working perfectly for the [Bookinfo](/docs/examples/bookinfo/) sample,
but similar version routing rules have no effect on your own application, it may be that
your Kubernetes services need to be changed slightly.

Kubernetes services must adhere to certain restrictions in order to take advantage of
Istio's L7 routing features.
Refer to the [Requirements for Pods and Services](/docs/setup/kubernetes/spec-requirements)
for details.

## Envoy won't connect to my HTTP/1.0 service

Envoy requires `HTTP/1.1` or `HTTP/2` traffic for upstream services. For example, when using [NGINX](https://www.nginx.com/) for serving traffic behind Envoy, you
will need to set the [proxy_http_version](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version) directive in your NGINX configuration to be "1.1", since the NGINX default is 1.0.

Example configuration:

{{< text plain >}}
upstream http_backend {
    server 127.0.0.1:8080;

    keepalive 16;
}

server {
    ...

    location /http/ {
        proxy_pass http://http_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        ...
    }
}
{{< /text >}}

## Headless TCP services losing connection

If `istio-citadel` is deployed, Envoy is restarted every 15 minutes to refresh certificates.
This causes the disconnection of TCP streams or long-running connections between services.

You should build resilience into your application for this type of
disconnect, but if you still want to prevent the disconnects from
happening, you will need to disable mutual TLS and the `istio-citadel` deployment.

First, edit your `istio` configuration to disable mutual TLS:

{{< text bash >}}
$ kubectl edit configmap -n istio-system istio
$ kubectl delete pods -n istio-system -l istio=pilot
{{< /text >}}

Next, scale down the `istio-citadel` deployment to disable Envoy restarts:

{{< text bash >}}
$ kubectl scale --replicas=0 deploy/istio-citadel -n istio-system
{{< /text >}}

This should stop Istio from restarting Envoy and disconnecting TCP connections.
