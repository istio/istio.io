---
title: Change Notes
description: Istio 1.8 release notes.
weight: 10
---

## Traffic Management

- **Added** support for injecting `istio-cni` into `k8s.v1.cni.cncf.io/networks` annotation with preexisting value that uses JSON notation.
  ([Issue #25744](https://github.com/istio/istio/issues/25744))

- **Added** support for `INSERT_FIRST`, `INSERT_BEFORE`, `INSERT_AFTER` insert operations for `HTTP_ROUTE` in `EnvoyFilter`  ([Issue #26692](https://github.com/istio/istio/issues/26692))

- **Added** `REPLACE` operation for `EnvoyFilter`. `REPLACE` operation can replace the contents of a named filter with new contents. It is only valid for `HTTP_FILTER` and `NETWORK_FILTER`.
  ([Issue #27425](https://github.com/istio/istio/issues/27425))

- **Added** Istio resource status now includes observed generation
  ([Issue #28003](https://github.com/istio/istio/issues/28003))

- **Fixed** remove endpoints when the new labels in `WorkloadEntry` do not match the `workloadSelector` in `ServiceEntry`.
  ([Issue #25678](https://github.com/istio/istio/issues/25678))

- **Fixed** when a node has multiple IP addresses (e.g., a VM in the mesh expansion scenario),
Istio Proxy will now bind `inbound` listeners to the first applicable address in the list
(new behavior) rather than to the last one (former behavior).
  ([Issue #28269](https://github.com/istio/istio/issues/28269))

## Security

- **Improved** Gateway certificates to be read and distributed from Istiod, rather than in the gateway pods.
This reduces the permissions required in the gateways, improves performance, and will make certificate reading
more flexible in the future. This change is fully backwards compatible with the old method, and requires no changes
to your cluster. If required, it can be disabled by setting the `ISTIOD_ENABLE_SDS_SERVER=false`
environment variable in Istiod.

- **Improved** TLS configuration on sidecar server side inbound paths to enforce `TLSv2` version along with recommended cipher suites.
             If this is not needed or creates problems with non Envoy clients, it can disabled by setting env variable `PILOT_SIDECAR_ENABLE_INBOUND_TLS_V2` to false.

- **Updated** The `ipBlocks`/`notIpBlocks` fields of an `AuthorizationPolicy` now strictly refer to the source IP address of the IP packet as it arrives at the sidecar.  Prior to this release, if using the Proxy Protocol, then the `ipBlocks`/`notIpBlocks` would refer to the IP address determined by the Proxy Protocol.  Now the `remoteIpBlocks`/`notRemoteIpBlocks` fields must be used to refer to the client IP address from the Proxy Protocol.
 ([reference](/docs/reference/config/security/authorization-policy/))([usage](/docs/ops/configuration/traffic-management/network-topologies/))([usage](/docs/tasks/security/authorization/authz-ingress/)) ([Issue #22341](https://github.com/istio/istio/issues/22341))

- **Added** `AuthorizationPolicy` now supports nested JWT claims.
  ([Issue #21340](https://github.com/istio/istio/issues/21340))

- **Added** support for client side Envoy secure naming config when trust domain alias is used.
This fixes the multi-cluster service discovery client SAN generation to use all endpoints' service accounts rather than the first found service registry.

- **Added** Experimental feature support allowing Istiod to integrate with external certificate authorities using Kubernetes CSR API (>=1.18 only).
  ([Issue #27606](https://github.com/istio/istio/issues/27606))

- **Added** Enable user to set the custom VM identity provider for credential authentication
  ([Issue #27947](https://github.com/istio/istio/issues/27947))

- **Added** action 'AUDIT' to Authorization Policy that can be used to determine which requests should be audited.
  ([Issue #25591](https://github.com/istio/istio/issues/25591))

- **Added** support for migration and concurrent use of regular K8S tokens as well as new K8S tokens with audience. This feature is enabled by
default, can be disabled by `REQUIRE_3P_TOKEN` environment variable in Istiod, which will require new tokens with audience. The
`TOKEN_AUDIENCES` environment variable allows customizing the checked audience, default remains `istio-ca`.

- **Added** `AuthorizationPolicy` now supports a `Source` of type `remoteIpBlocks`/`notRemoteIpBlocks` that map to a new `Condition` attribute called `remote.ip` that can also be used in the "when" clause.  If using an http/https load balancer in front of the ingress gateway, the `remote.ip` attribute is set to the original client IP address determined by the `X-Forwarded-For` http header from the trusted proxy configured through the `numTrustedProxies` field of the `gatewayTopology` under the `meshConfig` when you install Istio or set it via an annotation on the ingress gateway.  See the documentation here: [Configuring Gateway Network Topology](/docs/ops/configuration/traffic-management/network-topologies/). If using a TCP load balancer with the Proxy Protocol in front of the ingress gateway, the `remote.ip` is set to the original client IP address as given by the Proxy Protocol.
 ([reference](/docs/reference/config/security/authorization-policy/))([usage](/docs/ops/configuration/traffic-management/network-topologies/))([usage](/docs/tasks/security/authorization/authz-ingress/)) ([Issue #22341](https://github.com/istio/istio/issues/22341))

- **Added** Trust Domain Validation by default rejecting requests in sidecars if the request is not from same trust domain
or if it's not in the `TrustDomainAliases` specified in the `MeshConfig`.
  ([Issue #26224](https://github.com/istio/istio/issues/26224))

## Telemetry

- **Updated** the "Control Plane Dashboard" and the "Performance Dashboard" to use the `container_memory_working_set_bytes` metric
to display memory. This metric only counts memory that *cannot be reclaimed* by the kernel even under memory pressure,
and therefore more relevant for tracking. It is also consistent with `kubectl top`. The reported values are lower than
the previous values.

- **Updated** the Istio Workload and Istio Service dashboards to improve loading time.
  ([Issue #22408](https://github.com/istio/istio/issues/22408))

- **Added** `datasource` parameter to Grafana dashboards
  ([Issue #22408](https://github.com/istio/istio/issues/22408))

- **Added** Listener Access Logs when `ResponseFlag` from Envoy is set.
  ([Issue #26851](https://github.com/istio/istio/issues/26851))

- **Added** support for `OpenCensusAgent` formatted trace export with configurable trace context headers.

- **Added** Proxy config to control Envoy native stats generation.
  ([Issue #26546](https://github.com/istio/istio/issues/26546))

- **Added** Istio Wasm Extension Grafana Dashboard.
  ([Issue #25843](https://github.com/istio/istio/issues/25843))

- **Added** gRPC streaming message count proxy Prometheus `metrics istio_request_messages_total` and `istio_response_messages_total`
  ([PR #3048](https://github.com/istio/proxy/pull/3048))

- **Added** support for properly labeling traffic in client metrics for cases when the destination is not reached or is not behind a proxy.
  ([Issue #20538](https://github.com/istio/istio/issues/20538))

- **Fixed** interpretation of `$(HOST_IP)` in Zipkin and Datadog tracer address.
  ([Issue #27911](https://github.com/istio/istio/issues/27911))

- **Removed** all Mixer-related features and functionality. This is a scheduled
removal of a deprecated Istio services and deployments, as well as
Mixer-focused CRDs and component and related functionality.
  ([Issue #25333](https://github.com/istio/istio/issues/25333)),([Issue #24300](https://github.com/istio/istio/issues/24300))

## Installation

- **Added** support for [installing and upgrading Istio](/docs/setup/install/helm/) using [Helm 3](https://helm.sh/docs/)

- **Improved** multi-network configuration so that labeling a service with `topology.istio.io/network=network-name` can
configure cross-network gateways without using [mesh networks](/docs/reference/config/istio.mesh.v1alpha1/#MeshNetworks).

- **Improved** sidecar injection to not modify the pod `securityPolicy.fsGroup` which could conflict with existing settings and secret mounts.
 This option is enabled automatically on Kubernetes 1.19+ and is not supported on older versions.
  ([Issue #26882](https://github.com/istio/istio/issues/26882))

- **Improved** Generated operator manifests for use with `kustomize` are available in the [manifests]({{< github_tree >}}/manifests/charts/istio-operator/files) directory.
  ([Issue #27139](https://github.com/istio/istio/issues/27139))

- **Updated** install script to bypass GitHub API Rate Limiting.

- **Added** port `15012` to the default list of ports for the `istio-ingressgateway` Service.
  ([Issue #25933](https://github.com/istio/istio/issues/25933))

- **Added** support for Kubernetes versions 1.16 to 1.19 to Istio 1.8.
  ([Issue #25793](https://github.com/istio/istio/issues/25793))

- **Added** the ability to specify the network for a Pod using the label `topology.istio.io/network`. This overrides the setting for the cluster's installation values (`values.globalnetwork`). If the label isn't set, it is injected based on the global value for the cluster.
  ([Issue #25500](https://github.com/istio/istio/issues/25500))

- **Deprecated** installation flags `values.global.meshExpansion.enabled` in favor of user-managed config and `values.gateways.istio-ingressgateway.meshExpansionPorts` in favor of `components.ingressGateways[name=istio-ingressgateway].k8s.service.ports`
  ([Issue #25933](https://github.com/istio/istio/issues/25933))

- **Fixed** Istio operator manager to allow configuring `RENEW_DEADLINE`.
  ([Issue #27509](https://github.com/istio/istio/issues/27509))

- **Fixed** an issue preventing `NodePort` services from being used as the `registryServiceName` in `meshNetworks`.

- **Removed** support for installing third-party telemetry applications with `istioctl`. These applications (Prometheus, Grafana, Zipkin, Jaeger, and Kiali), often referred to as the Istio addons, must now be installed separately. This does not impact Istio's ability to produce telemetry for those use in the addons. See [Reworking our Addon Integrations](/blog/2020/addon-rework/) for more info.
  ([Issue #23868](https://github.com/istio/istio/issues/23868)),([Issue #23583](https://github.com/istio/istio/issues/23583))

- **Removed** `istio-telemetry` and `istio-policy` services and deployments from installation by `istioctl`.
  ([Issue #23868](https://github.com/istio/istio/issues/23868)),([Issue #23583](https://github.com/istio/istio/issues/23583))

## istioctl

- **Improved** `istioctl analyze` to find the exact line number with configuration errors when analyzing yaml files.
Before, it would return the first line of the resource with the error.
  ([Issue #22872](https://github.com/istio/istio/issues/22872))

- **Updated** `istioctl experimental version` and `proxy-status` to use token security.
A new option, `--plaintext`, has been created for testing without tokens.
  ([Issue #24905](https://github.com/istio/istio/issues/24905))

- **Added** istioctl commands may now refer to pods indirectly, for example `istioctl dashboard envoy deployment/httpbin`
  ([Issue #26080](https://github.com/istio/istio/issues/26080))

- **Added** `io` as short name for Istio Operator resources in addition to `iop`.
  ([Issue #27159](https://github.com/istio/istio/issues/27159))

- **Added** `--type` for `istioctl experimental create-remote-secret` to allow user specify type for the created secret.

- **Added** an experimental OpenShift Kubernetes platform profile to `istioctl`. To install with the OpenShift profile, use `istioctl install --set profile=openshift`.
 ([OpenShift Platform Setup](/docs/setup/platform-setup/openshift/))([Install OpenShift using `istioctl`](/docs/setup/install/istioctl/#install-a-different-profile))

- **Added** `istioctl bug-report` command to generate an archive of Istio and cluster information to assist with debugging.
  ([Issue #26045](https://github.com/istio/istio/issues/26045))

- **Added** new command `istioctl experimental istiod log` to enable managing logging levels
of `istiod` components.
  ([Issue #25276](https://github.com/istio/istio/issues/25276)),([Issue #27797](https://github.com/istio/istio/issues/27797))

- **Deprecated** `centralIstiod` flag in favor of `externalIstiod` to better support external control plane model.
  ([Issue #24471](https://github.com/istio/istio/issues/24471))

- **Fixed** an issue which allowed an empty revision flag on install.  ([Issue #26940](https://github.com/istio/istio/issues/26940))