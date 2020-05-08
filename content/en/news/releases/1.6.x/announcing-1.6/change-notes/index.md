---
title: Change Notes
description: Istio 1.6 release notes.
weight: 10
---

## Traffic Management

- ***Added*** experimental support for the [Kubernetes Service APIs](https://github.com/kubernetes-sigs/service-apis).
- ***Improved*** support for [Kubernetes Ingress](https://preliminary.istio.io/docs/tasks/traffic-management/ingress/kubernetes-ingress/), adding support for reading certificates from Secrets, `pathType`, and IngressClass.
- ***Fixed*** a [bug](https://github.com/istio/istio/issues/16458) blocking external HTTPS/TCP traffic in some cases.
- ***Removed*** most configuration flags and environment variables for the proxy. These are now read directly from the mesh configuration.
- ***Added*** a new `proxy.istio.io/config` annotation to override proxy configuration per pod.
- ***Added*** support for using appProtocol to select the [protocol for a port](https://preliminary.istio.io/docs/ops/configuration/traffic-management/protocol-selection/) for Kubernetes 1.18+.
- ***Added*** the new [Workload Entry](https://preliminary.istio.io/docs/reference/config/networking/workload-entry/) resource. This will allow easier configuration for non-Kubernetes workloads to join the mesh.
- ***Added*** support for configuring Gateway topology settings like number of trusted proxies deployed in front
- Moved the proxy readiness probe to port 15021
- TODO: add a statement around file mounted gateway removed and impact to users.
- TODO: add a statement around networking v1alpha3 API.. will it be removed in 1.6 or announce deprecation?

## Security

- TODO removal of alpha API
- SDS for mixer? Not sure we need this or its an implementation detail

## Telemetry

- ***Added*** automated publishing of Grafana dashboards to grafana.com as part of the Istio release process. Please see the [istio org page](https://grafana.com/orgs/istio) for more information.
- ***Improved*** Prometheus integration experience by adding standard Prometheus scrape annotations to proxies and the control plane workloads. This removes the need for specialized configuration to discover and consume Istio metrics. More details are availabe in the [design doc](https://docs.google.com/document/d/1TTeN4MFmh4aUYYciR4oDBTtJsxl5-T5Tu3m3mGEdSo8/edit).
- ***Improved*** Grafana dashboards to adapt to the new Istiod deployment model.
- ***Updated*** default Telemetry V2 configuration to avoid using host header to extract destination service name at gateway. This prevents unbound cardinality due to untrusted host header and implies that destination service labels are going to be omitted for request hits Blackhole and Passthrough at gateway.
- ***Added*** experimental tracing options

## Configuration Management

## Installation

- ***Removed*** the Citadel, Sidecar Injector, and Galley deployments. These were disabled by default in 1.5, and all functionality has moved into Istiod.
- ***Removed*** ports 15029-15032 from the default ingressgateway. It is recommended to expose telemetry addons by [Host routing](https://preliminary.istio.io/docs/tasks/observability/gateways/) instead.
- ***Removed*** the legacy Helm charts. Please see the [Upgrade guide](https://preliminary.istio.io/docs/setup/upgrade/) for migration.
- TODO helm3/kustomize support? should we mention something here?
- ***Improved*** installation to not manage the installation namespace, allowing more flexibility.
- ***Removed*** the legacy istio-pilot configurations, such as Service.
- ***Removed*** built in Istio configurations from the installation, including the Gateway, VirtualServices, and mTLS settings.
- ***Added*** a new preview profile, allowing users to try out new experimental features.
- ***Added*** `istioctl install` command as a replacement for `istioctl manifest apply`.
- ***Added*** functionality to save  installation state in a CustomResource in the cluster.
- ***Changed*** Gateway ports used (15020) and [resolution](https://github.com/istio/istio/pull/23432#issuecomment-622208734) for end users
- ***Added*** Allow users to add a custom hostname for istiod

## Operator

## istioctl

- ***Improved*** the output of the istioctl install command.
- ***Added*** a new command, istioctl install. This is an alias for manifest apply.
