---
title: Announcing Istio 1.3
subtitle: Major Update
description: Istio 1.3 release announcement.
publishdate: 2019-09-10
attribution: The Istio Team
release: 1.3.0
---

We are pleased to announce the release of Istio 1.3!

{{< relnote linktonote="true" >}}

The theme of Istio 1.3 is User Experience:

- Improve the experience of new users adopting Istio
- Improve the experience of users debugging problems
- Support more applications without any additional configuration

Every few releases, the Istio team gets excited as we make dramatic improvements to usability, APIs, and the overall system performance. This release is one of those where the team is excited to roll out some key updates.

## Intelligent protocol detection

In past releases, you had to explicitly declare the protocol for service ports by using a special port naming format. This requirement caused problems for users that did not name their ports when they added their applications to the mesh. Starting with 1.3, the protocol on the wire will be automatically detected (as HTTP or TCP), eliminating the need to name ports explicitly. We will be adding support for additional [non-HTTP] protocols in future releases.

## Mixer-less telemetry (experimental)

Yes you read that right! We had already turned off the `istio-policy` service by default as we implemented most of the common security policies such as RBAC directly in Envoy. We are now on track to migrate most of the mixer's telemetry functionality as well into Envoy. As of this release, if all you care about is telemetry for HTTP services, we have enhanced the Istio proxy to emit HTTP metrics directly to Prometheus, without requiring the `istio-telemetry` service to enrich the information. You can experiment with the mixer-less telemetry feature for HTTP services by following these [instructions](https://github.com/istio/istio/wiki/Mixerless-HTTP-Telemetry). We will be polishing this feature in the coming months including adding telemetry support for TCP services when Istio mutual TLS is being used.

## Container ports are no longer required

In the past, Istio required that pods explicitly declare the Kubernetes `containerPort` for each container as a security measure against trampolining traffic. Istio 1.3 has a secure and simpler way of handling all inbound traffic on any port into a Pod without requiring the `containerPort` declarations. We have also completely eliminated infinite loops caused in the IPtables rules when pods send traffic to themselves.

## Customize generated Envoy configuration

While Istio 1.3 focuses on out of box usability, it also caters to the expert users who would like to use advanced features in Envoy that Istio does not expose via its Networking APIs. We have enhanced the `EnvoyFilter` API to allow users to fully customize the Envoy HTTP route configuration returned by RDS, HTTP/TCP listeners and their filter chains returned by LDS, and the set of clusters returned by CDS. You get the best of both worlds - leverage  Istio to integrate with Kubernetes, handle large fleets of Envoys in an efficient manner and still retain the ability to customize the generated Envoy configuration to meet specific requirements within your infrastructure.

## Other enhancements

- `istioctl` has gained a plethora of debugging features that will highlight various issues in your mesh installation. Checkout the `istioctl` [reference manual](/docs/reference/commands/istioctl/) for the set of all supported features.

- Locality aware load balancing graduated from experimental to default in this release too. Istio can now take advantage of existing locality information to prioritize load balancing pools and favor sending requests to the closest backends.

- Better support for headless services with Istio mutual TLS

- We enhanced control plane monitoring in the following ways:

    - Added new metrics to monitor configuration state
    - Added metrics for sidecar injector
    - Added a new Grafana dashboard for Citadel
    - Improved the Pilot dashboard to expose additional key metrics

- Added the new [Istio Deployment Models concept](/docs/concepts/deployment-models/) to help you decide what deployment model suits your needs.

- Organized the content in of our [Operations Guide](/docs/ops/) and created a [section with all troubleshooting tasks](/docs/ops/troubleshooting) to help you find the information you seek faster.

See the [release notes](/about/notes/1.3) for the complete list of changes.

As always, there is a lot happening in the [Community Meeting](https://github.com/istio/community#community-meeting); join us every other Thursday at 11 AM Pacific.

Join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us make Istio better.

To join the conversation, go to [discuss.istio.io](https://discuss.istio.io), log in with your GitHub credentials and join us!
