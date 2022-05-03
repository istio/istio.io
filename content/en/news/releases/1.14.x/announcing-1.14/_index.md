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
Istio 1.14.0 is officially supported on Kubernetes versions `1.20` to `1.23`.
{{< /tip >}}

Here are some of the highlights of the release:

## Add a new approach for CA integration through the Envoy SDS API

This new feature adds a new approach for CA integration through the Envoy SDS API.
For more information, check out the [documentation](/docs/ops/integrations/spire/).

## Add the auto-sni support

Some servers require SNI be included in a request. This new feature configures SNI
automatically.

## Add the support of configuring the TLS version for Istio workloads

TLS version is important for security. This new feature adds
the support of configuring the minimum TLS version for Istio workloads. 

For more information, check out the [documentation](/docs/tasks/security/tls-configuration/workload-min-tls-version/).

## Upgrading to 1.14

When you upgrade, we would like to hear from you! Please take a few minutes to respond to a brief [survey](https://forms.gle/pzWZpAvMVBecaQ9h9) to let us know how we’re doing.

You can also join the conversation at [Discuss Istio](https://discuss.istio.io/), or join our [Slack workspace](https://slack.istio.io/).
Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
