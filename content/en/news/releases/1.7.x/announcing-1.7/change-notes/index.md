---
title: Istio 1.7 Change Notes
description: Istio 1.7 release notes.
weight: 10
release: 1.7
subtitle: Minor Release
linktitle: 1.7 Change Notes
publishdate: 2020-08-21
---

## Traffic Management

- **Added** config option `values.global.proxy.holdApplicationUntilProxyStarts`,
which causes the sidecar injector to inject the sidecar at the start of the
pod's container list and configures it to block the start of all other
containers until the proxy is ready.  This option is disabled by default.
 ([Issue #11130](https://github.com/istio/istio/issues/11130))
- **Added** SDS support for Client Certificate and CA certificate used for [TLS/mTLS Origination from Egress Gateway](/docs/tasks/traffic-management/egress/egress-gateway-tls-origination/) using `DestinationRule`.
  ([Issue #14039](https://github.com/istio/istio/issues/14039))

## Security

- **Improved** Trust Domain Validation to validate TCP traffic as well, previously only HTTP traffic was validated.
([Issue #26224](https://github.com/istio/istio/issues/26224))
- **Improved** Istio Gateways to allow use of source principal based authorization when the Server's TLS mode is `ISTIO_MUTUAL`.
([Issue #25818](https://github.com/istio/istio/issues/25818))
- **Improved** VM security. VM identity is now bootstrapped from a short-lived Kubernetes service account token. And VM's workload certificate is automatically rotated.
 ([Issue #24554](https://github.com/istio/istio/issues/24554))

## Telemetry

- **Added** Prometheus metrics to istio-agent.
 ([Issue #22825](https://github.com/istio/istio/issues/22825))
- **Added** Metric customization with `istioctl`.
  ([Issue #25963](https://github.com/istio/istio/issues/25963))
- **Added** TCP Metrics and Access Logs to Stackdriver.
 ([Issue #23134](https://github.com/istio/istio/issues/23134))
- **Deprecated** installation of telemetry addons by `istioctl`. These will be disabled by default, and in a future release removed entirely. More information on installing these addons can be found in the [Integrations](/docs/ops/integrations/) page.
 ([Issue #22762](https://github.com/istio/istio/issues/22762))
- **Enabled** Prometheus [metrics merging](/docs/ops/integrations/prometheus/#option-1-metrics-merging) by default.
 ([Issue #21366](https://github.com/istio/istio/issues/21366))
- **Fixed** Prometheus [metrics merging](/docs/ops/integrations/prometheus/#option-1-metrics-merging) to not drop Envoy metrics during application failures.
 ([Issue #22825](https://github.com/istio/istio/issues/22825))
- **Fixed** Fix unexplained telemetry which affects Kiali graph. This fix increases default outbound protocol sniffing timeout to `5s`, which has impact on server first protocol like `mysql`.
   ([Issue #24379](https://github.com/istio/istio/issues/24379))
- **Removed** the `pilot_xds_eds_instances` and `pilot_xds_eds_all_locality_endpoints` Istiod metrics, which were not
accurate.
 ([Issue #25154](https://github.com/istio/istio/issues/25154))

## Installation

- **Added** RPM packages for running the Istio sidecar on a VM to the release.
 ([Issue #9117](https://github.com/istio/istio/issues/9117))
- **Added** experimental [external Istiod](/blog/2020/new-deployment-model/) support.
- **Fixed** an issue preventing `NodePort` services from being used as the `registryServiceName` in `meshNetworks`.
- **Improved** gateway deployments to run as non-root by default.
 ([Issue #23379](https://github.com/istio/istio/issues/23379))
- **Improved** the operator to run as non-root by default. ([Issue #24960](https://github.com/istio/istio/issues/24960))
- **Improved** the operator by specifying a rigorous security context. ([Issue #24963](https://github.com/istio/istio/issues/24963))
- **Improved** Istiod to run as non-root by default. ([Issue #24961](https://github.com/istio/istio/issues/24961))
- **Improved** Kubernetes strategic merge is used to overlay IstioOperator user files, which improves how list items are handled.
 ([Issue #24432](https://github.com/istio/istio/issues/24432))
- **Upgraded** the CRD and Webhook versions to `v1`.
 ([Issue #18771](https://github.com/istio/istio/issues/18771)),([Issue #18838](https://github.com/istio/istio/issues/18838))

## istioctl

- **Added** Allow [`proxy-status <pod>` command](/docs/reference/commands/istioctl/#istioctl-proxy-status) for non Kubernetes workloads with proxy config passed in from the `--file` parameter.
- **Added** a configuration file to hold istioctl default flags. Its default location (`$HOME/.istioctl/config.yaml`) can be changed using the environment variable `ISTIOCONFIG`. The new command `istioctl experimental config list` shows the default flags.
 ([Issue #23868](https://github.com/istio/istio/issues/23868))
- **Added** `--revision` flag to `istioctl operator init` and `istioctl operator remove` commands to support multiple control plane upgrade.
 ([Issue #23479](https://github.com/istio/istio/issues/23479))
- **Added** `istioctl x uninstall` command to uninstall Istio control plane.
 ([Issue #24360](https://github.com/istio/istio/issues/24360))
- **Improved** `istioctl analyze` to warn if deprecated mixer resources are present
 ([Issue #24471](https://github.com/istio/istio/issues/24471))
- **Improved** `istioctl analyze` to warn if `DestinationRule` is not using `CaCertificates` to validate server identity.
- **Improved** `istioctl validate` to check for unknown fields in resources.
 ([Issue #24861](https://github.com/istio/istio/issues/24861))
- **Improved** `istioctl install` to emit a warning when attempting to install Istio in an old, non supported Kubernetes version.
 ([Issue #26141](https://github.com/istio/istio/issues/26141))
- **Removed** `istioctl manifest apply`. The simpler `install` command replaces manifest apply.
 ([Issue #25737](https://github.com/istio/istio/issues/25737))

## Documentation changes

- **Added** visual indication if an istio.io page has been tested by istio.io automated tests.
 ([Issue #7672](https://github.com/istio/istio.io/issues/7672))
