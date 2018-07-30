---
title: Observing Traffic Management
description: Describes tools and techniques to observe traffic management or issues related to traffic management 
weight: 5
---

* Provide operational statistics that can be used to observe the traffic management

* Provide pointers to tools that should be used to ensure the networking aspects are not getting stressed or over-loaded

## Envoy is crashing under load

Check your `ulimit -a`. Many systems have a 1024 open file descriptor limit by default which will cause Envoy to assert and crash with:

{{< text plain >}}
[2017-05-17 03:00:52.735][14236][critical][assert] assert failure: fd_ != -1: external/envoy/source/common/network/connection_impl.cc:58
{{< /text >}}

Make sure to raise your ulimit. Example: `ulimit -n 16384`

## Why is creating a weighted route rule to split traffic between two versions of a service not working as expected?

For the current Envoy sidecar implementation, up to 100 requests may be required for the desired distribution to be observed.

## How come some of my route rules don't take effect immediately?

The Istio implementation on Kubernetes utilizes an eventually consistent
algorithm to ensure all Envoy sidecars have the correct configuration
including all route rules.  A configuration change will take some time
to propagate to all the sidecars.  With large deployments the
propagation will take longer and there maybe a lag time on the
order of seconds.
