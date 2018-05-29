---
title: Scalability and Sizing Guide
overview: Setup of Istio components to scale horizontally. High availability. Sizing guide.
weight: 60

layout: docs
type: markdown
---
{% include home.html %}

* Setup multiple replicas of the control plane components.

* Setup [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

* Split mixer check and report pods.

* High availability (HA).

* See also [Istio's Performance oriented FAQ](https://github.com/istio/istio/wiki/Istio-Performance-oriented-setup-FAQ)

* And the [Performance and Scalability Working Group](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#performance-and-scalability) work.

Current recommendations (when using all Istio features):

* 1 vCPU per peak thousand requests per second for the sidecar(s)

* Assuming typical cache hit ratio (>80%) for mixer checks: 0.5 vCPU per peak thousand requests per second for the mixer pods.

* Latency cost/overhead is about [14 millisecond](https://fortio.istio.io/browse?url=qps_400-s1_to_s2-0.7.1-2018-04-05-22-06.json) for service-to-service (2 proxies involved, mixer telemetry and checks) as of 0.7.1, we are working on bringing this down to a low single digit ms.

We plan on providing more granular guidance for customers adopting Istio "A la carte".

The goal for 2018 for Istio is to reduce both the CPU overhead and latency of adding Istio to your application but please note that if you application is handling its own telemetry, policy, security, network routing, a/b testing, etc... all that code and cost can be removed and that should offset most if not all of the Istio overhead.
