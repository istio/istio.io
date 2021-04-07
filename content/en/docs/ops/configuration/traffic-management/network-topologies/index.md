---
title: Configuring Gateway Network Topology [Experimental]
description: How to configure gateway network topology (experimental).
weight: 60
keywords: [traffic-management,ingress,gateway]
owner: istio/wg-networking-maintainers
test: no
---

## Forwarding external client attributes (IP address, certificate info) to destination workloads

{{< boilerplate experimental >}}

Many applications require knowing the client IP address and certificate information of the originating request to behave
properly. Notable cases include logging and audit tools that require the client IP be populated and security tools,
such as Web Application Firewalls (WAF), that need this information to apply rule sets properly. The ability to
provide client attributes to services has long been a staple of reverse proxies. To forward these client
attributes to destination workloads, proxies use the `X-Forwarded-For` (XFF) and `X-Forwarded-Client-Cert` (XFCC) headers.

Today's networks vary widely in nature, but support for these attributes is a requirement no matter what the network topology is.
This information should be preserved
and forwarded whether the network uses cloud-based Load Balancers, on-premise Load Balancers, gateways that are
exposed directly to the internet, gateways that serve many intermediate proxies, and other deployment topologies not
specified.

While Istio provides an [ingress gateway](/docs/tasks/traffic-management/ingress/ingress-control/), given the varieties
of architectures mentioned above, reasonable defaults are not able to be shipped that support the proper forwarding of
client attributes to the destination workloads.
This becomes ever more vital as Istio multicluster deployment models become more common.

For more information on `X-Forwarded-For`, see the IETF's [RFC](https://tools.ietf.org/html/rfc7239).

## Configuring network topologies

Configuration of XFF and XFCC headers can be set globally for all gateway workloads via `MeshConfig` or per gateway using
a pod annotation. For example, to configure globally during install or upgrade when using an `IstioOperator` custom resource:

{{< text yaml >}}
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        numTrustedProxies: <VALUE>
        forwardClientCertDetails: <ENUM_VALUE>
{{< /text >}}

You can also configure both of these settings by adding the `proxy.istio.io/config` annotation to the Pod spec
of your Istio ingress gateway.

{{< text yaml >}}
...
  metadata:
    annotations:
      "proxy.istio.io/config": '{"gatewayTopology" : { "numTrustedProxies": <VALUE>, "forwardClientCertDetails": <ENUM_VALUE> } }'
{{< /text >}}

### Configuring X-Forwarded-For Headers

Applications rely on reverse proxies to forward client attributes in a request, such as `X-Forward-For` header. However, due to the variety of network
topologies that Istio can be deployed in, you must set the `numTrustedProxies` to the number of trusted proxies deployed in front
of the Istio gateway proxy, so that the client address can be extracted correctly.
This controls the value populated by the ingress gateway in the `X-Envoy-External-Address` header
which can be reliably used by the upstream services to access client's original IP address.

For example, if you have a cloud based Load Balancer and a reverse proxy in front of your Istio gateway, set `numTrustedProxies` to `2`.

{{< idea >}}
Note that all proxies in front of the Istio gateway proxy must parse HTTP traffic and append to the `X-Forwarded-For`
header at each hop. If the number of entries in the `X-Forwarded-For` header is less than the number of
trusted hops configured, Envoy falls back to using the immediate downstream address as the trusted
client address. Please refer to the [Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-for)
to understand how `X-Forwarded-For` headers and trusted client addresses are determined.
{{< /idea >}}

#### Example using X-Forwarded-For capability with httpbin

1. Run the following command to create a file named `topology.yaml` with `numTrustedProxies` set to `2` and install Istio:

    {{< text bash >}}
    $ cat <<EOF > topology.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        defaultConfig:
          gatewayTopology:
            numTrustedProxies: 2
    EOF
    $ istioctl install -f topology.yaml
    {{< /text >}}

    {{< idea >}}
    If you previously installed an Istio ingress gateway, restart all ingress gateway pods after step 1.
    {{</ idea >}}

1. Create an `httpbin` namespace:

    {{< text bash >}}
    $ kubectl create namespace httpbin
    namespace/httpbin created
    {{< /text >}}

1. Set the `istio-injection` label to `enabled` for sidecar injection:

    {{< text bash >}}
    $ kubectl label --overwrite namespace httpbin istio-injection=enabled
    namespace/httpbin labeled
    {{< /text >}}

