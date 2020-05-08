---
title: Configuring Network Topologies (Experimental)
description: How to configure network topologies (experimental).
weight: 60
keywords: [traffic-management,ingress,gateway]
---

## (Experimental) Configuring network topologies

Istio provides the ability to manage settings like X-Forwarded-For (XFF) and X-Forwarded-Client-Cert (XFCC), which are
dependent on how the gateway workloads are deployed. This is as currently an experimental feature.

Many users choose to deploy Istio ingress gateways in using various network topologies
(e.g. behind Cloud Load Balancers, a self-managed Load Balancer or directly expose the
Istio ingress gateway to the internet). As such, these topologies require different ingress gateway configurations for
transporting correct client attributes like IP/certs to the workloads running in the cluster.

Configuration of XFF and XFCC headers can be configured by using `MeshConfig` during Istio
*installation* or by adding a pod annotation.

To simplify configuring network topology during installation create a single YAML file to pass to `istioctl`:

{{< text yaml >}}
cat <<'EOF' > topology.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
EOF
{{< /text >}}

{{< warning >}}
If Istio ingress gateway was already running prior to application of the MeshConfig you will need
to restart any Istio ingress gateway pods.
{{< /warning >}}

Both of the settings discussed can also be configured using the `proxy.istio.io/config` annotation to the Pod spec
of your Istio ingress gateway.

{{< text yaml >}}
...
  metadata:
    annotations:
      "proxy.istio.io/config": '{"gatewayTopology" : { "numTrustedProxies": 2 } }'
{{< /text >}}

### Configuring X-Forwarded-For Headers

Many applications, both old and new, rely on client attributes, such as X-Forward-For header,
to be forwarded by reverse proxies in a request. However, due to the variety of network
topologies Istio can be deployed in, it is required to set the number of trusted proxies deployed in front
of the Istio gateway proxy so that the client address can be extracted correctly.

To set the number of trusted proxies add the following to your `topology.yaml` file.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        numTrustedProxies: <VALUE>
{{< /text >}}

For example, if you have a cloud based LB, a reverse proxy and then the Istio gateway proxy
then `<VALUE>` would be 2.

{{< warning >}}
Note that all the proxies in front need of Istio gateway proxy must parse HTTP traffic and append the X-Forwarded-For
headers at each hop. If the number of entries in X-Forwarded-For header is less than the number of
trusted hops configured, Envoy falls back to using the immediate downstream address as the trusted
client address. Please refer to [Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-for)
to understand how X-Forwarded-For headers and trusted client addresses are determined.
{{< /warning >}}

### Configuring X-Forwarded-Client-Cert Headers

From [Envoy's documenation](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-client-cert)
regarding XFCC:
> x-forwarded-client-cert (XFCC) is a proxy header which indicates certificate information of part or all of the clients
> or proxies that a request has flowed through, on its way from the client to the server. A proxy may choose to
> sanitize/append/forward the XFCC header before proxying the request.

To configure how XFCC Headers are handled add the following to your `topology.yaml` file.

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

| ENUM_VALUE          |                                                                                                                                |
|---------------------|--------------------------------------------------------------------------------------------------------------------------------|
| SANITIZE            | Do not send the XFCC header to the next hop. This is the default value.                                                        |
| FORWARD_ONLY        | When the client connection is mTLS (Mutual TLS), forward the XFCC header in the request.                                       |
| APPEND_FORWARD      | When the client connection is mTLS, append the client certificate information to the request’s XFCC header and forward it.     |
| SANITIZE_SET        | When the client connection is mTLS, reset the XFCC header with the client certificate information and send it to the next hop. |
| ALWAYS_FORWARD_ONLY | Always forward the XFCC header in the request, regardless of whether the client connection is mTLS.                            |
