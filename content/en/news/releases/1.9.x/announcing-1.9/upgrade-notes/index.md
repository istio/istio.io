---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.9.0.
weight: 20
---

When you upgrade from Istio 1.8 to Istio 1.9.x, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.8.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.8.

## PeerAuthentication per-port-level configuration will now also apply to pass through filter chains.
Previously the PeerAuthentication per-port-level configuration is ignored if the port number is not defined in a
service and the traffic will be handled by a pass through filter chain. Now the per-port-level setting will be
supported even if the port number is not defined in a service, a special pass through filter chain will be added
to respect the corresponidng per-port-level mTLS specification.
Please check your PeerAuthentication to make sure you are not using the per-port-level configuration on pass through
filter chains, it was not a supported feature and you should update your PeerAuthentication accordingly if you are
currently relying on the unsupported behavior before the upgrade.
You don't need to do anything if you are not using per-port-level PeerAuthentication on pass through filter chains.

## Service Tags added to trace spans
Istio now configures Envoy to include tags identifying the canonical service for a workload in generated trace spans.

This will lead to a small increase in storage per span for tracing backends.

To disable these additional tags, modify the 'istiod' deployment to set an environment variable of `PILOT_ENABLE_ISTIO_TAGS=false`.
