---
title: Authorization Too Permissive
description: Authorization is enabled, but requests make it through anyway.
weight: 50
---
If authorization checks are enabled for a service and yet requests to the service aren't being blocked, then
authorization was likely not enabled successfully. To verify, follow these steps:

1. Check the [enable authorization docs](/docs/concepts/security/#enabling-authorization) to correctly enable
Istio authorization.

1. Avoid enabling authorization for Istio Control Planes Components, including Mixer, Pilot and Ingress.
The Istio authorization features are designed for authorizing access to services in an Istio Mesh.
Enabling the authorization features for the Istio Control Planes components can cause unexpected behavior.

1. In your Kubernetes environment, check deployments in all namespaces to make sure there is no legacy
deployment left that can cause an error in Pilot. You can disable Pilot's authorization plug-in if
there is an error pushing authorization policy to Envoy.

1. Follow the [Debugging Authorization docs](/help/ops/security/debugging-authorization/) to find out the exact cause.
