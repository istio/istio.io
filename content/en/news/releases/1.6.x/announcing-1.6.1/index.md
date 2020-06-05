---
title: Announcing Istio 1.6.1
linktitle: 1.6.1
subtitle: Patch Release
description: Istio 1.6.1 patch release.
publishdate: 2020-06-04
release: 1.6.1
aliases:
    - /news/announcing-1.6.1
---

This release contains bug fixes to improve robustness. This release note describes
what’s different between Istio 1.6.0 and Istio 1.6.1.

{{< relnote >}}

## Changes

- **Fixed** support for pod annotations to override mesh-wide proxy settings
- **Updated** `EnvoyFilter` to register all filter types in order to support `typed_config` attributes ([Issue 23909](https://github.com/istio/istio/issues/23909))
- **Fixed** handling of custom resource names for Gateways ([Issue 23303](https://github.com/istio/istio/issues/23303))
- **Fixed** an issue where `istiod` fails to issue certificates to a remote cluster. `Istiod` now has support for the cluster name and certificate to generate the `injectionURL` ([Issue 23879](https://github.com/istio/istio/issues/23879))
- **Fixed** remote cluster's validation controller to check `istiod`'s ready status endpoint ([Issue 23945](https://github.com/istio/istio/issues/23945))
- **Improved** `regexp` fields validation to match Envoy's validation ([Issue 23436](https://github.com/istio/istio/issues/23436))
- **Fixed** `istioctl analyze` to validate `networking.istio.io/v1beta1` resources ([Issue 24064](https://github.com/istio/istio/issues/24064))
- **Fixed** typo of `istio` in `ControlZ` dashboard log ([Issue 24039](https://github.com/istio/istio/issues/24039))
- **Fixed** tar name to directory translation ([Issue 23635](https://github.com/istio/istio/issues/23635))
- **Improved** certificate management for multi-cluster and virtual machine setup from `samples/certs` directory to `install/tools/certs` directory
- **Improved** `pilot-agent`'s handling of client certificates when only a CA client certificate is present
- **Improved** `istiocl upgrade` to direct users to the `istio.io` website to migrate from `v1alpha1` security policies to `v1beta1` security policies
- **Fixed** release URL name for `istioctl upgrade`
- **Fixed** `k8s.overlays` for cluster resources
- **Fixed** `HTTP/HTTP2` conflict at Gateway ([Issue 24061](https://github.com/istio/istio/issues/24061) and [Issue 19690](https://github.com/istio/istio/issues/19690))
- **Fixed** Istio operator to respect the `--operatorNamespace` argument ([Issue 24073](https://github.com/istio/istio/issues/24073))
- **Fixed** Istio operator hanging when uninstalling Istio ([Issue 24038](https://github.com/istio/istio/issues/24038))
- **Fixed** TCP metadata exchange for upstream clusters that specify `http2_protocol_options` ([Issue 23907](https://github.com/istio/istio/issues/23907))
- **Added** `sideEffects` field to `MutatingWebhookConfiguration` for `istio-sidecar-injector` ([Issue 23485](https://github.com/istio/istio/issues/23485))
- **Improved** installation for replicated control planes ([Issue 23871](https://github.com/istio/istio/issues/23871))
- **Fixed** `istioctl experimental precheck` to report compatible versions of Kubernetes (1.14-1.18) ([Issue 24132](https://github.com/istio/istio/issues/24132))
- **Fixed** Istio operator namespace mismatches that caused a resource leak when pruning resources ([Issue 24222](https://github.com/istio/istio/issues/24222))
- **Fixed** SDS Agent failing to start when proxy uses file mounted certs for Gateways ([Issue 23646](https://github.com/istio/istio/issues/23646))
- **Fixed** TCP over HTTP conflicts that caused invalid configuration to be generated ([Issue 24084](https://github.com/istio/istio/issues/24084))
- **Fixed** the use of external name when remote Pilot address is a hostname ([Issue 24155](https://github.com/istio/istio/issues/24155))
- **Fixed** Istio CNI node `DaemonSet` starting when Istio CNI and `cos_containerd` are enabled on Google Kubernetes Engine (GKE) ([Issue 23643](https://github.com/istio/istio/issues/23643))
- **Fixed** Istio CNI causing pod initialization to experience a 30-40 second delay on startup when DNS unreachable ([Issue 23770](https://github.com/istio/istio/issues/23770))
- **Improved** Google Stackdriver telemetry use of UIDs with GCE VMs
- **Improved** telemetry plugins to not crash due invalid configuration ([Issue 23865](https://github.com/istio/istio/issues/23865))
- **Fixed** a proxy sidecar segfault when the response to HTTP calls by WASM filters are empty ([Issue 23890](https://github.com/istio/istio/issues/23890))
- **Fixed** a proxy sidecar segfault while parsing CEL expressions ([Issue 497](https://github.com/envoyproxy/envoy-wasm/issues/497))

## Bookinfo sample application security fixes

We've updated the versions of Node.js and jQuery used in the Bookinfo sample application. Node.js has been upgraded from
version 12.9 to 12.18. jQuery has been updated from version 2.1.4 to version 3.5.0. The highest rated vulnerability fixed:
*HTTP request smuggling using malformed Transfer-Encoding header (Critical) (CVE-2019-15605)*
