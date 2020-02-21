---
title: Remove cross-pod unix domain sockets
description: A more secure way to manage secrets.
publishdate: 2020-02-20
attribution: Lei Tang (Google)
keywords: [security, secret discovery service, unix domain socket]
target_release: 1.5
---

In Istio versions before 1.5, during secret discovery service (SDS) execution,
the SDS client and the SDS server communicate through a cross-pod Unix domain
socket (UDS), which needs to be protected by Kubernetes pod security policies.

With Istio 1.5, Pilot Agent, Envoy, and Citadel Agent will be running in
the same container (the architecture is shown in the following diagram).
To defend against attackers eavesdropping on the cross-pod UDS between Envoy (SDS client)
and Citadel Agent (SDS server), Istio 1.5 merges Pilot Agent and Citadel Agent
into a single Istio Agent and makes the UDS between Envoy and Citadel Agent
private to the Istio Agent container.
The Istio Agent container is deployed as the sidecar of the application service container.

{{< image width="70%"
    link="./istio_agent.svg"
    caption="The architecture of Istio Agent"
    >}}
