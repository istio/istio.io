---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.9.0.
weight: 20
---

When you upgrade from Istio 1.8 to Istio 1.9.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.8.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.8.

## PeerAuthentication per-port-level configuration will now also apply to pass through filter chains.
Previously the PeerAuthentication per-port-level configuration is ignored if the port number is not defined in a
service and the traffic will be handled by a pass through filter chain. Now the per-port-level setting will be
supported even if the port number is not defined in a service, a special pass through filter chain will be added
to respect the corresponidng per-port-level mTLS specification.
Pleae check your PeerAuthentication to make sure you are not using the per-port-level configuration on pass through
filter chains, it was not a supported feature and you should update your PeerAuthentication accordingly if you are
currently relying on the unsupported behavior before the upgrade.
You don't need to do anything if you are not using per-port-level PeerAuthentication on pass through filter chains.

## `AUTO_PASSTHROUGH` Gateway mode
Previously, gateways were configured with multiple Envoy `cluster` configurations for each Service in the cluster, even those
not referenced by any Gateway or VirtualService. This was added to support the `AUTO_PASSTHROUGH` mode on Gateway, generally used for exposing Services across networks.

However, this came at an increased CPU and memory cost in the gateway and Istiod. As a result, we have disabled these by default
on the `istio-ingressgateway` and `istio-egressgateway`.

If you are relying on this feature for multi-network support, please ensure you apply one of the following changes:

1. Follow our new [Multicluster Installation](/docs/setup/install/multicluster/) documentation.

   This documentation will guide you through running a dedicate gateway deployment for this type of traffic (generally referred to as the `eastwest-gateway`).
   This `eastwest-gateway` will automatically be configured to support `AUTO_PASSTHROUGH`.

1. Modify your installation of the gateway deployment to include this configuration. This is controlled by the `ISTIO_META_ROUTER_MODE` environment variable. Setting this to `sni-dnat` enables these clusters, while `standard` (the new default) disables them.

    {{< text yaml >}}
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        env:
          - name: ISTIO_META_ROUTER_MODE
            value: "sni-dnat"
    {{< /text >}}

## Service Tags added to trace spans
Istio now configures Envoy to include tags identifying the canonical service for a workload in generated trace spans.

This will lead to a small increase in storage per span for tracing backends.

To disable these additional tags, modify the 'istiod' deployment to set an environment variable of `PILOT_ENABLE_ISTIO_TAGS=false`.
