---
title: Istio 1.10 Change Notes
linktitle: 1.10 Change Notes
description: Istio 1.10.0 release notes.
publishdate: 2021-05-18
release: 1.10
weight: 10
---

## Deprecation Notices

These notices describe functionality that will be removed in a future release according to [Istio's deprecation policy](/docs/releases/feature-stages/#feature-phase-definitions). Please consider upgrading your environment to remove the deprecated functionality.

- **Deprecated** the `values.global.jwtPolicy=first-party-jwt` option. This option is less secure and intended for backwards compatibility
with older Kubernetes clusters without support for more secure token authentication but is now enabled by default in new Kubernetes versions. See [this documentation](/docs/ops/best-practices/security/#configure-third-party-service-account-tokens) for more information.

- **Deprecated** the `values.global.arch` option in favor of the affinity Kubernetes settings.
  ([Issue #30027](https://github.com/istio/istio/issues/30027))

- **Deprecated** the `remote` installation profile and added the `external` profile for installing Istio with an external control plane.
  ([Issue #32370](https://github.com/istio/istio/issues/32370))

## Traffic Management

- **Added** `meshConfig.discoverySelectors` to dynamically restrict the set of namespaces for `Services`, `Pods`, and `Endpoints` that istiod processes when pushing xDS updates to improve performance on the data plane.
  ([Blog](/blog/2021/discovery-selectors/), [Issue #26679](https://github.com/istio/istio/issues/26679))

- **Added** the `ISTIO_GATEWAY_STRIP_HOST_PORT` environment variable to control whether gateways strip the host port before any processing of requests by HTTP filters or routing. This option is disabled by default.
  ([Issue #25350](https://github.com/istio/istio/issues/25350))

- **Fixed** configuration of TLS parameters (TLS version, TLS cipher suites, curves, etc.) with `EnvoyFilter`.
  ([Issue #28996](https://github.com/istio/istio/issues/28996))

- **Fixed** an issue where the filter chain name was ignored when processing `EnvoyFilter` match.
  ([Issue #31166](https://github.com/istio/istio/issues/31166))

- **Improved** the full push scoping by adding `Sidecar` config to `sidecarScopeKnownConfigTypes`.

- **Improved** virtual machine integration to clean up `iptables` rules when the service is stopped.
  ([Issue #29556](https://github.com/istio/istio/issues/29556))

- **Updated** istio-proxy drain notification strategy from gradual to immediate.
  ([Issue #31403](https://github.com/istio/istio/issues/31403))

- **Added** CNI metrics counting repair operations.
  ([Issue #19300](https://github.com/istio/istio/issues/19300))

- **Added** `/debug/connections` istiod debug interface to list the current connected clients.
  ([Issue #31075](https://github.com/istio/istio/issues/31075))

- **Added** SDS secrets fetch failure metric `pilot_sds_certificate_errors_total`.
  ([Issue #31779](https://github.com/istio/istio/issues/31779))

- **Added** metrics for istiod informer errors.

- **Fixed** a bug where `ISTIO_META_IDLE_TIMEOUT` is not reflected when set to `0s`.
  ([Issue #30067](https://github.com/istio/istio/issues/30067))

- **Fixed** a bug causing unnecessary full push in service entry store.
  ([Issue #30683](https://github.com/istio/istio/issues/30683))

- **Fixed** a bug where the `EnvoyFilter` `HTTP_FILTER` didn't support `INSERT_FIRST`.
  ([Issue #31573](https://github.com/istio/istio/issues/31573))

- **Fixed** an issue where services with `PASSTHROUGH` load balancing were always sent mTLS traffic, even if the destinations did not support mTLS.
  ([Issue #23494](https://github.com/istio/istio/issues/23494))

- **Fixed** a bug where `EnvoyFilter` with service match did not work for inbound clusters.

## Security

- **Added** an experimental feature to allow dry-run of an `AuthorizationPolicy` without actually enforcing the policy.
 ([Usage](/docs/tasks/security/authorization/authz-dry-run/), [Design](https://docs.google.com/document/d/1xQdZsEgJ3Ld2qebfT3EJkg2COTtCR1TqBVojmnvI78g), [PR #1933](https://github.com/istio/api/pull/1933))

- **Updated** configuration to sign istiod certificates using Kubernetes CA (`PILOT_CERT_PROVIDER=kubernetes`) will not be honored in
clusters with version 1.22 and greater.
  ([Issue #22161](https://github.com/istio/istio/issues/22161))

- **Improved** the experimental [External Authorization](/docs/tasks/security/authorization/authz-custom/) feature with new capabilities:
    - **Added** the `timeout` field to configure the timeout (default is `10m`) between the `ext_authz` filter and the external service.
    - **Added** the `include_additional_headers_in_check` field to send additional headers to the external service.
    - **Added** the `include_request_body_in_check` field to send the body to the external service.
    - **Supported** prefix and suffix match in the `include_request_headers_in_check`, `headers_to_upstream_on_allow` and `headers_to_downstream_on_deny` field.
    - **Deprecated** the `include_headers_in_check` field with the new `include_request_headers_in_check` field for better naming. ([Reference](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-EnvoyExternalAuthorizationHttpProvider), [PR #1926](https://github.com/istio/api/pull/1926))

- **Added** experimental option to configure Envoy to fetch the JWKS by itself. This should be enabled if the `jwks_uri` is a mesh cluster URL for mTLS and has other benefits like retries, JWKS caching etc.
This is disabled by default and can be enabled by setting `PILOT_JWT_ENABLE_REMOTE_JWKS` to true.
  ([Issue #28742](https://github.com/istio/istio/issues/28742))

- **Added** an environment variable `PILOT_JWT_PUB_KEY_REFRESH_INTERVAL` to configure the interval of
istiod fetching the `jwks_uri` for the JWKS public key. Users can set the refresh interval with
`--set values.pilot.env.PILOT_JWT_PUB_KEY_REFRESH_INTERVAL=<duration>` during installation.
The default interval is `20m`. Valid time units are "ns", "us", "ms", "s", "m", "h".

- **Update** the istiod JWT public key refresh job to retry the failed fetch of the `jwks_uri` with exponential backoff.
  ([Issue #30261](https://github.com/istio/istio/issues/30261))

- **Removed** ability to configure `trustDomain` from Helm `global.values`. Now it is configured through `meshConfig.trustDomain` ([Issue #27734](https://github.com/istio/istio/issues/27734))

- **Fixed** an issue causing simple TLS traffic to ports not exposed by a `Service` to be rejected by servers when in `PERMISSIVE` mTLS mode.
  ([Issue #31297](https://github.com/istio/istio/issues/31297))

## Telemetry

- **Added** experimental support for the Telemetry API.
  ([Issue #24284](https://github.com/istio/istio/issues/24284))

- **Fixed** the missing `destination_cluster` metric label reported by client proxy on request failures.
  ([Issue #29373](https://github.com/istio/istio/issues/29373))

- **Fixed** an issue where Envoy did not start up properly when duplicate stats tags were configured.
  ([Issue #31270](https://github.com/istio/istio/issues/31270))

## Extensibility

- **Added** reliable Wasm module remote load with istio-agent.
  ([Issue #29989](https://github.com/istio/istio/issues/29989))

## Installation

- **Added** `istioctl experimental revision tag` command group. Revision tags act as aliases for
control plane revisions. Users can label their namespaces with a revision tag rather than pointing them
directly at a revision and selectively decide the granularity of their namespace labels. This makes it possible
to perform upgrades with the ease of in-place upgrades while having the safety of revision-based upgrades
under the hood. Read more about using revision tags [here](/docs/setup/upgrade/canary/#stable-revision-labels-experimental).

- **Improved** `ConfigMaps` to be read directly rather than from volume mounts. This improves the speed
of updates and ensures that for external istiod installations that the configmaps are read from the config cluster.
  ([Issue #31410](https://github.com/istio/istio/issues/31410))

- **Improved** the sidecar injector to better utilize pod labels to determine if injection is required.
  ([Issue #30013](https://github.com/istio/istio/issues/30013))

- **Updated** non-revisioned installs to target the label `istio.io/rev=default` for injection in addition to the
existing default injection labels (`istio-injection=enabled` and `sidecar.istio.io/inject=true`).

- **Added** support for slash characters in environment variables on `injectionURL`.
  ([Issue #31732](https://github.com/istio/istio/issues/31732))

- **Added** an `external` profile for installing Istio with an external control plane and deprecated the `remote` profile.
  ([Issue #32370](https://github.com/istio/istio/issues/32370))

- **Fixed** a bug preventing `istioctl kube-inject` from working with revisions.
  ([Issue #30991](https://github.com/istio/istio/issues/30991))

- **Improved** the output of istioctl YAML diff commands.
  ([Issue #31186](https://github.com/istio/istio/issues/31186))

- **Removed** the `15012` and `15443` ports from the default gateway installation. These can be explicitly
[added](/docs/setup/install/istioctl/#configure-gateways) if desired, although it is
recommended to follow the new [multicluster installation guide](/docs/setup/install/multicluster/) instead.

- **Updated** Kiali addon to the latest version `v1.34`.

## istioctl

- **Updated** the `istioctl experimental precheck` command to identify potential upgrade issues prior to actually running an upgrade.

- **Updated** `istioctl kube-inject` to call the webhook server to get the injection template by default.
  ([Issue #29270](https://github.com/istio/istio/issues/29270))

- **Added** `istioctl experimental internal-debug` to retrieve istiod debug information via a secured debug interface.
  ([Issue #31338](https://github.com/istio/istio/issues/31338))

- **Added** `istioctl validate` and the validating webhook now report duplicate or unreachable virtual service matches.
  ([Issue #31525](https://github.com/istio/istio/issues/31525))

- **Added** `istioctl proxy-config -o yaml` to display in YAML along with the current JSON and short format.
 ([Usage](/docs/reference/commands/istioctl/#istioctl-proxy-config), [Issue #31695](https://github.com/istio/istio/issues/31695))

- **Added** the `istioctl proxy-config all` command to view the full proxy configuration.

- **Added** tooling for revision-centric view of current Istio deployments in a cluster. This is to
provide a better understanding of deployments- such as the number of istiod, gateway pods, `IstioOperator` custom resources-
defining a particular revision, and the number of pods with sidecars pointing to a particular revision. ([Issue #23892](https://github.com/istio/istio/issues/23892))

- **Added** a new analyzer for invalid webhook configurations.

- **Fixed** an issue where `istioctl x create-remote-secret --secret-name` failed incorrectly when pointing to a non-existent secret in the remote cluster.  ([Issue #30723](https://github.com/istio/istio/issues/30723))
