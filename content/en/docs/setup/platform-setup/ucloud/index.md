---
title: UCloud
description: Instructions to setup an UCloud Kubernetes cluster for Istio.
weight: 70
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/ucloud/
    - /docs/setup/kubernetes/platform-setup/ucloud/
keywords: [platform-setup,uk8s,ucloud]
owner: istio/wg-environments-maintainers
test: n/a
---

Follow these instructions to prepare an
[UCloud Container Service for Kubernetes(UK8S)](https://docs.ucloud.cn/uk8s/README)
cluster for Istio.
You can deploy a Kubernetes cluster to UCloud quickly and easily, which fully supports Istio.

## Procedure

1. Log on to the [UCloud UK8S console](https://console.ucloud.cn/uk8s/manage), and click **Create Cluster** button.

1. Choose dedicated or managed cluster version. If dedicated cluster is chosen, 3 master nodes are required. If you choose managed version, the masters and core components like api-server, etcd, scheduler will be maintained by UCloud.

1. Select the **region** and **zone** in which the cluster resides.

1. Config Masters(in dedicated version) and Nodes, or keep the default configuration.

1. Set the **Administrator Password**.

1. Click the **Purchase Now** button in the upper-right corner.

1. Click the **Submit my order** button in the pop-up page.

1. The k8s cluster will be running in about ten minutes later;
