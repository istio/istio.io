---
title: Istio 1.6 Change Notes
description: Istio 1.6 release notes.
weight: 10
release: 1.6
subtitle: Minor Release
linktitle: 1.6 Change Notes
publishdate: 2020-05-21
---

## Traffic Management

- ***Added*** [`VirtualService` delegation](https://github.com/istio/istio/pull/22118). This allows mesh routing configurations to be specified in multiple composable `VirtualServices`.
- ***Added*** the new [Workload Entry](/docs/reference/config/networking/workload-entry/) resource. This allows easier configuration for non-Kubernetes workloads to join the mesh.
- ***Added*** configuration for gateway topology. This addresses providing correct [X-Forwarded-For headers](https://github.com/istio/istio/issues/7679) and X-Forwarded-Client-Cert headers based on gateway deployment topology .
- ***Added*** experimental support for the [Kubernetes Service APIs](https://github.com/kubernetes-sigs/service-apis/).
- ***Added*** support for using `appProtocol` to select the [protocol for a port](/docs/ops/configuration/traffic-management/protocol-selection/) introduced in Kubernetes 1.18.
- ***Changed*** Gateway SDS to be enabled by default. File mounted gateway continues to be available to help users to transition to secure gateway SDS.
- ***Added*** support for reading certificates from Secrets, `pathType`, and `IngressClass`, which provides better support for [Kubernetes ingress](/docs/tasks/traffic-management/ingress/kubernetes-ingress/).
- ***Added*** a new `proxy.istio.io/config` annotation to override proxy configuration per pod.
- ***Removed*** most configuration flags and environment variables for the proxy. These now read directly from the mesh configuration.
- ***Changed*** the proxy readiness probe to port 15021.
- ***Fixed*** a [bug](https://github.com/istio/istio/issues/16458), which blocked external HTTPS/TCP traffic in some cases.

## Security

- ***Added*** [JSON Web Token (JWT) caching](https://github.com/istio/istio/pull/22789) to the Istio-agent, which provides better Istio Agent SDS performance.
- ***Fixed*** the Istio Agent certificate provisioning [grace period calculation](https://github.com/istio/istio/pull/22617).
- ***Removed*** Security alpha API. Security beta API, which was introduced in Istio 1.5, is the only supported security API in Istio 1.6.

## Telemetry

- ***Added*** experimental support for [request classification](/docs/tasks/observability/metrics/classify-metrics/) filters. This enables operators to configure new attributes for use in telemetry, based on request information. A primary use case for this feature is labeling of traffic by API method.
- ***Added*** an experimental [mesh-wide tracing configuration API](/docs/tasks/observability/distributed-tracing/mesh-and-proxy-config/). This API provides control of trace sampling rates, the [maximum tag lengths](https://github.com/istio/istio/issues/14563) for URL tags, and [custom tags extraction](https://github.com/istio/istio/issues/13018) for all traces within the mesh.
- ***Added*** standard Prometheus scrape annotations to proxies and the control plane workloads, which improves the Prometheus integration experience. This removes the need for specialized configuration to discover and consume Istio metrics. More details are available in the [operations guide for Prometheus](/docs/ops/integrations/prometheus#option-2-metrics-merging/).
- ***Added*** the ability for mesh operators to add and remove labels used in Istio metrics, based on expressions over the set of available request and response attributes. This improves Istio's support for [customizing v2 metrics generation](/docs/tasks/observability/metrics/customize-metrics/).
- ***Updated*** default telemetry v2 configuration to avoid using host header to extract destination service name at the gateway. This prevents unbound cardinality due to an untrusted host header, and implies that destination service labels are going to be omitted for requests that hit `blackhole` and `passthrough` at the gateway.
- ***Added*** automated publishing of Grafana dashboards to `grafana.com` as part of the Istio release process. Please see the [Istio org page](https://grafana.com/orgs/istio) for more information.
- ***Updated*** Grafana dashboards to adapt to the new Istiod deployment model.

## Installation

- ***Added*** support for Istio canary upgrades. See the [Upgrade guide](/docs/setup/upgrade/) for more information.
- ***Removed*** the legacy Helm charts. For migration from them please see the [Upgrade guide](/docs/setup/upgrade/).
- ***Added*** the ability for users to add a custom hostname for istiod.
- ***Changed*** gateway readiness port used from 15020 to 15021. If you check health on your Istio `ingressgateway` from your Kubernetes network load balancer you will need to update the port.
- ***Added*** functionality to save installation state in a `CustomResource` in the cluster.
- ***Changed*** the Istio installation to no longer manage the installation namespace, allowing more flexibility.
- ***Removed*** the separate Citadel, Sidecar Injector, and Galley deployments. These were disabled by default in 1.5, and all functionality has moved into Istiod.
- ***Removed*** the legacy `istio-pilot` configurations, such as Service.
- ***Removed*** ports 15029-15032 from the default `ingressgateway`. It is recommended to expose telemetry addons by [host routing](/docs/tasks/observability/gateways/) instead.
- ***Removed*** built in Istio configurations from the installation, including the Gateway, `VirtualServices`, and mTLS settings.
- ***Added*** a new profile, called `preview`, allowing users to try out new experimental features that include WASM enabled telemetry v2.
- ***Added*** `istioctl install` command as a replacement for `istioctl manifest apply`.
- ***Added*** istiod-remote chart to allow users to [experiment with a central Istiod managing a remote data plane](https://github.com/istio/istio/wiki/Central-Istiod-manages-remote-data-plane).

## istioctl

- ***Added*** better display characteristics for the istioctl command.
- ***Added*** support for key:value list selection when using --set flag paths.
- ***Added*** support for deletes and setting non-scalar values when using the Kubernetes overlays patching mechanism.

## Documentation changes

- ***Added*** new and improved Istio documentation. For more information, see [Website content changes](/docs/releases/log/).
