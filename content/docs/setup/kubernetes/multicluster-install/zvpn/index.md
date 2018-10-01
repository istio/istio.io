---
title: With Istio Gateway
description: Connect multiple clusters using Istio Gateway to reach remote pods
weight: 2
keywords: [kubernetes,multicluster]
---

Instructions for spanning an Istio mesh across multiple clusters when pods
in each cluster can only talk to remote gateway IPs.

## Prerequisites

* Two or more Kubernetes clusters with **1.9 or newer**.

* The ability to deploy the [Istio control plane](/docs/setup/kubernetes/quick-start/)
on **each** Kubernetes cluster.

*   The gateway IP (load balancer IP) in each cluster must be accessible
from every other cluster.

* Helm **2.7.2 or newer**.  The use of Tiller is optional.

## Overview

In this mode, each cluster has an **identical** Istio control plane
installation. 

{{< image width="80%" ratio="36.01%"
    link="./multicluster-zvpn.svg"
    caption="Spanning a single mesh across multiple clusters using a Gateways"
    >}}

...to be continued...
