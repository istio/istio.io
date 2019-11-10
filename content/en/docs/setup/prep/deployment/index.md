---
title: Deployment Best Practices
description: General best practices for your Istio deployments.
weight: 2
icon: best-practices
---

We've identified the following general principles to help you get the most out
of your Istio deployments.

## Prefer simpler deployment models

When choosing a [deployment model](/docs/setup/prep/deployment-models),
prefer the **simplest** deployment possible. Keeping the complexity of your
deployment to a minimum makes the task of managing your deployment easier.

## Deploy clusters near your users

Include clusters in your deployment across the globe for **geographic
proximity to end-users**. The proximity helps your deployment have low latency.

## Deploy across multiple availability zones

Include clusters in your deployment **across multiple availability regions
and zones** within each geographic region. This approach limits the size of the
{{< gloss "failure domain" >}}failure domains{{< /gloss >}} of your deployment,
and helps you avoid global failures.

An Istio deployment running on Kubernetes satisfies the best practices
above if it meets the following conditions:

- The deployment runs a control plane per cluster.
- Each control plane gets its configuration from the API Server within the cluster.

These conditions limit the impact of bad configuration changes since
changes to the API Server do not affect control planes running in other zones.
