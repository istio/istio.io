---
title: Announcing Istio 1.13
linktitle: 1.13
subtitle: Major Update
description: Istio 1.13 release announcement.
publishdate: 2022-02-11
release: 1.13.0
skip_list: true
aliases:
    - /news/announcing-1.13
    - /news/announcing-1.13.0
---

We are pleased to announce the release of Istio 1.13!

{{< relnote >}}

This is the first Istio release of 2022. We would like to thank the entire Istio community for helping to get Istio 1.13.0 published.  Special thanks are due to the release managers Steven Landow (Google), Lei Tang (Google) and Elizabeth Avelar (SAP), and to Test & Release WG lead Eric Van Norman (IBM) for his help and guidance.

{{< tip >}}
Istio 1.13.0 is officially supported on Kubernetes versions `1.20` to `1.23`.
{{< /tip >}}

Here are some of the highlights of the release:

## Configure the Istio sidecar proxy with the `ProxyConfig` API

Previous versions of Istio allowed configuration of proxy-level Envoy options with the [mesh-wide settings API](/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig).
In 1.13, we have promoted this configuration to its open top-level custom resource, `ProxyConfig`. Like other Istio
configuration APIs, this CR can be configured globally, per-namespace, or per-workload.

In the initial release, you can configure concurrency and proxy image type through the `ProxyConfig` CR.  This will
expand in future releases.

For more information, check out the [`ProxyConfig` documentation](/docs/reference/config/networking/proxy-config/).

## Continued improvements to the Telemetry API

We continue to refine the new [Telemetry API](/docs/tasks/observability/telemetry/), introduced
in Istio 1.11. In 1.13, we added support for [logging with `OpenTelemetry`](https://opentelemetry.io/docs/reference/specification/logs/overview/), [filtering access logs](/docs/reference/config/telemetry/#AccessLogging-Filter),
and customizing the trace service name. There are also a large number of bug fixes and improvements.

## Support for hostname based load balancers for multi-network gateways

Up until now, Istio has relied on knowing the IP address for a load balancer used between two networks in an east-west
configuration. The Amazon EKS load balancer provides a hostname instead of an IP address, and users had to
[manually resolve this name and set the IP address](https://szabo.jp/2021/09/22/multicluster-istio-on-eks/) as a workaround.

In 1.13, Istio will now automatically resolve the hostname of a gateway, and Istio can now automatically discover the
gateway of a remote cluster on EKS.

## Feature updates

The [`WorkloadGroup`](/docs/reference/config/networking/workload-group/) API feature, first
introduced in Alpha in Istio 1.8, has been promoted to Beta in this release.

[Authorization policy dry-run mode](/docs/tasks/security/authorization/authz-dry-run/) has also
been promoted from Experimental to Alpha.

## Upgrading to 1.13

Please note that [Istio 1.13.1 will be released on February 22](https://discuss.istio.io/t/upcoming-istio-v1-11-7-v1-12-4-and-v1-13-1-security-releases/12264)
to address various security vulnerabilities.

When you upgrade, we would like to hear from you! Please take a few minutes to respond to a brief [survey](https://forms.gle/pzWZpAvMVBecaQ9h9) to let us know how we’re doing.

## Join us at IstioCon

[IstioCon 2022](https://events.istio.io/istiocon-2022/), set for April 25-29, will be the second annual conference for the Istio community. This year's conference
will again be 100% virtual, connecting community members across the globe with Istio's ecosystem of developers, partners
and vendors. Visit the [conference website](https://events.istio.io/istiocon-2022/) for all the information related to the event.

You can also join the conversation at [Discuss Istio](https://discuss.istio.io/), or join our [Slack workspace](https://slack.istio.io/).
Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
