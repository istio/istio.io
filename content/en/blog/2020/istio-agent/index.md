---
title: Remove cross-pod unix domain sockets
description: A more secure way to manage secrets.
publishdate: 2020-02-20
attribution: Lei Tang (Google)
keywords: [security, secret discovery service, unix domain socket]
target_release: 1.5
---

In Istio versions before 1.5, during secret discovery service (SDS),
the SDS client and the SDS server communicate through a cross-pod Unix domain
socket (UDS), which needs to be protected by Kubernetes pod security policies.

With Istio 1.5, Pilot Agent, Envoy, and Citadel Agent will be running in
the same container (the architecture is in the following diagram).
To defend attackers eavesdropping on the cross-pod UDS between Envoy (SDS client)
and Citadel Agent (SDS server), Istio 1.5 merges Pilot Agent and Citadel Agent
as Istio Agent and makes the UDS between Envoy and Citadel Agent
be private to the Istio Agent container.
Istio Agent container is deployed as the sidecar for the backend container.

{{< image width="70%"
    link="./istio_agent.svg"
    caption="The architecture of Istio Agent"
    >}}
