---
title: Monitoring Multicluster Istio with Prometheus
description: Configure Prometheus to monitor multicluster Istio.
weight: 10
aliases:
  - /help/ops/telemetry/monitoring-multicluster-prometheus
  - /docs/ops/telemetry/monitoring-multicluster-prometheus
---

## Overview

This is meant to provide operational guidance on how to configure monitoring of Istio meshes comprised of two
or more individual Kubernetes clusters. It is not meant to establish the *only* possible path forward, but rather
to demonstrate a workable approach to multicluster telemetry with Prometheus.

Our recommendation for multicluster monitoring of Istio with Prometheus is built upon the foundation of Prometheus
[hierarchical federation](https://prometheus.io/docs/prometheus/latest/federation/#hierarchical-federation).
Prometheus instances that are deployed locally to each cluster by Istio act as initial collectors that then federate up to a production
mesh-wide Prometheus instance. That mesh-wide Prometheus can either live outside of the mesh (external), or in one
of the clusters within the mesh.

## Multicluster Istio setup

There are a couple of [multicluster deployment models](/docs/ops/deployment/deployment-models/#multiple-clusters)
supported by Istio. You can follow the [multicluster installation](/docs/setup/install/multicluster/) section to setup
your multicluster Istio. For the purposes of this guide, any of those approaches will work, with the following
caveat:

**Ensure that a cluster-local Istio Prometheus instance is installed in each cluster.**

Individual Istio deployments of Prometheus in each cluster are required to form the basis of cross-cluster monitoring by
way of federation to a production-ready instance of Prometheus that runs externally or in one of the clusters.

For multicluster deployments that use the `remote` profile, you must add the following to the `istioctl manifest` command:

{{< text bash >}}
$ istioctl manifest apply -f --set addonComponents.prometheus.enabled=true
{{< /text >}}

Validate that you have an instance of Prometheus running in each cluster:

{{< text bash >}}
$ kubectl -n istio-system get services prometheus
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
prometheus   ClusterIP   10.8.4.109   <none>        9090/TCP   20h
{{< /text >}}

## Configure Prometheus federation

### External production Prometheus

There are several reasons why you may want to have a Prometheus instance running outside of your Istio deployment.
Perhaps you want long-term monitoring disjoint from the cluster being monitored. Perhaps you want to monitor multiple
separate meshes in a single place. Or maybe you have other motivations. Whatever your reason is, you’ll need some special
configurations to make it all work.

{{< image width="80%"
    link="./external-production-prometheus.svg"
    alt="Architecture of external Production Prometheus for monitoring multicluster Istio."
    caption="External Production Prometheus for monitoring multicluster Istio"
    >}}

{{< warning >}}
This guide does not cover securing access to Prometheus. It demonstrates providing connectivity to cluster-local Prometheus
instances in a few simple ways. For production use cases, it is recommended to secure access to each Prometheus endpoint
with HTTPS, as well as taking appropriate precautions such as using an internal load-balancer instead of a publicly-accessible
endpoint and/or properly configuring firewall rules.
{{< /warning >}}

Istio provides a way to expose cluster services externally via [Gateways](/docs/reference/config/networking/gateway/).
You can configure an ingress gateway for the cluster-local Prometheus, providing external connectivity to the in-cluster
Prometheus endpoint.

For each cluster, follow the appropriate instructions from the [Remotely Accessing Telemetry Addons](/docs/tasks/observability/gateways/#option-1-secure-access-https) task. And you
**SHOULD** establish secure (HTTPS) access.

After that, you will need to configure your external Prometheus instance to access the cluster-local Prometheus instances.
This can be achieved with a configuration like the following (replacing the gateway address and cluster name):

{{< text yaml >}}
scrape_configs:
  - job_name: 'federate-{{CLUSTER_NAME}}'
    scrape_interval: 15s

    honor_labels: true
    metrics_path: '/federate'

    params:
      'match[]':
        - '{job="pilot"}'
        - '{job="envoy-stats"}'

    static_configs:
      - targets:
        - '{{GATEWAY_IP_ADDR}}:15030'
        labels:
          cluster: {{CLUSTER_NAME}}
{{< /text >}}

Notes:

* `CLUSTER_NAME` should be set to the same value which is used to create the cluster (set via `values.global.multiCluster.clusterName`).

* No authentication to the Prometheus endpoint(s) is provided. This means that anyone can query your
cluster-local Prometheus instances. This may not be desirable.

* Without proper HTTPS configuration of the gateway, everything is being transported via plaintext. This may not be
desirable.

### Production Prometheus from one of the clusters

If you desire to run a Prometheus in one of the clusters, establish connectivity from the production instance of
Prometheus to each of the cluster-local Prometheus instances within the mesh.

This is really just a customization of the process for external federation, which you can achieve by configuring the `Gateway`,
`VirtualService`, and `DestinationRule` in each remote cluster.

{{< image width="80%"
    link="./in-mesh-production-prometheus.svg"
    alt="Architecture of in-mesh Production Prometheus for monitoring multicluster Istio."
    caption="In-mesh Production Prometheus for monitoring multicluster Istio"
    >}}

Configure your production Prometheus to access both of the *local* and the *remote* Prometheus instances. This can be achieved
by adding a configuration like the following for the *remote* clusters (replacing the service name and cluster name for each cluster):

{{< text yaml >}}
scrape_configs:
  - job_name: 'federate-{{CLUSTER_NAME}}'
    scrape_interval: 15s

    honor_labels: true
    metrics_path: '/federate'

    params:
      'match[]':
        - '{job="pilot"}'
        - '{job="envoy-stats"}'

    static_configs:
      - targets:
        - '{{GATEWAY_IP_ADDR}}:15030'
        labels:
          cluster: {{CLUSTER_NAME}}
{{< /text >}}

Then add a configuration like the following for the *local* cluster:

{{< text yaml >}}
- job_name: 'federate-local'
  honor_labels: true
  metrics_path: '/federate'
  metrics_relabel_configs:
  - replacement: {{CLUSTER_NAME}}
    targetLabel: cluster
  kubernetes_sd_configs:
  - role: pod
    namespaces:
      names: ['istio-system']
  params:
    'match[]':
    - '{__name__=~"istio_(.*)"}'
    - '{__name__=~"pilot(.*)"}'
{{< /text >}}