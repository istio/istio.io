---
title: 1.1 升级通知
description: 在升级到 Istio 1.1 之前，运维人员必须了解的重要更改。
weight: 5

---

此页面描述了从 Istio 1.0 升级到 1.1 时需要注意的事项。在这里，我们详细介绍了我们向后不兼容性的情况。我们还提到了保留向后兼容性但引入了新行为的情况，这对于熟悉 Istio 1.0 的使用和操作的人来说是令人惊讶的。

有关 Istio 1.1 引入的新功能的概述，请参阅 [1.1 发行说明](/about/notes/1.1/)。

## 安装

- 我们增加了控制平面和 Envoy Sidecar 所需的 CPU 和内存。在更新之前，确保群集有足够的资源。
- Istio 的 CRD 已被放入他们自己的 Helm chart `istio-init` 中。这可以防止丢失自定义资源数据，促进升级过程，使 Istio 能够基于 Helm 的安装形式也可以升级。 [升级文档](/docs/setup/kubernetes/upgrade/steps/) 提供了从 Istio 1.0.6 升级到 Istio 1.1 的正确过程。升级时请仔细遵循这些说明。如果需要 `certmanager`，在使用 `template` 或 `tiller` 安装模式安装`istio-init` 和 Istio chart 时，请使用 `--set certmanager=true` 标志。
- 用于[多集群 VPN](/zh/docs/setup/kubernetes/install/multicluster/vpn/) 的 1.0 `istio-remote` chart 和 [多集群水平分割](/zh/docs/tasks/multicluster/split-horizon-eds/) 远程集群安装已合并到 Istio chart 中。要生成等效的 `istio-remote` chart，请使用 `--set global.istioRemote=true` 标志。
- 插件不再通过单独的负载均衡器暴露。现在可以选择通过 Ingress 网关公开插件。要通过 Ingress Gateway 公开插件，请按照[远程访问遥测插件](/docs/tasks/telemetry/gateways/)指南进行操作。
- 内置的 Istio Statsd 收集器已被删除。 Istio 使用 `--set global.envoyStatsd.enabled=true` 标志保留与您自己的 Statsd 收集器集成的功能。
- 用于配置 Kubernetes Ingress 的 `ingress` 系列选项已被删除。 Kubernetes Ingress 仍然可以使用 `--set global.k8sIngress.enabled=true` 标志启用。查看[使用 Cert-Manager 保护 Kubernetes Ingress](/docs/tasks/traffic-management/edge-traffic/ingress-certmgr/)，了解如何保护您的 Kubernetes 入口资源。

## 流量管理

- 出站流量策略现在默认为 `ALLOW_ANY`。未知端口的流量将按原样转发。到已知端口（例如，端口 80 ）的流量将与系统中的一个服务匹配并相应地转发。
- 在对服务的 Sidecar 路由期间，与 Sidecar 相同的命名空间中的目标服务的目标规则将优先，随后是服务命名空间中的目标规则，并且如果适用，最后在其他命名空间中跟随目标规则。
- 我们建议将网关资源存储在与网关工作负载相同的命名空间中（例如，在 `istio-ingressgateway` 的情况下为 `istio-system`）。在引用虚拟服务中的网关资源时，请使用命名空间/名称格式，而不是使用 `name.namespace.svc.cluster.local`。
- 现在，默认情况下禁用可选的出口网关。它在演示配置文件中启用，供用户浏览，但默认情况下禁用所有其他配置文件。如果您需要通过出口网关控制和保护出站流量，则需要在任何非演示配置文件中手动启用 `gateways.istio-egressgateway.enabled=true`。

## 策略与遥测

- `istio-policy` 检查现在默认禁用。它在演示配置文件中启用，供用户浏览但在所有其他配置文件中禁用。这种变化仅适用于 `istio-policy` 而不适用于 `istio-telemetry`。要重新启用策略检查，请使用 `--set global.disablePolicyChecks=false` 运行 `helm template` 并重新应用配置。
- 服务图组件现已弃用，推荐使用 [Kiali](https://www.kiali.io/)。

## 安全

- 已修改 RBAC 配置以实现集群范围。 `RbacConfig` 资源已被 `ClusterRbacConfig` 资源取代。有关迁移说明，请参阅[将 `RbacConfig` 迁移到 `ClusterRbacConfig`](/docs/setup/kubernetes/upgrade/steps/#migrating-from-rbacconfig-to-clusterrbacconfig)。
