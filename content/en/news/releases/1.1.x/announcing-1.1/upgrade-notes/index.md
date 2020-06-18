---
title: Upgrade Notes
description: Important changes operators must understand before upgrading to Istio 1.1.
weight: 20
---

This page describes changes you need to be aware of when upgrading from Istio 1.0.x to 1.1.x.  Here we detail cases where we intentionally broke backwards compatibility.  We also mention cases where backwards compatibility was preserved but new behavior was introduced that would be surprising to someone familiar with the use and operation of Istio 1.0.

For an overview of new features introduced with Istio 1.1, please refer to the [1.1 change notes](/news/releases/1.1.x/announcing-1.1/change-notes/).

## Installation

- We have increased the control plane and envoy sidecar’s required CPU and memory.  It is critical to ensure your cluster have enough resource before proceeding
the update.

- Istio’s CRDs have been placed into their own Helm chart `istio-init`.  This prevents loss of custom resource data, facilitates the upgrade process, and enables
Istio to evolve beyond a Helm-based installation.  The [upgrade documentation](/docs/setup/upgrade/) provides the proper procedures for upgrading
from Istio 1.0.6 to Istio 1.1.  Please follow these instructions carefully when upgrading.  If `certmanager` is desired, use the `--set certmanager=true` flag
when installing both `istio-init` and Istio charts with either `template` or `tiller` installation modes.

- Many installation options have been added, removed, or changed. Refer to [Installation Options Changes](/news/releases/1.1.x/announcing-1.1/helm-changes/) for a detailed
summary of the changes.

- The 1.0 `istio-remote` chart used for [multicluster VPN](https://archive.istio.io/v1.1/docs/setup/kubernetes/install/multicluster/vpn/) and
[multicluster split horizon](https://archive.istio.io/v1.1/docs/examples/multicluster/split-horizon-eds/) remote cluster
installation has been consolidated into the Istio chart. To generate an equivalent `istio-remote` chart, use the `--set global.istioRemote=true` flag.

- Addons are no longer exposed via separate load balancers.  Instead addons can now be optionally exposed via the Ingress Gateway.  To expose an addon via the
Ingress Gateway, please follow the [Remotely Accessing Telemetry Addons](/docs/tasks/observability/gateways/) guide.

- The built-in Istio Statsd collector has been removed. Istio retains the capability of integrating with your own Statsd collector, using the
`--set global.envoyStatsd.enabled=true` flag.

- The `ingress` series of options for configuring a Kubernetes Ingress have been removed.  Kubernetes Ingress is still functional and can be enabled using the
`--set global.k8sIngress.enabled=true` flag.  Check out [Securing Kubernetes Ingress with Cert-Manager](/docs/ops/integrations/certmanager/)
to learn how to secure your Kubernetes ingress resources.

## Traffic management

- Outbound traffic policy now defaults to `ALLOW_ANY`.  Traffic to unknown ports will be forwarded as-is. Traffic to known ports (e.g., port 80) will be matched
with one of the services in the system and forwarded accordingly.

- During sidecar routing to a service, destination rules for the target service in the same namespace as the sidecar will take precedence, followed by destination
rules in the service’s namespace, and finally followed by destination rules in other namespaces if applicable.

- We recommend storing gateway resources in the same namespace as the gateway workload (e.g., `istio-system` in case of `istio-ingressgateway`).  When referring
to gateway resources in virtual services, use the namespace/name format instead of using `name.namespace.svc.cluster.local`.

- The optional egress gateway is now disabled by default.  It is enabled in the demo profile for users to explore but disabled in all other profiles by default.
If you need to control and secure your outbound traffic through the egress gateway, you will need to enable `gateways.istio-egressgateway.enabled=true` manually
in any of the non-demo profiles.

## Policy & telemetry

- `istio-policy` check is now disabled by default.  It is enabled in the demo profile for users to explore but disabled in all other profiles.  This change is
only for `istio-policy` and not for `istio-telemetry`.  In order to re-enable policy checking, run `helm template` with `--set global.disablePolicyChecks=false`
and re-apply the configuration.

- The Service Graph component has now been deprecated in favor of [Kiali](https://www.kiali.io/).

## Security

- RBAC configuration has been modified to implement cluster scoping.  The `RbacConfig` resource has been replaced with the `ClusterRbacConfig` resource. Refer
to [Migrating `RbacConfig` to `ClusterRbacConfig`](https://archive.istio.io/v1.1/docs/setup/kubernetes/upgrade/steps/#migrating-from-rbacconfig-to-clusterrbacconfig) for migration instructions.
