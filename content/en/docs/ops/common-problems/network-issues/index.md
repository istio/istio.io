---
title: Traffic Management Problems
description: Techniques to address common Istio traffic management and network problems.
force_inline_toc: true
weight: 10
aliases:
  - /help/ops/traffic-management/troubleshooting
  - /help/ops/troubleshooting/network-issues
  - /docs/ops/troubleshooting/network-issues
owner: istio/wg-networking-maintainers
test: n/a
---

## Requests are rejected by Envoy

Requests may be rejected for various reasons. The best way to understand why requests are being rejected is
by inspecting Envoy's access logs. By default, access logs are output to the standard output of the container.
Run the following command to see the log:

{{< text bash >}}
$ kubectl logs PODNAME -c istio-proxy -n NAMESPACE
{{< /text >}}

In the default access log format, Envoy response flags are located after the response code,
if you are using a custom log format, make sure to include `%RESPONSE_FLAGS%`.

Refer to the [Envoy response flags](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#config-access-log-format-response-flags)
for details of response flags.

Common response flags are:

- `NR`: No route configured, check your `DestinationRule` or `VirtualService`.
- `UO`: Upstream overflow with circuit breaking, check your circuit breaker configuration in `DestinationRule`.
- `UF`: Failed to connect to upstream, if you're using Istio authentication, check for a
[mutual TLS configuration conflict](#503-errors-after-setting-destination-rule).

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

{{< tip >}}
You should only see this error if you disabled [automatic mutual TLS](/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls) during install.
{{< /tip >}}

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

Whenever you apply a `DestinationRule`, ensure the `trafficPolicy` TLS mode matches the global server configuration.

## Route rules have no effect on ingress gateway requests

Let's assume you are using an ingress `Gateway` and corresponding `VirtualService` to access an internal service.
For example, your `VirtualService` looks something like this:

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
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
apiVersion: networking.istio.io/v1beta1
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
Only internal requests with the host `helloworld.default.svc.cluster.local` will use the
helloworld `VirtualService` which directs traffic exclusively to subset v1.

To control the traffic from the gateway, you need to also include the subset rule in the myapp `VirtualService`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
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
apiVersion: networking.istio.io/v1beta1
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

## 503 error while accessing headless services

Assume Istio is installed with the following configuration:

- `mTLS mode` set to `STRICT` within the mesh
- `meshConfig.outboundTrafficPolicy.mode` set to `ALLOW_ANY`

Consider `nginx` is deployed as a `StatefulSet` in the default namespace and a corresponding `Headless Service` is defined as shown below:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: http-web  # Explicitly defining an http port
  clusterIP: None   # Creates a Headless Service
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: nginx
  serviceName: "nginx"
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: registry.k8s.io/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
{{< /text >}}

The port name `http-web` in the Service definition explicitly specifies the http protocol for that port.

Let us assume we have a [sleep]({{< github_tree >}}/samples/sleep) pod `Deployment` as well in the default namespace.
When `nginx` is accessed from this `sleep` pod using its Pod IP (this is one of the common ways to access a headless service), the request goes via the `PassthroughCluster` to the server-side, but the sidecar proxy on the server-side fails to find the route entry to `nginx` and fails with `HTTP 503 UC`.

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}')
$ kubectl exec -it $SOURCE_POD -c sleep -- curl 10.1.1.171 -s -o /dev/null -w "%{http_code}"
  503
{{< /text >}}

`10.1.1.171` is the Pod IP of one of the replicas of `nginx` and the service is accessed on `containerPort` 80.

Here are some of the ways to avoid this 503 error:

1. Specify the correct Host header:

    The Host header in the curl request above will be the Pod IP by default. Specifying the Host header as `nginx.default` in our request to `nginx` successfully returns `HTTP 200 OK`.

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}')
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -H "Host: nginx.default" 10.1.1.171 -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

1. Set port name to `tcp` or `tcp-web` or `tcp-<custom_name>`:

    Here the protocol is explicitly specified as `tcp`. In this case, only the `TCP Proxy` network filter on the sidecar proxy is used both on the client-side and server-side. HTTP Connection Manager is not used at all and therefore, any kind of header is not expected in the request.

    A request to `nginx` with or without explicitly setting the Host header successfully returns `HTTP 200 OK`.

    This is useful in certain scenarios where a client may not be able to include header information in the request.

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}')
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl 10.1.1.171 -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -H "Host: nginx.default" 10.1.1.171 -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

1. Use domain name instead of Pod IP:

    A specific instance of a headless service can also be accessed using just the domain name.

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}')
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl web-0.nginx.default -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

    Here `web-0` is the pod name of one of the 3 replicas of `nginx`.

