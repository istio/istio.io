---
title: Kiali
description: 有关如何与 Kiali 集成的信息。
weight: 29
keywords: [integration,kiali]
owner: istio/wg-environments-maintainers
test: no
---
[Kiali](https://kiali.io/) 是具有服务网格配置和验证功能的 Istio 可观察性的控制台。通过监视流量来推断拓扑和错误报告，它可以帮助您了解服务网格的结构和运行状态。Kiali 提供了详细的的指标并与 Grafana 进行基础集成，可以用于高级查询。通过与 [Jaeger](/zh/docs/ops/integrations/jaeger) 来提供分布式链路追踪功能。

## 安装{#installation}

### 方法1：快速开始{#option-1-quick-start}

Istio 提供了一个基础的安装示例用于快速使用和运行 Kiali：

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/kiali.yaml
{{< /text >}}

这将会在您的集群中部署 Kiali。这仅用于演示，并且不会针对性能或安全性进行调整。

{{< tip >}}
如果尝试安装插件时出现错误，请尝试再次运行该指令。再次运行该命令可能会解决一些计时性问题。
{{< /tip >}}

### 方法2：自定义安装{#option-2-customizable-install}

Kiali 项目提供了自己的[快速入门指南](https://kiali.io/documentation/latest/quick-start)和[自定义安装方法](https://kiali.io/documentation/latest/installation-guide)。我们建议生产用户遵循这些说明，确保了解最新版本和最佳方式。

## 使用{#usage}

更多关于 Kiali 的使用信息，请查看[可视化网格](/zh/docs/tasks/observability/kiali/)任务.
