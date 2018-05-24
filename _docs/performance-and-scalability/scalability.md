---
title: Scalability
overview: Setup of Istio components to scale horizontally. High availability.
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

* 1 vCPU per peak thousand requests per seconds for the sidecar(s)

* Assuming typical cache hit ratio (>80%) for mixer checks: 0.5 vCPU per peak thousand uncached requests per seconds for the mixer pods.

We plan on providing more granular guidance for customers adopting Istio "A la carte".

The goal for 2018 for Istio is for the overhead/cost of adding it to your application to be less than 15% extra virtual hardware required, we currently (as of 0.7.1) are at around 50% overhead.
