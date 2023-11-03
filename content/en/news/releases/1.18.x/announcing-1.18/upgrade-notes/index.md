---
title: Istio 1.18 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.18.0.
weight: 20
publishdate: 2023-06-07
---

When you upgrade from Istio 1.17.x to Istio 1.18.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio `1.17.x.`
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio `1.17.x.`

## Proxy Concurrency changes

Previously, the proxy `concurrency` setting, which configures how many worker threads the proxy runs,
was inconsistently configured between sidecars and different gateway installation mechanisms.
This often led to gateways running with concurrency based on the number of physical cores on the host machine,
despite having CPU limits, leading to decreased performance and increased resource usage.

In this release, concurrency configuration has been tweaked to be consistent across deployment types.
The new logic will use the `ProxyConfig.Concurrency` setting (which can be configured mesh wide or per-pod), if set, and otherwise set concurrency based on the CPU limit allocated to the container.  For example, a limit of `2500m` would set concurrency to 3.

Prior to this release, sidecars followed this logic, but sometimes incorrectly determined the CPU limit.
Gateways would never automatically adapt based on concurrency settings.

To retain the old gateway behavior of always utilizing all cores, `proxy.istio.io/config: concurrency: 0` can be set on each gateway.  However, it is recommended to instead unset CPU limits if this is desired.

## Gateway API Automated Deployment changes

This change impacts you only if you use [Gateway API Automated Deployment](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment).
Note that this only applies to the Kubernetes Gateway API, not the Istio `Gateway`.
You can check if you are using this feature with the following command:

{{< text bash >}}
$ kubectl get gateways.gateway.networking.k8s.io -ojson | jq -r '.items[] | select(.spec.gatewayClassName == "istio") | select((.spec.addresses | length) == 0) | "Found managed gateway: " + .metadata.namespace + "/" + .metadata.name'
Found managed gateway: default/gateway
{{< /text >}}

If you see "Found managed gateway", you may be impacted by this change.

Prior to Istio 1.18, the managed gateway worked by creating a minimal Deployment configuration which
was fully populated at runtime with Pod injection. To upgrade gateways, users would restart the Pods
to trigger a re-injection.

In Istio 1.18, this has changed to create a fully rendered Deployment and no longer rely on injection.
As a result, *Gateways will be updated, via a rolling restart, when their revision changes*.

Additionally, users using this feature must update their control plane to Istio 1.16.5+ or 1.17.3+ before adopting Istio 1.18.
Failure to do so may lead to conflicting writes to the same resources.
