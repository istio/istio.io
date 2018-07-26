---
title: Authorization Too Permissive
description: Authorization is enabled, but requests make it through anyway.
weight: 50
---
If authorization checks are enabled for a service and yet requests to the service aren't being blocked, then
its likely that authorization was not actually enabled successfully. You can do the following to verify:

1. Check [this page](/docs/concepts/security/#authorization) to find out how to correctly enable
Istio authorization policy.

1. Avoid enabling authorization for Istio Control Planes Components, including Mixer, Pilot, Ingress.
Istio authorization policy is designed for authorizing access to services in Istio Mesh. Enabling it
for Istio Control Planes Components may cause unexpected behavior.

1. In Kubernetes environment, check deployments in all namespaces to make sure there is no legacy
deployment left that could cause error in Pilot. Authorization plugin in Pilot could be disabled if
there is error pushing authorization policy to Envoy.

1. Follow the [Debugging Authorization](/help/ops/security/debugging-authorization/) to find out the exact cause.
