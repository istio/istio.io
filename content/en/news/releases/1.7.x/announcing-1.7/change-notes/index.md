---
title: Change Notes
description: Istio 1.7 release notes.
weight: 10
---

## Traffic Management

- **Added** config option `values.global.proxy.holdApplicationUntilProxyStarts`,
which causes the sidecar injector to inject the sidecar at the start of the
pod's container list and configures it to block the start of all other
containers until the proxy is ready.  This option is disabled by default.
 ([Issue #11130](https://github.com/istio/istio/issues/11130))

## Security

- **Fixed** an issue preventing the use of source principal based authorization at Istio Gateway when the Server's TLS mode is ISTIO_MUTUAL.

- **Added** Enable the workload cert rotate automatically in VM
 ([Issue #24554](https://github.com/istio/istio/issues/24554))

- **Added** support for creation of CSRs using ECC based certificates.
 ([Issue #23226](https://github.com/istio/istio/issues/23226))

## Telemetry

- **Enabled** Prometheus [metrics merging](/docs/ops/integrations/prometheus/#option-1-metrics-merging) by default.
 ([Issue #21366](https://github.com/istio/istio/issues/21366))

- **Deprecated** installation of telemetry addons by `istioctl`. These will be disabled by default, and in a future release removed entirely. More information on installing these addons can be found in the [Integrations](/docs/ops/integrations/) page.
 ([Issue #22762](https://github.com/istio/istio/issues/22762))

- **Removed** the `pilot_xds_eds_instances` and `pilot_xds_eds_all_locality_endpoints` Istiod metrics, which were not
accurate.
 ([Issue #25154](https://github.com/istio/istio/issues/25154))

- **Added** Prometheus metrics to istio-agent.
 ([Issue #22825](https://github.com/istio/istio/issues/22825))
- **Fixed** Prometheus [metrics merging](/docs/ops/integrations/prometheus/#option-1-metrics-merging) to not drop Envoy metrics during application failures.
 ([Issue #22825](https://github.com/istio/istio/issues/22825))

## Installation

- **Upgraded** the CRD and Webhook versions to `v1`.
 ([Issue #18771](https://github.com/istio/istio/issues/18771)),([Issue #18838](https://github.com/istio/istio/issues/18838))

- **Improved** gateway deployments to run as non-root by default.
 ([Issue #23379](https://github.com/istio/istio/issues/23379))

- **Added** RPM packages for running the Istio sidecar on a VM to the release.
 ([Issue #9117](https://github.com/istio/istio/issues/9117))

- **Fixed** an issue preventing NodePort services from being used as the `registryServiceName` in `meshNetworks`.

## istioctl

- **Added** Allow proxy-status for non-K8s workloads with --file

- **Removed** `istioctl manifest apply`. The simpler `install` command replaces manifest apply.
 ([Issue #25737](https://github.com/istio/istio/issues/25737))

- **Improved** `istioctl validate` to check for unknown fields in resources.
 ([Issue #24861](https://github.com/istio/istio/issues/24861))

- **Added** configuration file handling for istioctl defaults. Also added environment variable `ISTIOCONFIG` for selecting that file (default $HOME/.istioctl/config.yaml). Also added 'istioctl experimental config list' subcommand to show configured flag defaults.
 ([Issue #23868](https://github.com/istio/istio/issues/23868))

- **Added** `--revision` flag to `istioctl operator init` and `istioctl operator remove` commands to support multiple control plane upgrade.
 ([Issue #23479](https://github.com/istio/istio/issues/23479))

- **Added** `istioctl analyze` now warns if deprecated mixer resources are present
 ([Issue #24471](https://github.com/istio/istio/issues/24471))

- **Added** `istioctl x uninstall` command to uninstall Istio control plane.
 ([Issue #24360](https://github.com/istio/istio/issues/24360))

## Documentation changes

- **Added** support for autogenerating release notes based off of a file present in the /releasenotes/notes directory.
 ([Issue #23622](https://github.com/istio/istio/issues/23622))
