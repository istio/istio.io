---
title: Ambient multi-network multicluster support is now in beta stage
description: Istio 1.29 arrives with ambient multi-network multicluster in beta status, with improvements in telemetry, connectivity and reliability.
date: 2025-02-16
attribution: Gustavo Meira (Microsoft), Mikhail Krinkin (Microsoft)
keywords: [ambient,multicluster]
---

Our team of contributors has been busy throughout the transition to 2026. A lot of work was done to push the multi-network multicluster support for ambient into a beta release. Improvements were made in areas from our internal tests, up to the most popular multi-network multicluster asks in ambient, with a big focus on telemetry.  

## Gaps in Telemetry

For sure all the benefits from a multicluster system distributed across different networks don't come for free. With that, some complexity ends up in the mix, which makes good telemetry even more important. The Istio team understands that point and we were aware of some gaps that needed to be covered. Thankfully, on release 1.29, telemetry is now more robust and complete when our ambient data-plane operates over distributed clusters.

If you've deployed alpha multicluster capabilities before in multi-network scenarios, you might have had a few strange encounters with metrics that didn't make much sense. Requests crossing cluster boundaries could show up in a very confusing way. For example, some sources or destinations would show as "unknown".

For context, in a local cluster (or clusters sharing the same network), Waypoint and Ztunnel are aware of all existing endpoints, and they acquire that information through XDS. Confusing metrics instead often occur in multi-network deployments where, given all the information that needs to be replicated across separate networks, the XDS peer discovery is unpractical. Unfortunately, that results in missing peer information when requests traverse network boundaries to reach a different Istio cluster.

## Telemetry Enhancements

Overcoming that problem, Istio 1.29 now ships with augmented discovery mechanisms in its data-plane for exchanging peer metadata between endpoints and gateways sitting across different networks. The HBONE protocol is now enriched with baggage headers, allowing for Waypoints and Ztunnels to exchange peer information transparently through E/W gateways.

{{< image link="./peer-metadata-exchange-diagram.png" caption="Diagram showing peer metadata exchange across different networks" >}}

In the diagram above, focusing on L7 metrics, we show how the peer metadata flows through baggage headers across different clusters sitting in different networks.

1. The client in Cluster A initiates a request, and Ztunnel starts to establish an HBONE connection through the Waypoint. This means Ztunnel sends a CONNECT request with a baggage header containing the peer metadata from downstream. That metadata is then stored in the Waypoint.
2. The baggage header containing the metadata is removed, and the request is routed normally. In this case it goes to a different cluster.
3. On the receiving side, the Ztunnel in Cluster B receives the HBONE request and replies with a successful status, appending a baggage header, now containing the upstream peer metadata.
4. The upstream peer metadata is invisible to the East/West Gateway. And as the response reaches the Waypoint, it will now have all the information it needs to emit metrics about the two parties involved.

Note that this functionality is behind a feature flag at the moment. If you want to try these telemetry enhancements, they need to be explicitly activated with the `AMBIENT_ENABLE_BAGGAGE` feature option.

## Other Improvements and Fixes

Ingress gateways now can route requests directly to remote clusters when no healthy endpoints are available locally. This sets the stage for easier resiliency, which we know is what lots of Istio users expect from their multicluster and multi-network designs.

We also made improvements soaking the EDS content according to service scopes. This means that when clusters sit in different networks, remote endpoints that don’t belong to local clusters won’t be transmitted to local gateways and Ztunnel instances.

And of course, we've also added a couple of smaller fixes making multi-network multicluster more stable and robust. We've updated the multicluster documentation to reflect some of these changes, including the addition of a [guide](/docs/ambient/install/multicluster/observability) on how to setup Kiali for an ambient multi-network deployment. 

## Limitation and Next Steps

All that said, we still acknowledge some gaps weren’t fully covered.

* Multicluster in single network deployments are still considered alpha stage.
* In multi-network multicluster, the E/W gateway may give preference to a specific endpoint during a certain timespan. This may have some impact on how load from requests coming from a different network is distributed between endpoints.
* In multi-network multicluster, services marked as cluster-local may answer to traffic from a remote cluster if they’re behind a global endpoint.

We’re working with the fantastic Istio community to get those addressed.

For now, we’re excited to get this beta out there, and eager to get your feedback. The future is looking bright for Istio multi-network multicluster.

If you would like to try out ambient multinetwork multicluster, please follow [this guide](/docs/ambient/install/multicluster/multi-primary_multi-network/). Remember, this feature is in beta status and not ready for production use. We welcome your bug reports, thoughts, comments, and use cases. You can reach us on [GitHub](https://github.com/istio/istio) or [Slack](https://istio.slack.com/).
