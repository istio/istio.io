---
title: General Principles
description: The general principles for your Istio deployments.
weight: 1
icon: best-practices
---

We've identified the following general principles to help you get the most out
of your Istio deployments.

## Make your deployment simple

When choosing a [deployment model](/docs/concepts/deployment-models),
**prefer simplicity over complexity** wherever possible.

## Make your deployment fast

Include clusters in your deployment across the globe for **geographic
proximity to end-users**. The proximity helps your deployment have low latency.

## Make your deployment reliable

Include clusters in your deployment **across multiple availability regions
and zones** within each region. This approach helps you avoid global failures.

Follow these recommendations to enhance the reliability of your deployment:

- Deploy each workload to at least one cluster per region.
- Deploy a control plane to at least one cluster per region.
- Ensure each control plane has a dedicated configuration source.
- Roll out changes incrementally. Do not change all failure domains at once.

For example, an Istio deployment that satisfies the reliability recommendations above
running in Kubernetes would meet the following conditions:

- The deployment runs a control plane in one cluster per availability zone.
- Each control plane gets its configuration from the API Server within the cluster.

These conditions limit the impact of bad configuration changes since
changes to the API Server do not affect control planes running in other zones.