Refer to this [traffic routing](/docs/ops/configuration/traffic-management/traffic-routing/) page for some additional information on headless services and traffic routing behavior for different protocols.

## TLS configuration mistakes

Many traffic management problems
are caused by incorrect [TLS configuration](/docs/ops/configuration/traffic-management/tls-configuration/).
The following sections describe some of the most common misconfigurations.

### Sending HTTPS to an HTTP port

If your application sends an HTTPS request to a service declared to be HTTP,
the Envoy sidecar will attempt to parse the request as HTTP while forwarding the request,
which will fail because the HTTP is unexpectedly encrypted.

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: http
    protocol: HTTP
  resolution: DNS
{{< /text >}}

Although the above configuration may be correct if you are intentionally sending plaintext on port 443 (e.g., `curl http://httpbin.org:443`),
generally port 443 is dedicated for HTTPS traffic.

Sending an HTTPS request like `curl https://httpbin.org`, which defaults to port 443, will result in an error like
`curl: (35) error:1408F10B:SSL routines:ssl3_get_record:wrong version number`.
The access logs may also show an error like `400 DPE`.

To fix this, you should change the port protocol to HTTPS:

{{< text yaml >}}
spec:
  ports:
  - number: 443
    name: https
    protocol: HTTPS
{{< /text >}}

### Gateway to virtual service TLS mismatch {#gateway-mismatch}

There are two common TLS mismatches that can occur when binding a virtual service to a gateway.

1. The gateway terminates TLS while the virtual service configures TLS routing.
1. The gateway does TLS passthrough while the virtual service configures HTTP routing.

#### Gateway with TLS termination

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
      - "*"
    tls:
      mode: SIMPLE
      credentialName: sds-credential
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*.example.com"
  gateways:
  - istio-system/gateway
  tls:
  - match:
    - sniHosts:
      - "*.example.com"
    route:
    - destination:
        host: httpbin.org
{{< /text >}}

In this example, the gateway is terminating TLS while the virtual service is using TLS based routing.
The TLS route rules will have no effect since the TLS is already terminated when the route rules are evaluated.

With this misconfiguration, you will end up getting 404 responses because the requests will be
sent to HTTP routing but there are no HTTP routes configured.
You can confirm this using the `istioctl proxy-config routes` command.

To fix this problem, you should switch the virtual service to specify `http` routing, instead of `tls`:

{{< text yaml >}}
spec:
  ...
  http:
  - match:
    - headers:
        ":authority":
          regex: "*.example.com"
{{< /text >}}

#### Gateway with TLS passthrough

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - "*"
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: virtual-service
spec:
  gateways:
  - gateway
  hosts:
  - httpbin.example.com
  http:
  - route:
    - destination:
        host: httpbin.org
{{< /text >}}

In this configuration, the virtual service is attempting to match HTTP traffic against TLS traffic passed through the gateway.
This will result in the virtual service configuration having no effect. You can observe that the HTTP route is not applied using
the `istioctl proxy-config listener` and `istioctl proxy-config route` commands.

To fix this, you should switch the virtual service to configure `tls` routing:

{{< text yaml >}}
spec:
  tls:
  - match:
    - sniHosts: ["httpbin.example.com"]
    route:
    - destination:
        host: httpbin.org
{{< /text >}}

Alternatively, you could terminate TLS, rather than passing it through, by switching the `tls` configuration in the gateway:

{{< text yaml >}}
spec:
  ...
    tls:
      credentialName: sds-credential
      mode: SIMPLE
{{< /text >}}

### Double TLS (TLS origination for a TLS request) {#double-tls}

When configuring Istio to perform {{< gloss >}}TLS origination{{< /gloss >}}, you need to make sure
that the application sends plaintext requests to the sidecar, which will then originate the TLS.

The following `DestinationRule` originates TLS for requests to the `httpbin.org` service,
but the corresponding `ServiceEntry` defines the protocol as HTTPS on port 443.

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: originate-tls
spec:
  host: httpbin.org
  trafficPolicy:
    tls:
      mode: SIMPLE
{{< /text >}}

With this configuration, the sidecar expects the application to send TLS traffic on port 443
(e.g., `curl https://httpbin.org`), but it will also perform TLS origination before forwarding requests.
This will cause the requests to be double encrypted.

For example, sending a request like `curl https://httpbin.org` will result in an error:
`(35) error:1408F10B:SSL routines:ssl3_get_record:wrong version number`.

You can fix this example by changing the port protocol in the `ServiceEntry` to HTTP:

