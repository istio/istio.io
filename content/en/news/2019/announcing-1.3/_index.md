---
title: Announcing Istio 1.3
subtitle: Major Update
description: Istio 1.3 release announcement.
publishdate: 2019-09-12
attribution: The Istio Team
release: 1.3.0
aliases:
    - /blog/2019/announcing-1.3
    - /news/announcing-1.3
skip_list: true
---

We are pleased to announce the release of Istio 1.3!

{{< relnote >}}

The theme of Istio 1.3 is User Experience:

- Improve the experience of new users adopting Istio
- Improve the experience of users debugging problems
- Support more applications without any additional configuration

Every few releases, the Istio team delivers dramatic improvements to usability, APIs, and the overall system performance. Istio 1.3 is one such release, and the team is very excited to roll out some key updates.

## Intelligent protocol detection (experimental)

To take advantage of Istio's routing features, service ports must use a special port naming format to explicitly declare the protocol. This requirement can cause problems for users that do not name their ports when they add their applications to the mesh. Starting with 1.3, the protocol for outbound traffic is automatically detected as HTTP or TCP when the ports are not named according to Istio's conventions. We will be polishing this feature in the upcoming releases with support for protocol sniffing on inbound traffic as well as identifying protocols other than HTTP.

## Mixer-less telemetry (experimental)

Yes, you read that right! We implemented most of the common security policies, such as RBAC, directly into Envoy. We previously turned off the `istio-policy` service by default and are now on track to migrate most of Mixer's telemetry functionality into Envoy as well. In this release, we have enhanced the Istio proxy to emit HTTP metrics directly to Prometheus, without requiring the `istio-telemetry` service to enrich the information. This enhancement is great if all you care about is telemetry for HTTP services. Follow the [Mixer-less HTTP telemetry instructions](https://github.com/istio/istio/wiki/Mixerless-HTTP-Telemetry) to experiment with this feature. We are polishing this feature in the coming months to add telemetry support for TCP services when you enable Istio mutual TLS.

## Container ports are no longer required

Previous releases required that pods explicitly declare the Kubernetes `containerPort` for each container as a security measure against trampolining traffic. Istio 1.3 has a secure and simpler way of handling all inbound traffic on any port into a {{< gloss >}}workload instance{{< /gloss >}} without requiring the `containerPort` declarations. We have also completely eliminated the infinite loops caused in the IP tables rules when workload instances send traffic to themselves.

## Fully customize generated Envoy configuration

While Istio 1.3 focuses on usability, expert users can use advanced features in Envoy that are not part of the Istio Networking APIs. We enhanced the `EnvoyFilter` API to allow users to fully customize:

- The HTTP/TCP listeners and their filter chains returned by LDS
- The Envoy HTTP route configuration returned by the RDS
- The set of clusters returned by CDS

You get the best of both worlds:

Leverage Istio to integrate with Kubernetes and handle large fleets of Envoys in an efficient manner, while you still can customize the generated Envoy configuration to meet specific requirements within your infrastructure.

## Other enhancements

- `istioctl` gained many debugging features to help you highlight various issues in your mesh installation. Checkout the `istioctl` [reference page](/docs/reference/commands/istioctl/) for the set of all supported features.

- Locality aware load balancing graduated from experimental to default in this release too. Istio now takes advantage of existing locality information to prioritize load balancing pools and favor sending requests to the closest backends.

- Better support for headless services with Istio mutual TLS

- We enhanced control plane monitoring in the following ways:

    - Added new metrics to monitor configuration state
    - Added metrics for sidecar injector
    - Added a new Grafana dashboard for Citadel
    - Improved the Pilot dashboard to expose additional key metrics

- Added the new [Istio Deployment Models concept](/docs/concepts/deployment-models/) to help you decide what deployment model suits your needs.

- Organized the content in of our [Operations Guide](/docs/ops/) and created a [section with all troubleshooting tasks](/docs/ops/common-problems) to help you find the information you seek faster.

As always, there is a lot happening in the [Community Meeting](https://github.com/istio/community#community-meeting); join us every other Thursday at 11 AM Pacific.

The growth and success of Istio is due to its 400+ contributors from over 300 companies. Join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us make Istio even better.

To join the conversation, go to [discuss.istio.io](https://discuss.istio.io), log in with your GitHub credentials and join us!
