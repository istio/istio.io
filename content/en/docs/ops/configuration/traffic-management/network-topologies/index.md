---
title: Configuring Gateway Network Topology (Development)
description: How to configure gateway network topology (Development).
weight: 60
keywords: [traffic-management,ingress,gateway]
owner: istio/wg-networking-maintainers
test: no
---

## Configuring network topologies (Development)

{{< idea >}}
This feature is actively in [development](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE.md) and is
considered `pre-alpha`.
{{</ idea >}}

Istio provides the ability to manage settings like [X-Forwarded-For](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-for) (XFF)
and [X-Forwarded-Client-Cert](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-client-cert)
(XFCC), which are dependent on how the gateway workloads are deployed. This is currently an in-development feature. For more
information on `X-Forwarded-For`, see the IETF's [RFC](https://tools.ietf.org/html/rfc7239).

You might choose to deploy Istio ingress gateways in various network topologies
(e.g. behind Cloud Load Balancers, a self-managed Load Balancer or directly expose the
Istio ingress gateway to the Internet). As such, these topologies require different ingress gateway configurations for
transporting correct client attributes like IP addresses and certificates to the workloads running in the cluster.

Configuration of XFF and XFCC headers is managed via `MeshConfig` during Istio
installation or by adding a pod annotation. Note that the `Meshconfig` configuration is a global setting for all gateway workloads, while pod annotations override the global setting on a per-workload basis.

To simplify configuring network topology during installation, create a single YAML file to pass to `istioctl`:

{{< text bash >}}
$ cat <<EOF > topology.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
EOF
{{< /text >}}

{{< idea >}}
If Istio ingress gateway was already running prior to application of the `MeshConfig`, restart any Istio ingress gateway pods.
{{< /idea >}}

You can configure both of these settings using the `proxy.istio.io/config` annotation to the Pod spec
of your Istio ingress gateway.

{{< text yaml >}}
...
  metadata:
    annotations:
      "proxy.istio.io/config": '{"gatewayTopology" : { "numTrustedProxies": 2 } }'
{{< /text >}}

### Configuring X-Forwarded-For Headers

Applications rely on reverse proxies to forward client attributes in a request, such as `X-Forward-For` header. However, due to the variety of network
topologies Istio can be deployed in, you must set the number of trusted proxies deployed in front
of the Istio gateway proxy, so that the client address can be extracted correctly.

To set the number of trusted proxies, add the following to your `topology.yaml` file.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        numTrustedProxies: <VALUE>
{{< /text >}}

For example, if you have a cloud based Load Balancer, a reverse proxy, and an Istio gateway proxy,
then `<VALUE>` would be 2.

{{< idea >}}
Note that all proxies in front of the Istio gateway proxy must parse HTTP traffic and append to the `X-Forwarded-For`
header at each hop. If the number of entries in the `X-Forwarded-For` header is less than the number of
trusted hops configured, Envoy falls back to using the immediate downstream address as the trusted
client address. Please refer to the [Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-for)
to understand how `X-Forwarded-For` headers and trusted client addresses are determined.
{{< /idea >}}

#### Example using X-Forwarded-For capability with httpbin

1. Specify `numTrustedProxies` as 2 either using `MeshConfig` or an `proxy.istio.io/config` annotation. If you are using `MeshConfig`, run the following command to create a file named `topology.yaml` and apply it to your cluster:

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

1. Run the following `curl` command to verify the `X-Envoy-External-Address` and `X-Forwarded-For` are set correctly:

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

Note that the `X-Envoy-External-Address` is set to the "second" from last address in the `X-Forwarded-For` header
as per your `numTrustedProxies` setting. Additionally, the gateway workload appends its IP in the
`X-Forwarded-For` header before forwarding it to the upstream httpbin workload.

### Configuring X-Forwarded-Client-Cert Headers

From [Envoy's documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-client-cert)
regarding XFCC:

{{< quote >}}
x-forwarded-client-cert (XFCC) is a proxy header which indicates certificate information of part or all of the clients
or proxies that a request has flowed through, on its way from the client to the server. A proxy may choose to
sanitize/append/forward the XFCC header before proxying the request.
{{< /quote >}}

To configure how XFCC Headers are handled, add the following to your `topology.yaml` file.

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
