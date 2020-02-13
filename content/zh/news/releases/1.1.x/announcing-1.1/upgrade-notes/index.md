---
title: 升级说明
description: 在升级到 Istio 1.1 之前，操作人员必须了解的重要更改。
weight: 20
---

本页描述了从 Istio 1.0 升级到 1.1 时需要注意的变化。在这里我们详细介绍了一些故意破坏向后兼容性的情况。我们还提到保留向后兼容性的情况，但是引入了一些新的行为，这对于熟悉 Istio 1.0 的使用者和操作人员来说很吃惊。

有关 Istio 1.1 引入的新特性的概述，请参阅 [1.1 更改说明](/zh/news/releases/1.1.x/announcing-1.1/change-notes/)。

## 安装{#installation}

- 我们增加了控制平面和 envoy sidecar 所需的 CPU 和 内存。在进行更新之前，确保集群具有足够的资源至关重要。

- Istio 的 CRD 已放置在它们自己的 Helm 图表 `istio-init` 中。这样可以防止丢失自定义资源数据，简化升级过程，并在基于 Helm 的安装之外推动 Istio 的发展。
[升级文档](/zh/docs/setup/upgrade/)提供了从 Istio 1.0.6 升级到 Istio 1.1 的正确步骤。当升级时，请仔细遵循这些说明。当使用 `template` 或者 `tiller` 安装模式来安装 `istio-init`和 Istio 图表时，如果需要 `certmanager`，请使用 `--set certmanager=true` 标志。

- 许多安装选项已被添加、删除或者更改。请参阅[安装选项更改](/zh/news/releases/1.1.x/announcing-1.1/helm-changes/)来获得详细的更改概要。

- 用于[多集群 VPN](/zh/docs/setup/install/multicluster/shared-vpn/)的 1.0 `istio-remote` 图表和[多集群共享网关](/zh/docs/setup/install/multicluster/shared-gateways/)的远程集群安装已经被合并到 Istio 图表中。为了生成等价的 `istio-remote` 图表，请使用 `--set global.istioRemote=true` 标志。

- 插件不再通过单独的负载均衡器暴露。现在可以通过选择 Ingress 网关暴露插件。当通过 Ingress 网关暴露插件时，请遵循[远程访问遥测插件](/zh/docs/tasks/observability/gateways/)指南进行操作。

- 内置的 Istio Statsd 收集器已经被删除。Istio 保留了与您自己的 Statsd 收集器集成的功能，可以使用 `--set global.envoyStatsd.enabled=true` 标志。

- 用于配置 Kubernetes 入口的一系列 `ingress` 选项已经被删除。使用 `--set global.k8sIngress.enabled=true` 标志依然可以开启并使用 Kubernetes Ingress。请参阅[使用 Cert-Manager 确保 Kubernetes Ingress 安全](/zh/docs/tasks/traffic-management/ingress/ingress-certmgr/)的文档了解如何保护 Kubernetes 入口资源。

## 流量管理{#traffic-management}

- 现在出站流量的默认策略为 `ALLOW_ANY`。到达未知端口的流量将按原样转发。到达已知端口（例如 80 端口）的流量将与系统中的一个服务匹配并进行相应的转发。

- 将 sidecar 路由到服务期间，与 sidecar 相同命名空间中的目标服务的 destination rule 将优先使用，随后是服务命名空间的 destination rule，最后是在其他命名空间的 destination rule（如果适用）。

- 我们建议将网关资源存储在与网关工作负载相同的命名空间中（例如在 `istio-ingressgateway` 情况下使用 `istio-system` 命名空间）。
当在虚拟服务中提到网关资源时，使用命名空间/名称格式而不要使用 `name.namespace.svc.cluster.local`。

- 现在默认情况下禁用可选的出口网关。在 demo 配置文件中启用它，以供用户浏览，但默认情况下在所有的其他配置文件中已禁用。
如果您需要通过出口网关控制和保护出站流量，则需要在任何非演示配置文件中，手动启用 `gateways.istio-egressgateway.enabled=true`。

## 策略和遥测{#policy-telemetry}

- 现在默认禁用 `istio-policy` 检查。demo 配置文件中启用它，供用户评测，但在所有的其他配置文件已禁用该检查。这个改变仅针对 `istio-policy` 而不针对 `istio-telemetry`。若想重新启用该策略检查，请运行 `helm template` 并附带 `--set global.disablePolicyChecks=false` 参数，重新应用配置。

- Service Graph 组件已被弃用，推荐使用 [Kiali](https://www.kiali.io/)。

## 安全{#security}

- RBAC 配置已被修改来实现集群作用域。`RbacConfig` 资源已经被替换成 `ClusterRbacConfig` 资源。请参阅[将 `RbacConfig` 迁移到 `ClusterRbacConfig`](https://archive.istio.io/v1.1/docs/setup/kubernetes/upgrade/steps/#migrating-from-rbacconfig-to-clusterrbacconfig)的文档获得更多的迁移说明。
