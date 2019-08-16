---
title: Troubleshooting Networking Issues
description: Describes common networking issues and how to recognize and avoid them.
weight: 30
aliases:
    - /help/ops/traffic-management/troubleshooting
---

This section describes common problems and tools and techniques to address issues related to traffic management.

## Requests are rejected by Envoy

Requests may be rejected for various reasons. The best way to understand why requests are being rejected is
by inspecting Envoy's access logs. By default, access logs are output to the standard output of the container.
Run the following command to see the log:

{{< text bash >}}
$ kubectl logs PODNAME -c istio-proxy -n NAMESPACE
{{< /text >}}

In the default access log format, Envoy response flags and Mixer policy status are located after the response code,
if you are using a custom log format, make sure to include `%RESPONSE_FLAGS%` and `%DYNAMIC_METADATA(istio.mixer:status)%`.

Refer to the [Envoy response flags](https://www.envoyproxy.io/docs/envoy/latest/configuration/access_log#config-access-log-format-response-flags)
for details of response flags.

Common response flags are:

- `NR`: No route configured, check your `DestinationRule` or `VirtualService`.
- `UO`: Upstream overflow with circuit breaking, check your circuit breaker configuration in `DestinationRule`.
- `UF`: Failed to connect to upstream, if you're using Istio authentication, check for a
[mutual TLS configuration conflict](#503-errors-after-setting-destination-rule).

A request is rejected by Mixer if the response flag is `UAEX` and the Mixer policy status is not `-`.

Common Mixer policy statuses are:

- `UNAVAILABLE`: Envoy cannot connect to Mixer and the policy is configured to fail close.
- `UNAUTHENTICATED`: The request is rejected by Mixer authentication.
- `PERMISSION_DENIED`: The request is rejected by Mixer authorization.
- `RESOURCE_EXHAUSTED`: The request is rejected by Mixer quota.
- `INTERNAL`: The request is rejected due to Mixer internal error.

## Route rules don't seem to affect traffic flow

With the current Envoy sidecar implementation, up to 100 requests may be required for weighted
version distribution to be observed.

If route rules are working perfectly for the [Bookinfo](/docs/examples/bookinfo/) sample,
but similar version routing rules have no effect on your own application, it may be that
your Kubernetes services need to be changed slightly.
Kubernetes services must adhere to certain restrictions in order to take advantage of
Istio's L7 routing features.
Refer to the [Requirements for Pods and Services](/docs/setup/additional-setup/requirements/)
for details.

Another potential issue is that the route rules may simply be slow to take effect.
The Istio implementation on Kubernetes utilizes an eventually consistent
algorithm to ensure all Envoy sidecars have the correct configuration
including all route rules. A configuration change will take some time
to propagate to all the sidecars.  With large deployments the
propagation will take longer and there may be a lag time on the
order of seconds.

## Destination rule policy not activated

Although destination rules are associated with a particular destination host,
the activation of subset-specific policies depends on route rule evaluation.

When routing a request, Envoy first evaluates route rules in virtual services
to determine if a particular subset is being routed to.
If so, only then will it activate any destination rule policies corresponding to the subset.
Consequently, Istio only applies the policies you define for specific subsets if
you explicitly routed traffic to the corresponding subset.

For example, consider the following destination rule as the one and only configuration defined for the
*reviews* service, that is, there are no route rules in a corresponding virtual service definition:

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

Even if Istio's default round-robin routing calls "v1" instances on occasion,
maybe even always if "v1" is the only running version, the above traffic policy will never be invoked.

You can fix the above example in one of two ways:

1. Move the traffic policy in the destination rule up a level to make the policy
    apply to any subset, for example:

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

1. Define proper route rules for the service using a virtual service.
    For example, add a simple route rule for the `v1` subset of the `reviews` service:

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

The default Istio behavior conveniently sends traffic from any source
to all versions of the destination service without you setting any rules.
As soon as you need to differentiate between the versions of a service,
you need to define routing rules.
Due to this fact, we consider a best practice to set a default routing rule
for every service from the start.

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

Otherwise, the mode defaults to `DISABLE` causing client proxy sidecars to make plain HTTP requests
instead of TLS encrypted requests. Thus, the requests conflict with the server proxy because the server proxy expects
encrypted requests.

To confirm there is a conflict, check whether the `STATUS` field in the output of the `istioctl authn tls-check` command
is set to `CONFLICT` for your service. For example, a command similar to the following could be used to check
for a conflict with the `httpbin` service:

{{< text bash >}}
$ istioctl authn tls-check istio-ingressgateway-db454d49b-lmtg8.istio-system httpbin.default.svc.cluster.local
HOST:PORT                                  STATUS       SERVER     CLIENT     AUTHN POLICY     DESTINATION RULE
httpbin.default.svc.cluster.local:8000     CONFLICT     mTLS       HTTP       default/         httpbin/default
{{< /text >}}

Whenever you apply a `DestinationRule`, ensure the `trafficPolicy` TLS mode matches the global server configuration.

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
which will activate the rules in the myapp `VirtualService` that routes to any endpoint of the helloworld service.
Only internal requests with the host `helloworld.default.svc.cluster.local` will use the
helloworld `VirtualService` which directs traffic exclusively to subset v1.

To control the traffic from the gateway, you need to also include the subset rule in the myapp `VirtualService`:

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

## Headless TCP services losing connection

If `istio-citadel` is deployed, Envoy is restarted every 45 days to refresh certificates.
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

## Envoy is crashing under load

Check your `ulimit -a`. Many systems have a 1024 open file descriptor limit by default which will cause Envoy to assert and crash with:

{{< text plain >}}
[2017-05-17 03:00:52.735][14236][critical][assert] assert failure: fd_ != -1: external/envoy/source/common/network/connection_impl.cc:58
{{< /text >}}

Make sure to raise your ulimit. Example: `ulimit -n 16384`

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
