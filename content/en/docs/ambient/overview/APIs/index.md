---
title: Ambient APIs
description: Understanding ambient APIs and its status.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

This page lists all the user facing APIs relevant to the ambient mode and its feature status.

## Labels

| Name | Status |
| ------------------------------- | -------------------------- |
| [`istio.io/dataplane-mode`](/docs/reference/config/labels/) | GA |
| [`istio.io/use-waypoint`](/docs/reference/config/labels/) | GA |
| [`istio.io/waypoint-for`](/docs/reference/config/labels/) | GA |
| [`istio.io/use-waypoint-namespace`](/docs/reference/config/labels/) | Beta |

## Kubernetes Gateway API resources

Below are the resources you can use to configure your Ingress gateway or waypoint proxies:

|  Name  | Status |
| --- | --- |
| [`HTTPRoute`](https://gateway-api.sigs.k8s.io/guides/http-routing/) | GA |
| [`TLSRoute`](https://gateway-api.sigs.k8s.io/guides/tls) | Alpha |
| [`TCPRoute`](https://gateway-api.sigs.k8s.io/guides/tcp/) | Alpha |

## Istio API resources

Below are the Istio resources you can use to build security or networking or other policies for your services in the ambient mode.
While Istio supports its classic networking APIs, we recommend you to use Kubernetes Gateway API for traffic management first, and only use Istio's classic networking API if necessary.

|  Name  | Status |
| --- | --- |
| [`DestinationRule`](/docs/reference/config/networking/destination-rule/) | GA |
| [`ServiceEntry`](/docs/reference/config/networking/service-entry/) | GA |
| [`AuthorizationPolicy`](/docs/reference/config/security/authorization-policy/) (including L7 features) | GA |
| [`RequestAuthentication`](/docs/reference/config/security/request_authentication/) | Beta |
| [`VirtualService`](/docs/reference/config/networking/virtual-service/) | Alpha |
| [`WasmPlugin`](/docs/reference/config/proxy_extensions/wasm-plugin/) | Alpha |
| [`EnvoyFilter`](/docs/reference/config/networking/envoy-filter/) | Alpha |
