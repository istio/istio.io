---
title: Announcing Istio 1.16
linktitle: 1.16
subtitle: Major Update
description: Istio 1.16 release announcement.
publishdate: 2022-11-15
release: 1.16.0
skip_list: true
aliases:
- /news/announcing-1.16
- /news/announcing-1.16.0
---

We are pleased to announce the release of Istio 1.16!

{{< relnote >}}

This is the fourth Istio release of 2022. We would like to thank the entire Istio community
for helping to get Istio 1.16.0 published. Special thanks are due to the release managers Daniel Hawton from Solo.io, Ziyang Xiao from Intel, and Tong Li from IBM. As always, our gratitude goes to Test & Release WG lead Eric Van Norman (IBM) for his help and guidance.

{{< tip >}}
Istio 1.16.0 is officially supported on Kubernetes versions `1.22` to `1.25`.
{{< /tip >}}

## What's new

Here are some of the highlights of the release:

### External Authorization Promoted to Beta

Istio's External Authorization feature has been promoted to Beta. For more information, see the [External Authorization](/docs/tasks/security/authorization/authz-custom/) documentation.

### Kubernetes Gateway API Implementation Promoted to Beta

Istio's implementation of the [Gateway API](https://gateway-api.sigs.k8s.io/) has been promoted to Beta.
This is a significant step toward our goal of making the Gateway API the default API for traffic management [in the future](/blog/2022/gateway-api-beta/).

Along with the Beta promotion, we have enhanced all of our
[ingress tasks](/docs/tasks/traffic-management/ingress/) to include parallel instructions for
configuring ingress using either the Gateway API or the Istio configuration API.
Also, although using the Gateway API for more generally configuring internal mesh traffic is still an
[experimental feature](https://gateway-api.sigs.k8s.io/concepts/versioning/#release-channels-eg-experimental-standard)
of the Gateway API, pending [upstream agreement](https://gateway-api.sigs.k8s.io/contributing/gamma/),
several other Istio documents have been updated with Gateway API instructions to allow early experimentation.
Refer to the [Gateway API task](/docs/tasks/traffic-management/ingress/gateway-api/) for more information.

### JWT Claim Based Routing Promoted to Alpha

Istio's JWT Claim Based Routing feature has been promoted to Alpha. For more information, see the [JWT Claim Based Routing](/docs/tasks/security/authentication/jwt-route/) documentation.

### HBONE for Sidecars and Ingress (Experimental)

We have added support for the HBONE protocol for Sidecars and Ingress gateways. For more information, see the [pull request](https://github.com/istio/istio/pull/41391).

### MAGLEV Load Balancing Support

We have added support for the MAGLEV load balancing algorithm. For more information, see the [Envoy Documentation](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/load_balancers#maglev).

### Added OpenTelemetry Tracing Provider Support

We have added support for the OpenTelemetry tracing provider with the Telemetry API.

## Upgrading to 1.16

When you upgrade, we would like to hear from you! Please take a few minutes to respond to a brief [survey](https://forms.gle/99uiMML96AmsXY5d6) to let us know how we’re doing.

You can also join the conversation at [Discuss Istio](https://discuss.istio.io/), or join our [Slack workspace](https://slack.istio.io/).
Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
