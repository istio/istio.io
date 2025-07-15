---
title: Alibaba Cloud
description: Instructions to set up an Alibaba Cloud Kubernetes cluster for Istio.
weight: 5
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/alicloud/
    - /docs/setup/kubernetes/platform-setup/alicloud/
keywords: [platform-setup,alibaba-cloud,aliyun,alicloud]
owner: istio/wg-environments-maintainers
test: n/a
---

{{< boilerplate untested-document >}}

Follow these instructions to prepare an
[Alibaba Cloud Kubernetes Container Service](https://www.alibabacloud.com/product/kubernetes)
cluster for Istio.
You can deploy a Kubernetes cluster to Alibaba Cloud quickly and easily in the
`Container Service console`, which fully supports Istio.

{{< tip >}}
Alibaba Cloud offers a fully managed service mesh platform named Alibaba Cloud Service Mesh (ASM),
 which is fully compatible with Istio. Refer to
 [Alibaba Cloud Service Mesh](https://www.alibabacloud.com/help/doc-detail/147513.htm) for
 details and instructions.
{{< /tip >}}

## Prerequisites

1. [Follow the Alibaba Cloud instructions](https://www.alibabacloud.com/help/doc-detail/95108.htm)
to activate the following services: Container Service, Resource Orchestration
 Service (ROS), and RAM.

## Procedure

1. Log on to the `Container Service console`, and click **Clusters** under
**Kubernetes** in the left-side navigation pane to enter the **Cluster List** page.

1. Click the **Create Kubernetes Cluster** button in the upper-right corner.

1. Enter the cluster name. The cluster name can be 1–63 characters long and
it can contain numbers, Chinese characters, English letters, and hyphens (-).

1. Select the **region** and **zone** in which the cluster resides.

1. Set the cluster network type. Kubernetes clusters only support the VPC
network type now.

1. Configure the node type, Pay-As-You-Go and Subscription types are supported.

1. Configure the master nodes. Select the generation, family, and type for the
master nodes.

1. Configure the worker nodes. Select whether to create a worker node or add an
 existing ECS instance as the worker node.

1. Configure the logon mode, and configure the Pod Network CIDR and Service
CIDR.
