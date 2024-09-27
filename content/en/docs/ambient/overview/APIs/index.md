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
| `istio.io/dataplane-mode` | Beta |
| `istio.io/use-waypoint` | Beta |
| `istio.io/use-waypoint-namespace` | Beta |
| `istio.io/waypoint-for` | Beta |

TODO: add link to labels page for each when 3307 is merged.

## Annotations

Below are annotations that can be used to customize your waypoint proxies:

| Name | Status |
| ------------------------------- | -------------------------- |
| `gateway.istio.io/service-account` | Alpha |
| `ambient.istio.io/waypoint-inbound-binding` | Alpha |
| `gateway.istio.io/name-override` | Alpha |

TODO: add link to annotations page for each when 3307 is merged.

## Kubernetes Gateway API resources

Below are the resources you can use to configure your Ingress gateway or waypoint proxies:

|  Name  | Status |
| --- | --- |
| [`HTTPRoute`](https://gateway-api.sigs.k8s.io/guides/http-routing/) | Beta |
| [`TLSRoute`](https://gateway-api.sigs.k8s.io/guides/tls) | Alpha |
| [`TCPRoute`](https://gateway-api.sigs.k8s.io/guides/tcp/) | Alpha |

## Istio resources

Below are the Istio resources you can use to build networking or security or other policies for your services in the ambient mode:

|  Name  | Status |
| --- | --- |
| [`VirtualService`](https://gateway-api.sigs.k8s.io/guides/http-routing/) | Alpha |
| [`DestinationRule`](https://gateway-api.sigs.k8s.io/guides/tls) | Beta |
| [`ServiceEntry`](https://gateway-api.sigs.k8s.io/guides/tcp/) | Beta |
| [`AuthorizationPolicy`](/docs/reference/config/security/authorization-policy/) (including L7 features) | Beta |
| [`RequestAuthentication`](/docs/reference/config/security/request_authentication/) | Beta |
| [`WasmPlugin`](/docs/reference/config/proxy_extensions/wasm-plugin/) | Alpha |
| [`EnvoyFilter`](/docs/reference/config/networking/envoy-filter/) | Alpha |
