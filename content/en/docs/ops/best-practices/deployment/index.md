---
title: Deployment Best Practices
description: General best practices when setting up an Istio service mesh.
force_inline_toc: true
weight: 10
aliases:
  - /docs/ops/prep/deployment
owner: istio/wg-environments-maintainers
test: n/a
---

We have identified the following general principles to help you get the most
out of your Istio deployments. These best practices aim to limit the impact of
bad configuration changes and make managing your deployments easier.

## Deploy fewer clusters

Deploy Istio across a small number of large clusters, rather than a large number
of small clusters. Instead of adding clusters to your deployment, the best
practice is to use [namespace tenancy](/docs/ops/deployment/deployment-models/#namespace-tenancy)
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

## Run multiple istiod replicas

By default, `istiod` is deployed with a single replica. When that replica
becomes unavailable — for example, during a node drain or a rolling update — the
mutating webhook for sidecar injection (`failurePolicy: Fail`) rejects all pod
creation requests cluster-wide. This effectively makes a single `istiod`
replica a single point of failure for any operation that creates pods.

To avoid this, set `autoscaleMin` to at least `2` in your Helm values
override for the `istio/istiod` chart. The chart ships with
`autoscaleEnabled: true` by default, so the Horizontal Pod Autoscaler
controls the replica count. Setting the minimum to 2 ensures at least one
replica remains available during disruptions:

{{< text yaml >}}
autoscaleMin: 2
{{< /text >}}

Add the following to your Helm values override for the `istio/istiod` chart
to spread replicas across nodes and zones.
Use `requiredDuringSchedulingIgnoredDuringExecution` for node-level separation
to guarantee replicas run on different nodes. If capacity is insufficient, the
unschedulable pod surfaces the issue instead of silently colocating both
replicas on a single node. Use `preferredDuringSchedulingIgnoredDuringExecution`
for zone-level spreading to avoid blocking scheduling in clusters with fewer
zones than replicas:

{{< text yaml >}}
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - istiod
      topologyKey: kubernetes.io/hostname
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - istiod
        topologyKey: topology.kubernetes.io/zone
{{< /text >}}