{{< text yaml >}}
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: http
    protocol: HTTP
{{< /text >}}

Note that with this configuration your application will need to send plaintext requests to port 443,
like `curl http://httpbin.org:443`, because TLS origination does not change the port.
However, starting in Istio 1.8, you can expose HTTP port 80 to the application (e.g., `curl http://httpbin.org`)
and then redirect requests to `targetPort` 443 for the TLS origination:

{{< text yaml >}}
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
    targetPort: 443
{{< /text >}}

### 404 errors occur when multiple gateways configured with same TLS certificate

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

### Configuring SNI routing when not sending SNI

An HTTPS `Gateway` that specifies the `hosts` field will perform an [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) match on incoming requests.
For example, the following configuration would only allow requests that match `*.example.com` in the SNI:

{{< text yaml >}}
servers:
- port:
    number: 443
    name: https
    protocol: HTTPS
  hosts:
  - "*.example.com"
{{< /text >}}

This may cause certain requests to fail.

For example, if you do not have DNS set up and are instead directly setting the host header, such as `curl 1.2.3.4 -H "Host: app.example.com"`, no SNI will be set, causing the request to fail.
Instead, you can set up DNS or use the `--resolve` flag of `curl`. See the [Secure Gateways](/docs/tasks/traffic-management/ingress/secure-ingress/) task for more information.

Another common issue is load balancers in front of Istio.
Most cloud load balancers will not forward the SNI, so if you are terminating TLS in your cloud load balancer you may need to do one of the following:

- Configure the cloud load balancer to instead passthrough the TLS connection
- Disable SNI matching in the `Gateway` by setting the hosts field to `*`

A common symptom of this is for the load balancer health checks to succeed while real traffic fails.

## Unchanged Envoy filter configuration suddenly stops working

An `EnvoyFilter` configuration that specifies an insert position relative to another filter can be very
fragile because, by default, the order of evaluation is based on the creation time of the filters.
Consider a filter with the following specification:

{{< text yaml >}}
spec:
  configPatches:
  - applyTo: NETWORK_FILTER
    match:
      context: SIDECAR_OUTBOUND
      listener:
        portNumber: 443
        filterChain:
          filter:
            name: istio.stats
    patch:
      operation: INSERT_BEFORE
      value:
        ...
{{< /text >}}

To work properly, this filter configuration depends on the `istio.stats` filter having an older creation time
than it. Otherwise, the `INSERT_BEFORE` operation will be silently ignored. There will be nothing in the
error log to indicate that this filter has not been added to the chain.

This is particularly problematic when matching filters, like `istio.stats`, that are version
specific (i.e., that include the `proxyVersion` field in their match criteria). Such filters may be removed
or replaced by newer ones when upgrading Istio. As a result, an `EnvoyFilter` like the one above may initially
be working perfectly but after upgrading Istio to a newer version it will no longer be included in the network
filter chain of the sidecars.

To avoid this issue, you can either change the operation to one that does not depend on the presence of
another filter (e.g., `INSERT_FIRST`), or set an explicit priority in the `EnvoyFilter` to override the
default creation time-based ordering. For example, adding `priority: 10` to the above filter will ensure
that it is processed after the `istio.stats` filter which has a default priority of 0.

## Virtual service with fault injection and retry/timeout policies not working as expected

Currently, Istio does not support configuring fault injections and retry or timeout policies on the
same `VirtualService`. Consider the following configuration:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
    - "*"
  gateways:
  - helloworld-gateway
  http:
  - match:
    - uri:
        exact: /hello
    fault:
      abort:
        httpStatus: 500
        percentage:
          value: 50
    retries:
      attempts: 5
      retryOn: 5xx
    route:
    - destination:
        host: helloworld
        port:
          number: 5000
{{< /text >}}

You would expect that given the configured five retry attempts, the user would almost never see any
errors when calling the `helloworld` service. However since both fault and retries are configured on
the same `VirtualService`, the retry configuration does not take effect, resulting in a 50% failure
rate. To work around this issue, you may remove the fault config from your `VirtualService` and
inject the fault to the upstream Envoy proxy using `EnvoyFilter` instead:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: hello-world-filter
spec:
  workloadSelector:
    labels:
      app: helloworld
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND # will match outbound listeners in all sidecars
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.fault
        typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.http.fault.v3.HTTPFault"
          abort:
            http_status: 500
            percentage:
              numerator: 50
              denominator: HUNDRED
{{< /text >}}

This works because this way the retry policy is configured for the client proxy while the fault
injection is configured for the upstream proxy.
