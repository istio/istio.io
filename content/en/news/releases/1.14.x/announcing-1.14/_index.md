---
title: Announcing Istio 1.14
linktitle: 1.14
subtitle: Major Update
description: Istio 1.14 release announcement.
publishdate: 2022-05-11
release: 1.14.0
skip_list: true
aliases:
- /news/announcing-1.14
- /news/announcing-1.14.0
---

We are pleased to announce the release of Istio 1.14!

{{< relnote >}}

This is the second Istio release of 2022. We would like to thank the entire Istio community
for helping to get Istio 1.14.0 published.
Special thanks are due to the release managers Lei Tang (Google) and Greg Hanson (solo.io),
and to Test & Release WG lead Eric Van Norman (IBM) for his help and guidance.

{{< tip >}}
Istio 1.14.0 is officially supported on Kubernetes versions `1.21` to `1.24`.
{{< /tip >}}

Here are some of the highlights of the release:

## Support for the SPIRE runtime

SPIRE is a production-ready implementation of the SPIFFE specification, that offers
pluggable multi-factor attestation and SPIFFE federation. We've made changes in the way
we integrate with external Certificate Authorities, using the Envoy SDS API, to enable
support for SPIRE. Thanks to the team at HP Enterprise for contributing this work!

For more information, check out the [documentation](/docs/ops/integrations/spire/).

## Add auto-sni support

Some servers require SNI be included in a request. This new feature configures SNI automatically.
For more information, check out the [documentation](/docs/reference/config/networking/destination-rule/).

## Add support for configuring the TLS version for Istio workloads

TLS version is important for security. This new feature adds
the support of configuring the minimum TLS version for Istio workloads.
For more information, check out the [documentation](/docs/tasks/security/tls-configuration/workload-min-tls-version/).

## Telemetry improvements

The [Telemetry API](/docs/tasks/observability/telemetry/) has undergone a number of improvements,
including support for OpenTelemetry access logging, filtering based on WorkloadMode, and more.

## Upgrading to 1.14

When you upgrade, we would like to hear from you! Please take a few minutes to respond to a brief [survey](https://forms.gle/pzWZpAvMVBecaQ9h9) to let us know how we’re doing.

You can also join the conversation at [Discuss Istio](https://discuss.istio.io/), or join our [Slack workspace](https://slack.istio.io/).
Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.

## CNCF wrap up

We're so pleased at the response to our announcement that [Istio has been proposed to the CNCF](/blog/2022/istio-has-applied-to-join-the-cncf/).
We're hard at work at our application, and hope to have more to share in the coming months!