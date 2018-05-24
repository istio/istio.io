---
title: Why is creating a weighted route rule to split traffic between two versions of a service not working as expected?
weight: 20
---
{% include home.html %}

For the current Envoy sidecar implementation, up to 100 requests may be required for the desired
distribution to be observed.
