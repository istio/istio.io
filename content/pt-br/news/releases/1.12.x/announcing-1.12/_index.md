---
title: Announcing Istio 1.12
linktitle: 1.12
subtitle: Major Update
description: Istio 1.12 release announcement.
publishdate: 2021-11-18
release: 1.12.0
skip_list: true
aliases:
    - /news/announcing-1.12
    - /news/announcing-1.12.0
---

We are pleased to announce the release of Istio 1.12!

{{< relnote >}}

This is the last release of 2021. We would like to thank the entire Istio community, and especially the release managers [Daniel Grimm](https://github.com/dgn) from Red Hat and [Kenan O'Neal](https://github.com/Kmoneal) from Aspen Mesh, for helping to get 1.12.0 published.

{{< tip >}}
Istio 1.12.0 is officially supported on Kubernetes versions `1.19` to `1.22`.
{{< /tip >}}

Here are some of the highlights of the release:

## WebAssembly API

[WebAssembly](/docs/concepts/wasm/) has been an important project, in development for [over 3 years](/blog/2020/wasm-announce/), to bring advanced extensibility to Istio, by allowing users to dynamically load custom-built extensions at runtime.
However, until now, configuring WebAssembly plugins has been experimental and hard to use.

In Istio 1.12, we have improved this experience by adding a first-class API to configure WebAssembly plugins: [WasmPlugin](/docs/reference/config/proxy_extensions/wasm-plugin/).

With `WasmPlugin`, you can easily deploy custom plugins to individual proxies, or even the entire mesh.

The API is currently in alpha and evolving. [Your feedback](/get-involved/) is appreciated!

## Telemetry API

In Istio 1.11, we introduced a brand new [`Telemetry` API](/docs/reference/config/telemetry/) to bring a standardized API to configure tracing, logging, and metrics in Istio.
In 1.12, we continued work in this direction, expanding support for configuring metrics and access logging to the API.

To get started, check out the docs:

* [Telemetry API overview](/docs/tasks/observability/telemetry/)
* [Tracing](/docs/tasks/observability/distributed-tracing/)
* [Metrics](/docs/tasks/observability/metrics/)
* [Access Logging](/docs/tasks/observability/logs/access-log/)

The API is currently in alpha and evolving. [Your feedback](/get-involved/) is appreciated!

## Helm support

Istio 1.12 features a number of improvements to our [Helm installation support](/docs/setup/install/helm/), and paves the path for the feature to graduate to beta in the future.

An official Helm repository has been published to further simplify on-boarding, resolving one of the [most popular GitHub feature requests](https://github.com/istio/istio/issues/7505).
Check out the new [getting started](/docs/setup/install/helm/#prerequisites) instructions for more information.

These charts can also be found at the [ArtifactHub](https://artifacthub.io/packages/search?org=istio).

In addition, a new refined [`gateway` chart](https://artifacthub.io/packages/helm/istio-official/gateway) has been published.
This chart replaces the old `istio-ingressgateway` and `istio-egressgateway` charts to greatly simplify management of gateways and follow Helm best practices. Please visit the gateway injection page for instructions migrating to the new helm chart.

## Kubernetes Gateway API

Istio has added full support for the `v1alpha2` release of the [Kubernetes Gateway API](http://gateway-api.org/).
This API aims to unify the diverse set of APIs used by Istio, Kubernetes `Ingress`, and other proxies, to define a powerful, extensible API to configure traffic routing.

While the API is not yet targeted for production workloads, the API and Istio's implementation is rapidly evolving.
To try it out, check out the [Kubernetes Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/) documentation.

## And much, much more

* Default Retry Policies have been added to [Mesh Config](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig), allowing users configuring the default retry strategy in a single location, rather than repeating configuration in every VirtualService.
* A new `failoverPriority` configuration has been added to [Locality Load Balancing configuration](/docs/reference/config/networking/destination-rule/#LocalityLoadBalancerSetting), allowing customizing how pods are prioritized. For example, pods within the same network can be given additional priority.
* New configuration to make [secure TLS origination simpler](/docs/ops/best-practices/security/#configure-tls-verification-in-destination-rule-when-using-tls-origination) has been added.
* In case you missed it: initial support has been added for [gRPC native "Proxyless" Service Mesh](/blog/2021/proxyless-grpc/).
* Experimental support for HTTP/3 Gateways [has been added](https://github.com/istio/istio/wiki/Experimental-QUIC-and-HTTP-3-support-in-Istio-gateways).
* For the full list of changes, the see the [Change Notes](/news/releases/1.12.x/announcing-1.12/change-notes/).
