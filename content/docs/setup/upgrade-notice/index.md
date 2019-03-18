---
title: 1.1 Upgrade Notice
description: Important changes operators must understand before upgrading to Istio 1.1.
weight: 5

---

This page describes changes you need to be aware of when upgrading from Istio 1.0 to 1.1.  Here we detail cases where we intentionally broke backwards compatibility.  We also mention cases where backwards compatibility was preserved but new behavior was introduced that would be surprising to someone familiar with the use and operation of Istio 1.0.

For an overview of new features introduced with Istio 1.1, please refer to the [1.1 release notes](/about/notes/1.1/).

## Installation

- Istio’s CRDs have been placed into their own Helm chart `istio-init`.  This prevents loss of custom resource data, facilitates the upgrade process, and enables Istio to evolve beyond a Helm-based installation.  The [upgrade documentation](/docs/setup/kubernetes/upgrade/) provides the proper procedures for upgrading from Istio 1.0.6 to Istio 1.1.  Please follow these instructions carefully when upgrading.  If `certmanager` is desired, use the `--set certmanager=true` flag when installing both `istio-init` and Istio charts with either `template` or `tiller` installation modes.
- The 1.0 `istio-remote` chart used for [multicluster VPN](/docs/setup/kubernetes/install/multicluster/vpn/) and [multicluster split horizon](/docs/examples/multicluster/split-horizon-eds/) remote cluster installation has been consolidated into the Istio chart.  To generate an equivalent `istio-remote` chart, use the `--set global.istioRemote=true` flag.
- Addons are no longer exposed via separate load balancers.  Instead addons are now exposed via the Ingress Gateway.  To expose an addon via the Ingress Gateway, please follow the [Remotely Accessing Telemetry Addons](/docs/tasks/telemetry/gateways/) guide.
- The built-in Istio Statsd collector has been removed. Istio retains the capability of integrating with your own Statsd collector.
- Grafana, Prometheus, Kiali, and Jaeger passwords and usernames are now stored in [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/) instead of command line configuration options, `values.yaml`, or configmaps for improved security and compliance.
- Jaeger has replaced Zipkin as the default tracing system.
- The `ingress` series of options for configuring a Kubernetes Ingress have been removed.  Kubernetes Ingress is still functional and can be installed by following the [Securing Kubernetes Ingress with Cert-Manager](/docs/examples/advanced-gateways/ingress-certmgr/) guide.

## Traffic Management

- Outbound traffic policy now defaults to `ALLOW_ANY`.  Traffic to unknown ports will be forwarded as-is. Traffic to known ports (e.g., port 80) will be matched with one of the services in the system and forwarded accordingly.
- During sidecar routing to a service, destination rules for the target service in the same namespace as the sidecar will take precedence, followed by destination rules in the service’s namespace, and finally followed by destination rules in other namespaces if applicable.
- We recommend storing gateway resources in the same namespace as the gateway workload (e.g., `istio-system` in case of `istio-ingressgateway`).  When referring to gateway resources in virtual services, use the namespace/name format instead of using `name.namespace.svc.cluster.local`.
- The optional egress gateway is now disabled by default.  It is enabled in the demo profile for users to explore but disabled in all other profiles by default.  If you need to control and secure your outbound traffic through the egress gateway, you will need to enable `gateways.istio-egressgateway.enabled=true` manually in any of the non-demo profiles.

## Policy & Telemetry

- `istio-policy` is now disabled by default.  It is enabled in the demo profile for users to explore but disabled in all other profiles.  This change is only for `istio-policy` and not for `istio-telemetry`.  In order to re-enable policy checking, run `helm template` with `--set global.disablePolicyChecks=false` and re-apply the configuration.
- The Service Graph component has now been deprecated in favor of [Kiali](https://www.kiali.io/).

## Security

- RBAC configuration has been modified to implement cluster scoping.  The `RbacConfig` resource has been replaced with the `ClusterRbacConfig` resource. Refer to [Migrating `RbacConfig` to `ClusterRbacConfig`](/docs/setup/kubernetes/upgrade/#migrating-from-rbacconfig-to-clusterrbacconfig) for migration instructions.