1. Deploy `httpbin` in the `httpbin` namespace:

    {{< text bash >}}
    $ kubectl apply -n httpbin -f samples/httpbin/httpbin.yaml
    {{< /text >}}

1. Deploy a gateway associated with `httpbin`:

    {{< text bash >}}
    $ kubectl apply -n httpbin -f samples/httpbin/httpbin-gateway.yaml
    {{< /text >}}

1. Set a local `GATEWAY_URL` environmental variable based on your Istio ingress gateway's IP address:

    {{< text bash >}}
    $ export GATEWAY_URL=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    {{< /text >}}

1. Run the following `curl` command to simulate a request with proxy addresses in the `X-Forwarded-For` header:

    {{< text bash >}}
    $ curl -H 'X-Forwarded-For: 56.5.6.7, 72.9.5.6, 98.1.2.3' $GATEWAY_URL/get?show_env=true
    {
      "args": {
        "show_env": "true"
      },
      "headers": {
        ...
        "X-Envoy-External-Address": "72.9.5.6",
        ...
        "X-Forwarded-For": "56.5.6.7, 72.9.5.6, 98.1.2.3, <YOUR GATEWAY IP>",
        ...
      },
      ...
    }
    {{< /text >}}

The above output shows the request headers that the `httpbin` workload received. When the Istio gateway received this request, it set the `X-Envoy-External-Address` header to the second to last (`numTrustedProxies: 2`) address in the `X-Forwarded-For` header from your curl command. Additionally, the gateway appends its own IP to the
`X-Forwarded-For` header before forwarding it to the httpbin workload.

### Configuring X-Forwarded-Client-Cert Headers

From [Envoy's documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-client-cert)
regarding XFCC:

{{< quote >}}
x-forwarded-client-cert (XFCC) is a proxy header which indicates certificate information of part or all of the clients
or proxies that a request has flowed through, on its way from the client to the server. A proxy may choose to
sanitize/append/forward the XFCC header before proxying the request.
{{< /quote >}}

To configure how XFCC headers are handled, set `forwardClientCertDetails` in your `IstioOperator`

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        forwardClientCertDetails: <ENUM_VALUE>
{{< /text >}}

where `ENUM_VALUE` can be of the following type.

| `ENUM_VALUE`          |                                                                                                                                |
|-----------------------|--------------------------------------------------------------------------------------------------------------------------------|
| `UNDEFINED`           | Field is not set.                                                                                                              |
| `SANITIZE`            | Do not send the XFCC header to the next hop. This is the default value for a gateway.                                          |
| `FORWARD_ONLY`        | When the client connection is mTLS (Mutual TLS), forward the XFCC header in the request.                                       |
| `APPEND_FORWARD`      | When the client connection is mTLS, append the client certificate information to the request’s XFCC header and forward it.     |
| `SANITIZE_SET`        | When the client connection is mTLS, reset the XFCC header with the client certificate information and send it to the next hop. |
| `ALWAYS_FORWARD_ONLY` | Always forward the XFCC header in the request, regardless of whether the client connection is mTLS.                            |

See the [Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-client-cert)
for examples of using this capability.

## PROXY Protocol

The [PROXY protocol](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt) allows for exchanging and preservation of client attributes across multiple proxies without relying on Layer 7 protocols.

If your external load balancer is configured to use the PROXY protocol, the Istio gateway must also be configured to accept the PROXY protocol. Enabling this requires adding the [Envoy Proxy Protocol filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/listener_filters/proxy_protocol) using an `EnvoyFilter` applied on the gateway workload. For example:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: proxy-protocol
  namespace: istio-system
spec:
  configPatches:
  - applyTo: LISTENER
    patch:
      operation: MERGE
      value:
        listener_filters:
        - name: envoy.listener.proxy_protocol
        - name: envoy.listener.tls_inspector
  workloadSelector:
    labels:
      istio: ingressgateway
{{< /text >}}

The client IP is retrieved from the PROXY protocol and set (or appended) in the `X-Forwarded-For` and `X-Envoy-External-Address` header. When PROXY protocol is used in conjunction with the `gatewayTopology` configuration, the `numTrustedProxies` and the received `X-Forwarded-For` header takes precedence in determining the trusted client addresses.
