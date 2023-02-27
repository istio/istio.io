---
title: Istio 1.16 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.16.0.
publishdate: 2022-11-15
weight: 20
---

When you upgrade from Istio 1.15.x to Istio 1.16.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.15.0.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio `1.15.x`.
Users upgrading from 1.14.x to Istio 1.16.0 should also reference the [1.15 change logs](/news/releases/1.15.x/announcing-1.15/change-notes/).

## Gateway API Resources

The Gateway API integration has been upgraded to read `v1beta1` resources for `HTTPRoute`, `Gateway`, and `GatewayClass`. If using the new Gateway API feature for traffic management, which is currently beta, this change requires the gateway-api to be version 0.5.0 or higher. For more information, see the Kubernetes Gateway API [Getting Started Guide](/docs/setup/additional-setup/getting-started).
