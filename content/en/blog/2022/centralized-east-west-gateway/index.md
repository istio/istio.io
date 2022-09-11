---
title: "Introducing centralized east-west traffic gateway"
description: "A light-weighted way to achieve layer 7 load balancing functions without per-pod sidecars."
publishdate: 2022-09-11T07:00:00-06:00
attribution: "Shaokai Zhang (Alibaba Cloud), Chengyun Lu(Alibaba Cloud), Yang Song(Alibaba Cloud)"
keywords: [centralized sidecars]
---

## Background & introduction

The east-west traffic in Istio is carried by envoy sidecars, which are deployed in every pod
together with the application containers. Sidecars provide the functions of secure
service-to-service communication, load balancing for various protocols, flexible traffic control
and policy, and complete tracing. 

However, there are also a few disadvantages of sidecars. First of all, deploying one sidecar to
every pod can be resource-consuming and introduce complexity, especially when the number of pods is
huge. Not only must those resources be provisioned to the sidecars, but also the control plane to
manage the sidecar and to push configurations can be demanding. Second, a query needs to go through
two sidecars, one in the source pod and the other one in the destination pod,  in order to reach
the destination. For delay-sensitive applications, sometimes, the extra time spent in the sidecars
is not acceptable. 

We noted that, for the majority of our HTTP applications, many of the rich features in sidecars are
unused. That's why we want to propose a light-weighted way to serve east-west traffic without the
drawbacks mentioned in the previous paragraph. Our focus is on the HTTP applications that do not
require advanced security features, like mTLS. 

We propose the centralized east-west traffic gateway, which moves the sidecars and the
functionalities they carry to nodes that are dedicated for sidecars, and no application container
shares those nodes. This way, no modifications are required on the nodes, and we can save on the
resources and the delay. In addition, we can decouple the network management from application
management,  and also avoid the resource competition between application and networking. However,
because we move the sidecars out of the nodes of applications, we at the same time lose some of the
security and tracing abilities provided by the original sidecars. Our observation is that the
majority of our applications do not require those features.

## Istio and sidecars

Since its inception, a defining feature of Istio’s architecture has been the use of _sidecars_
– programmable proxies deployed alongside application containers.  Sidecars allow operators to
reap Istio’s benefits, without requiring applications to undergo major surgery and its
associated costs.

{{< image width="100%"
    link="traditional-istio.png"
    caption="Istio’s traditional model deploys Envoy proxies as sidecars within the
workloads’ pods"
    >}}

Although sidecars have significant advantages over refactoring applications, they do not provide a
perfect separation between applications and the Istio data plane. This results in a few
limitations:

* **Invasiveness** - Sidecars must be "injected" into applications by modifying their Kubernetes
* pod spec and redirecting traffic within the pod.   As a result, installing or upgrading sidecars
* requires restarting the application pod, which can be disruptive for workloads.
* **Underutilization of resources** - Since the sidecar proxy is dedicated to its associated
* workload, the CPU and memory resources must be provisioned for worst case usage of each
* individual pod. This adds up to large reservations that can lead to underutilization of resources
* across the cluster.
* **Traffic breaking** - Traffic capture and HTTP processing, as typically done by Istio’s
* sidecars, is computationally expensive and can break some applications with non-conformant HTTP
* implementations.
