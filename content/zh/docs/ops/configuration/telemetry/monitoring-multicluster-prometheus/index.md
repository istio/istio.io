---
title: 使用 Prometheus 监控 Istio 多集群
description: 配置 Prometheus 监控 Istio 多集群。
weight: 10
aliases:
  - /zh/help/ops/telemetry/monitoring-multicluster-prometheus
  - /zh/docs/ops/telemetry/monitoring-multicluster-prometheus
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

## 概述{#overview}

本教程的目的是为如何配置两个或者多个 Kubernetes 集群组成的 Istio 网格提供操作引导。
这不是唯一的操作方式，而是演示一个使用 Prometheus 遥测多集群的可行方案。

我们推荐 Istio 多集群监控使用 Prometheus，其主要原因是基于 Prometheus
的[分层联邦](https://prometheus.io/docs/prometheus/latest/federation/#hierarchical-federation)（Hierarchical Federation）。

通过 Istio 部署到每个集群中的 Prometheus 实例作为初始收集器，然后将数据聚合到网格层次的 Prometheus 实例上。
网格层次的 Prometheus 既可以部署在网格之外（外部），也可以部署在网格内的集群中。

## 安装 Istio 多集群{#multicluster-Istio-setup}

按照[多集群安装](/zh/docs/setup/install/multicluster/)部分，
在[多集群部署模型](/zh/docs/ops/deployment/deployment-models/#multiple-clusters)中选择可行的模型配置 Istio 多集群。
为了能够实现本教程的目的，让示例都能够运行，并提出以下警告：

**确保在多集群中安装了一个 Istio Prometheus 集群实例!**

在每个集群中使用 Istio 独立部署的 Prometheus 是跨集群监控的基础，
通过联邦（Federation）的方式将 Prometheus 的生产就绪实例运行在网格外部或其中任意一个集群中。

验证在多集群中运行的 Prometheus 实例：

{{< text bash >}}
$ kubectl -n istio-system get services prometheus
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
prometheus   ClusterIP   10.8.4.109   <none>        9090/TCP   20h
{{< /text >}}

## 配置 Prometheus Federation{#configure-Prometheus-federation}

### 外部 Prometheus{#external-production-Prometheus}

您可能希望在 Istio 部署之外运行 Prometheus 实例有几个原因。
也许您希望长期监控并且与被监控的集群解耦。
也许您在想单独的地方去监测多个独立的网格。
或许你还有其他的动机，不管您的原因是什么，您都需要一些特殊的配置来让它全部工作起来。

{{< image width="80%"
    link="./external-production-prometheus.svg"
    alt="监控 Istio 多集群的外部 Prometheus 的架构。"
    caption="监控 Istio 多集群的外部 Prometheus"
    >}}

{{< warning >}}
本教程演示了连接主集群的 Prometheus 实例，但不涉及安全考虑因素。
对于生产用途，请使用 HTTPS 确保对每个 Prometheus 端点的访问安全。
此外，请采取预防措施，例如使用内部负载均衡而不是公共端点，并且配置适当的防火墙规则。
{{< /warning >}}

Istio 提供了一种通过 [Gateway](/zh/docs/reference/config/networking/gateway/) 向外部暴露集群服务的方式。
您可以为主集群的 Prometheus 配置 Ingress Gateway，为集群内 Prometheus 端点提供外部连接。

对于每个集群，请按照[远程访问遥测插件](/zh/docs/tasks/observability/gateways/#option-1-secure-access-https)任务中的相应说明进行操作。
还请注意，您**应该**建立安全（HTTPS）访问。

接下来，配置您的外部 Prometheus 实例，类似以下的配置来访问主集群的 Prometheus 实例（替换 Ingress 域名和集群名称）：

{{< text yaml >}}
scrape_configs:
- job_name: 'federate-{{CLUSTER_NAME}}'
  scrape_interval: 15s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{job="kubernetes-pods"}'

  static_configs:
    - targets:
      - 'prometheus.{{INGRESS_DOMAIN}}'
      labels:
        cluster: '{{CLUSTER_NAME}}'
{{< /text >}}

注意：

* `CLUSTER_NAME` 应该与创建集群时的值保持一致（通过 `values.global.multiCluster.clusterName` 设置）。

* 没有开启 Prometheus 端点验证。这意味着任何人都可以查询您的主集群的 Prometheus 实例，这是不可取的。

* 如果 Gateway 没有正确的 HTTPS 配置，所有的通讯都是通过明文传输的，这是不可取的。

### 集群内的 Prometheus{#production-Prometheus-on-an-in-mesh-cluster}

如果您希望在其中一个集群中运行 Prometheus，则需要与网格中的另一个主集群的 Prometheus 实例建立连接。

这实际上只是外部 federation 配置的一种变异。在这种情况下，运行在集群上的 Prometheus 的配置不同于远程集群Prometheus 的配置。

{{< image width="80%"
    link="./in-mesh-production-prometheus.svg"
    alt="监控 Istio 多集群的内部 Prometheus 的架构。"
    caption="监控 Istio 多集群的内部 Prometheus"
    >}}

配置您的 Prometheus 使得可以同时访问 **主** 和 **从** Prometheus 实例：

首先执行下面的命令：

{{< text bash >}}
$ kubectl -n istio-system edit cm prometheus -o yaml
{{< /text >}}

然后给 **从** 集群添加配置（替换每个集群的 Ingress 域名和集群名称），并且给 **主** 集群添加一个配置：

{{< text yaml >}}
scrape_configs:
- job_name: 'federate-{{REMOTE_CLUSTER_NAME}}'
  scrape_interval: 15s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{job="kubernetes-pods"}'

  static_configs:
    - targets:
      - 'prometheus.{{REMOTE_INGRESS_DOMAIN}}'
      labels:
        cluster: '{{REMOTE_CLUSTER_NAME}}'

- job_name: 'federate-local'

  honor_labels: true
  metrics_path: '/federate'

  metric_relabel_configs:
  - replacement: '{{CLUSTER_NAME}}'
    target_label: cluster

  kubernetes_sd_configs:
  - role: pod
    namespaces:
      names: ['istio-system']
  params:
    'match[]':
    - '{__name__=~"istio_(.*)"}'
    - '{__name__=~"pilot(.*)"}'
{{< /text >}}
