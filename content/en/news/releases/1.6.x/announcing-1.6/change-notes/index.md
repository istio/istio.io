---
title: Change Notes
description: Istio 1.6 release notes.
weight: 10
---

## Traffic Management

- ***Added*** the new [Workload Entry](/docs/reference/config/networking/workload-entry/) resource. This will allow easier configuration for non-Kubernetes workloads to join the mesh.
- ***Added*** configuration for gateway topology. This addresses sanitizing and providing useful [X-Forward-For headers](https://github.com/istio/istio/issues/7679).
- ***Added*** experimental support for the [Kubernetes Service APIs](https://github.com/kubernetes-sigs/service-apis/).
- ***Added*** support for using `appProtocol` to select the [protocol for a port](/docs/ops/configuration/traffic-management/protocol-selection/) introduced in Kubernetes 1.18.
- ***Changed*** gateway SDS to be enabled by default.  File mounted gateway continues to be available to help users to transition to secure gateway SDS.
- ***Improved*** support for [Kubernetes ingress](/docs/tasks/traffic-management/ingress/kubernetes-ingress/), adding support for reading certificates from Secrets, `pathType`, and `IngressClass`.
- ***Added*** a new `proxy.istio.io/config` annotation to override proxy configuration per pod.
- ***Removed*** most configuration flags and environment variables for the proxy. These are now read directly from the mesh configuration.
- ***Changed*** the proxy readiness probe to port 15021.
- ***Fixed*** a [bug](https://github.com/istio/istio/issues/16458) blocking external HTTPS/TCP traffic in some cases.

## Security

- ***Removed*** Security alpha API.

## Telemetry

- ***Added*** experimental [request classification](/docs/tasks/observability/metrics/classify-metrics/) filter support. This feature enables operators to configure new attributes for use in telemetry, based on request information. A primary use case for this feature is labeling of traffic by API method.
- ***Added*** experimental [mesh-wide tracing configuration API](/docs/tasks/observability/distributed-tracing/configurability/). This API provides control of trace sampling rates, the [maximum tag lengths](https://github.com/istio/istio/issues/14563) for URL tags, and [custom tags extraction](https://github.com/istio/istio/issues/13018) for all traces within the mesh.
- ***Improved*** Prometheus integration experience by adding standard Prometheus scrape annotations to proxies and the control plane workloads. This removes the need for specialized configuration to discover and consume Istio metrics. More details are available in the [operations guide for Prometheus](/docs/ops/integrations/prometheus#option-2-metrics-merging/).
- ***Improved*** support for [customizing v2 metrics generation](/docs/tasks/observability/metrics/customize-metrics/). This allows mesh operators to add and remove labels used in Istio metrics based on expressions over the set of available request and response attributes.
- ***Updated*** default telemetry v2 configuration to avoid using host header to extract destination service name at gateway. This prevents unbound cardinality due to untrusted host header and implies that destination service labels are going to be omitted for request hits `blackhole` and `passthrough` at gateway.
- ***Added*** automated publishing of Grafana dashboards to `grafana.com` as part of the Istio release process. Please see the [Istio org page](https://grafana.com/orgs/istio) for more information.
- ***Updated*** Grafana dashboards to adapt to the new Istiod deployment model.

## Configuration Management

## Installation

- ***Improved*** Please see the [Upgrade guide](/docs/setup/upgrade/) for migration. In-place upgrades are now possible in Istio.
- ***Removed*** the legacy Helm charts.
- ***Added*** Allow users to add a custom hostname for istiod.
- ***Changed*** Gateway ports used (15020) and [resolution](https://github.com/istio/istio/pull/23432#issuecomment-622208734) for end users.
- ***Added*** functionality to save installation state in a `CustomResource` in the cluster.
- ***Improved*** installation to not manage the installation namespace, allowing more flexibility.
- ***Removed*** the Citadel, Sidecar Injector, and Galley deployments. These were disabled by default in 1.5, and all functionality has moved into Istiod.
- ***Removed*** the legacy `istio-pilot` configurations, such as Service.
- ***Removed*** ports 15029-15032 from the default `ingressgateway`. It is recommended to expose telemetry addons by [host routing](/docs/tasks/observability/gateways/) instead.
- ***Removed*** built in Istio configurations from the installation, including the Gateway, `VirtualServices`, and mTLS settings.
- ***Added*** a new preview profile, allowing users to try out new experimental features that include Wasm enabled telemetry v2.
- ***Added*** `istioctl install` command as a replacement for `istioctl manifest apply`.

## Operator

## istioctl

- ***Improved*** the display characteristics of the istioctl command. Surprise awaits!
- ***Improved*** --set flag paths support key:value list selection.
- ***Improved*** Kubernetes overlays patching mechanism now supports deletes and setting non-scalar values.

## Miscellaneous changes

- ***Improved*** the quality of the website content and structure
