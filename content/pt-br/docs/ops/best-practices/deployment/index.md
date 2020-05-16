---
title: Deployment Best Practices
description: General best practices when setting up an Istio service mesh.
force_inline_toc: true
weight: 10
aliases:
  - /docs/ops/prep/deployment
---

We have identified the following general principles to help you get the most
out of your Istio deployments. These best practices aim to limit the impact of
bad configuration changes and make managing your deployments easier.

## Deploy fewer clusters

Deploy Istio across a small number of large clusters, rather than a large number
of small clusters. Instead of adding clusters to your deployment, the best
practice is to use [namespace tenancy](/pt-br/docs/ops/deployment/deployment-models/#namespace-tenancy)
to manage large clusters. Following this approach, you can deploy Istio across
one or two clusters per zone or region. You can then deploy a control plane on
one cluster per region or zone for added reliability.

## Deploy clusters near your users

Include clusters in your deployment across the globe for **geographic
proximity to end-users**. Proximity helps your deployment have low latency.

## Deploy across multiple availability zones

Include clusters in your deployment **across multiple availability regions
and zones** within each geographic region. This approach limits the size of the
{{< gloss "failure domain" >}}failure domains{{< /gloss >}} of your deployment,
and helps you avoid global failures.
