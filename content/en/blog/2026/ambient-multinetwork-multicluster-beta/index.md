---
title: Ambient multi-network multicluster support is now Beta
description: Istio 1.29 arrives with ambient multi-network multicluster in Beta, with improvements in telemetry, connectivity and reliability.
date: 2026-02-18
attribution: Gustavo Meira (Microsoft), Mikhail Krinkin (Microsoft)
keywords: [ambient,multicluster]
---

Our team of contributors has been busy throughout the transition to 2026. A lot of work was done to get the multi-network multicluster for ambient to production ready state. Improvements were made in areas from our internal tests, up to the most popular multi-network multicluster asks in ambient, with a big focus on telemetry.

## Gaps in Telemetry

The benefits of a multicluster distributed system are not without their tradeoffs. Some complexity is inevitable with larger scale, making good telemetry even more important. The Istio team understands that point and we were aware of some gaps that needed to be covered. Thankfully, on release 1.29, telemetry is now more robust and complete when our ambient data plane operates over distributed clusters and networks.

If you've deployed alpha multicluster capabilities before in multi-network scenarios, you might have noticed some source or destination labels would show as "unknown".

For context, in a local cluster (or clusters sharing the same network), waypoint and ztunnel are aware of all existing endpoints, and they acquire that information through xDS. Confusing metrics instead often occur in multi-network deployments where, given all the information that needs to be replicated across separate networks, the xDS peer discovery is unpractical. Unfortunately, that results in missing peer information when requests traverse network boundaries to reach a different Istio cluster.

## Telemetry Enhancements

Overcoming that problem, Istio 1.29 now ships with augmented discovery mechanisms in its data plane for exchanging peer metadata between endpoints and gateways sitting across different networks. The HBONE protocol is now enriched with baggage headers, allowing for waypoint and ztunnel to exchange peer information transparently through east-west gateways.

{{< image link="./peer-metadata-exchange-diagram.png" caption="Diagram showing peer metadata exchange across different networks" >}}

In the diagram above, focusing on L7 metrics, we show how the peer metadata flows through baggage headers across different clusters sitting in different networks.

1. The client in Cluster A initiates a request, and ztunnel starts to establish an HBONE connection through the Waypoint. This means ztunnel sends a CONNECT request with a baggage header containing the peer metadata from downstream. That metadata is then stored in the waypoint.
1. The baggage header containing the metadata is removed, and the request is routed normally. In this case it goes to a different cluster.
1. On the receiving side, the Ztunnel in Cluster B receives the HBONE request and replies with a successful status, appending a baggage header, now containing the upstream peer metadata.
1. The upstream peer metadata is invisible to the east-west gateway. And as the response reaches the waypoint, it will now have all the information it needs to emit metrics about the two parties involved.

Note that this functionality is behind a feature flag at the moment. If you want to try these telemetry enhancements, they need to be explicitly activated with the `AMBIENT_ENABLE_BAGGAGE` feature option.

## Other Improvements and Fixes

Some welcomed [improvements](/news/releases/1.29.x/announcing-1.29/change-notes/#traffic-management) were made regarding connectivity. Ingress gateways and waypoint proxies can now route requests directly to remote clusters. This sets the stage for easier resiliency and enables more flexible design patterns providing the benefits that Istio users expect in multicluster and multi-network deployments.

And of course, we've also added a couple of smaller fixes making multi-network multicluster more stable and robust. We've updated the multicluster documentation to reflect some of these changes, including the addition of a [guide](/docs/ambient/install/multicluster/observability) on how to set up Kiali for an ambient multi-network deployment.

## Limitations and Next Steps

All that said, we still acknowledge some gaps weren’t fully covered. Most of the work here was targeting multi-network support. Note that multicluster in single network deployments is still considered alpha stage.

Also, the east-west gateway may give preference to a specific endpoint during a certain time span. This may have some impact on how load from requests coming from a different network is distributed between endpoints. And this is a behavior that impacts both ambient and sidecar data plane modes, and we have plans to address it for both cases.

We’re working with the fantastic Istio community to get these limitations addressed. For now, we’re excited to get this beta out there, and eager to get your feedback. The future is looking bright for Istio multi-network multicluster.

If you would like to try out ambient multi-network multicluster, please follow [this guide](/docs/ambient/install/multicluster/multi-primary_multi-network/). Remember, this feature is in beta status and not ready for production use. We welcome your bug reports, thoughts, comments, and use cases. You can reach us on [GitHub](https://github.com/istio/istio) or [Slack](https://istio.slack.com/).
