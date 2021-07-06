---
title: DNS Proxying
description: How to configure DNS proxying.
weight: 60
keywords: [traffic-management,dns,virtual-machine]
owner: istio/wg-networking-maintainers
test: no
---

In addition to capturing application traffic, Istio can also capture DNS requests to improve the performance and usability of your mesh.
When proxying DNS, all DNS requests from an application will be redirected to the sidecar, which stores a local mapping of domain names to IP addresses. If the request can be handled by the sidecar, it will directly return a response to the application, avoiding a roundtrip to the upstream DNS server. Otherwise, the request is forwarded upstream following the standard `/etc/resolv.conf` DNS configuration.

While Kubernetes provides DNS resolution for Kubernetes `Service`s out of the box, any custom `ServiceEntry`s will not be recognized. With this feature, `ServiceEntry` addresses can be resolved without requiring custom configuration of a DNS server. For Kubernetes `Service`s, the DNS response will be the same, but with reduced load on `kube-dns` and increased performance.

This functionality is also available for services running outside of Kubernetes. This means that all internal services can be resolved without clunky workarounds to expose Kubernetes DNS entries outside of the cluster.

## Getting started

This feature is not currently enabled by default. To enable it, install Istio with the following settings:

{{< text bash >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        # Enable basic DNS proxying
        ISTIO_META_DNS_CAPTURE: "true"
        # Enable automatic address allocation, optional
        ISTIO_META_DNS_AUTO_ALLOCATE: "true"
EOF
{{< /text >}}

This can also be enabled on a per-pod basis with the [`proxy.istio.io/config` annotation](/docs/reference/config/annotations/).

{{< tip >}}
When deploying to a VM using [`istioctl workload entry configure`](/docs/setup/install/virtual-machine/), basic DNS proxying will be enabled by default.
{{< /tip >}}

## DNS capture In action

To try out the DNS capture, first setup a `ServiceEntry` for some external service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: external-address
spec:
  addresses:
  - 198.51.100.0
  hosts:
  - address.internal
  ports:
  - name: http
    number: 80
    protocol: HTTP
{{< /text >}}

Without the DNS capture, a request to `address.internal` would likely fail to resolve. Once this is enabled, you should instead get a response back based on the configured `address`:

{{< text bash >}}
$ curl -v address.internal
*   Trying 198.51.100.1:80...
{{< /text >}}

## Address auto allocation

In the above example, you had a predefined IP address for the service to which you sent the request. However, it's common to access external services that do not have stable addresses, and instead rely on DNS. In this case, the DNS proxy will not have enough information to return a response, and will need to forward DNS requests upstream.

This is especially problematic with TCP traffic. Unlike HTTP requests, which are routed based on `Host` headers, TCP carries much less information; you can only route on the destination IP and port number. Because you don't have a stable IP for the backend, you cannot route based on that either, leaving only port number, which leads to conflicts when multiple `ServiceEntry`s for TCP services share the same port.

To work around these issues, the DNS proxy additionally supports automatically allocating addresses for `ServiceEntry`s that do not explicitly define one. This is configured by the `ISTIO_META_DNS_AUTO_ALLOCATE` option.

When this feature is enabled, the DNS response will include a distinct and automatically assigned address for each `ServiceEntry`. The proxy is then configured to match requests to this IP address, and forward the request to the corresponding `ServiceEntry`.

{{< warning >}}
Because this feature modifies DNS responses, it may not be compatible with all applications.
{{< /warning >}}

To try this out, configure another `ServiceEntry`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: external-auto
spec:
  hosts:
  - auto.internal
  ports:
  - name: http
    number: 80
    protocol: HTTP
  resolution: STATIC
  endpoints:
  - address: 198.51.100.2
{{< /text >}}

Now, send a request:

{{< text bash >}}
$ curl -v auto.internal
*   Trying 240.240.0.1:80...
{{< /text >}}

As you can see, the request is sent to an automatically allocated address, `240.240.0.1`. These addresses will be picked from the `240.240.0.0/16` reserved IP address range to avoid conflicting with real services.
