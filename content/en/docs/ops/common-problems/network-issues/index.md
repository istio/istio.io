---
title: Traffic Management Problems
description: Techniques to address common Istio traffic management and network problems.
force_inline_toc: true
weight: 10
aliases:
  - /help/ops/traffic-management/troubleshooting
  - /help/ops/troubleshooting/network-issues
  - /docs/ops/troubleshooting/network-issues
---

## Requests are rejected by Envoy

Requests may be rejected for various reasons. The best way to understand why requests are being rejected is
by inspecting Envoy's access logs. By default, access logs are output to the standard output of the container.
Run the following command to see the log:

{{< text bash >}}
$ kubectl logs PODNAME -c istio-proxy -n NAMESPACE
{{< /text >}}

In the default access log format, Envoy response flags and Mixer policy status are located after the response code,
if you are using a custom log format, make sure to include `%RESPONSE_FLAGS%` and `%DYNAMIC_METADATA(istio.mixer:status)%`.

Refer to the [Envoy response flags](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log#config-access-log-format-response-flags)
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
Refer to the [Requirements for Pods and Services](/docs/ops/deployment/requirements/)
for details.

Another potential issue is that the route rules may simply be slow to take effect.
The Istio implementation on Kubernetes utilizes an eventually consistent
algorithm to ensure all Envoy sidecars have the correct configuration
including all route rules. A configuration change will take some time
to propagate to all the sidecars.  With large deployments the
propagation will take longer and there may be a lag time on the
order of seconds.

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

To confirm there is a conflict, check whether the `STATUS` field in the output of the [`istioctl authn tls-check`](/docs/reference/commands/istioctl/#istioctl-authn-tls-check) command
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

## 404 errors occur when multiple gateways configured with same TLS certificate

Configuring more than one gateway using the same TLS certificate will cause browsers
that leverage [HTTP/2 connection reuse](https://httpwg.org/specs/rfc7540.html#reuse)
(i.e., most browsers) to produce 404 errors when accessing a second host after a
connection to another host has already been established.

For example, let's say you have 2 hosts that share the same TLS certificate like this:

- Wildcard certificate `*.test.com` installed in `istio-ingressgateway`
- `Gateway` configuration `gw1` with host `service1.test.com`, selector `istio: ingressgateway`, and TLS using gateway's mounted (wildcard) certificate
- `Gateway` configuration `gw2` with host `service2.test.com`, selector `istio: ingressgateway`, and TLS using gateway's mounted (wildcard) certificate
- `VirtualService` configuration `vs1` with host `service1.test.com` and gateway `gw1`
- `VirtualService` configuration `vs2` with host `service2.test.com` and gateway `gw2`

Since both gateways are served by the same workload (i.e., selector `istio: ingressgateway`) requests to both services
(`service1.test.com` and `service2.test.com`) will resolve to the same IP. If `service1.test.com` is accessed first, it
will return the wildcard certificate (`*.test.com`) indicating that connections to `service2.test.com` can use the same certificate.
Browsers like Chrome and Firefox will consequently reuse the existing connection for requests to `service2.test.com`.
Since the gateway (`gw1`) has no route for `service2.test.com`, it will then return a 404 (Not Found) response.

You can avoid this problem by configuring a single wildcard `Gateway`, instead of two (`gw1` and `gw2`).
Then, simply bind both `VirtualServices` to it like this:

- `Gateway` configuration `gw` with host `*.test.com`, selector `istio: ingressgateway`, and TLS using gateway's mounted (wildcard) certificate
- `VirtualService` configuration `vs1` with host `service1.test.com` and gateway `gw`
- `VirtualService` configuration `vs2` with host `service2.test.com` and gateway `gw`

## Port conflict when configuring multiple TLS hosts in a gateway

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
