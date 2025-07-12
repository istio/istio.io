---
title: Tencent Cloud
description: Instructions to set up Istio quickly in Tencent Cloud.
weight: 65
skip_seealso: true
keywords: [platform-setup,tencent-cloud-mesh,tcm,tencent-cloud,tencentcloud]
owner: istio/wg-environments-maintainers
test: n/a
---

## Prerequisites

Follow these instructions to prepare a [Tencent Kubernetes Engine](https://intl.cloud.tencent.com/products/tke) or [Elastic Kubernetes Service](https://intl.cloud.tencent.com/product/eks) cluster for Istio.

You can deploy a Kubernetes cluster to Tencent Cloud via [Tencent Kubernetes Engine](https://intl.cloud.tencent.com/document/product/457/40029) or [Elastic Kubernetes Service](https://intl.cloud.tencent.com/document/product/457/34048) which fully supports Istio.

{{< image link="./tke.png" caption="Create Cluster" >}}

## Procedure

After creating a Tencent Kubernetes Engine or Elastic Kubernetes Service cluster, you can quickly start to deploy and use Istio by [Tencent Cloud Mesh](https://cloud.tencent.com/product/tcm):

{{< image link="./tcm.png" caption="Create Tencent Cloud Mesh" >}}

1. Log on to the `Container Service console`, and click **Service Mesh** in the left-side navigation pane to enter the **Service Mesh** page.

1. Click the **Create** button in the upper-left corner.

1. Enter the mesh name.

    {{< tip >}}
    The mesh name can be 1–60 characters long and it can contain numbers, Chinese characters, English letters, and hyphens (-).
    {{< /tip >}}

1. Select the **Region** and **Zone** in which the cluster resides.

1. Choose the Istio version.

1. Choose the service mesh mode: `Managed Mesh` or `Stand-Alone Mesh`.

    {{< tip >}}
    Tencent Cloud Mesh supports **Stand-Alone Mesh** (Istiod is running in the user cluster and managed by users) and **Managed Mesh** (Istiod is managed by Tencent Cloud Mesh Team).
    {{< /tip >}}

1. Configure the Egress traffic policy:  `Register Only` or `Allow Any` .

1. Choose the related **Tencent Kubernetes Engine** or **Elastic Kubernetes Service** cluster.

1. Choose to open sidecar injection in the selected namespaces.

1. Configure external requests to bypass the IP address block directly accessed by the sidecar, and external request traffic will not be able to use Istio traffic management, observability and other features.

1. Choose to open **SideCar Readiness Guarantee** or not. If it is open, app containers will be created after sidecar is running.

1. Configure the Ingress Gateway and Egress Gateway.

{{< image link="./tps.png" caption="Configure Observability" >}}

1. Configure the Observability of Metrics, Tracing and Logging.

    {{< tip >}}
    Besides the default Cloud Monitor services, You can choose to open the advanced external services like [Managed Service for Prometheus](https://intl.cloud.tencent.com/document/product/457/38824?has_map=1) and the [Cloud Log Service](https://intl.cloud.tencent.com/product/cls).
    {{< /tip >}}

After finishing these steps, you can confirm to create Istio and start to use Istio in Tencent Cloud Mesh.
