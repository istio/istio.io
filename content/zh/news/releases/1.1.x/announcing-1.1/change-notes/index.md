---
title: 变更说明
description: Istio 1.1 发行说明。
weight: 10
aliases:
    - /zh/about/notes/1.1
---

## 从 1.0 开始的不兼容变更{#incompatible-changes-from-1-0}

除了下面列出的新功能和改进之外，Istio 从 1.0 开始就引入了许多重要改进，这些改进可以更改应用程序的行为。在[升级说明](/zh/news/releases/1.1.x/announcing-1.1/upgrade-notes)中可以找到这些改进的简明清单。

## 升级{#upgrades}

我们建议手动将控制平面和数据平面升级到 1.1。有关更多信息，请参见[升级文档](/zh/docs/setup/upgrade/)。

{{< warning >}}
在将 deployment 升级到 Istio 1.1 之前，请务必查看[升级说明](/zh/news/releases/1.1.x/announcing-1.1/upgrade-notes)以获得您应该了解的简要清单。
{{< /warning >}}

## 安装{#installation}

- **将 CRD 安装从 Istio 安装中分离出来**。将 Istio 的自定义资源（CRD）放入 `istio-init` Helm chart 中。将 CRD 放置在自己的 Helm chart 中，可以在升级过程中保留自定义资源内容的数据连续性，并进一步使 Istio 能够超越基于 Helm 的安装。

- **安装配置文件**。添加了几个安装配置文件，以便使用成熟的且经过测试的方式简化安装过程。[安装配置文件功能](/zh/docs/setup/additional-setup/config-profiles/)为用户提供了更好的体验，以便您详细了解。

- **改进多集群集成**。将 `istio-remote` chart 1.0 合并到 Istio Helm chart 中，从而简化操作体验，其先前用于[多集群 VPN](/zh/docs/setup/install/multicluster/shared-vpn/) 和[多集群水平拆分](/zh/docs/setup/install/multicluster/shared-gateways/)远程集群安装。

## 流量管理{#traffic-management}

- **新的 `Sidecar` 资源**。通过新的 [sidecar](/zh/docs/concepts/traffic-management/#sidecars) 资源，可以更精细地控制附加到命名空间中工作负载的 sidecar 代理的行为。特别是，它增加了对限制 sidecar 向其发送流量的服务集的支持。这减少了计算和传输给代理的配置量，从而改善了启动时间、资源消耗和控制平面可伸缩性。对于复杂部署，我们建议为每个命名空间添加 sidecar 资源。我们还为高级用例的端口、协议和流量捕获提供了控件。

- **限制服务的可见性**。添加了新的 `exportTo` 功能，该功能允许服务所有者控制哪些命名空间可以引用其服务。此功能已添加到`ServiceEntry`，`VirtualService` 中，并且 Kubernetes 服务也通过 `networking.istio.io/exportTo` 批注支持该功能。

- **命名空间范围**。当在网关中引用 `VirtualService` 时，我们在配置模型中使用基于 DNS 的名称匹配。当多个命名空间为同一主机名定义虚拟服务时，这会造成模棱两可的情况。为了解决歧义，现在可以在 `hosts` 字段中使用 **`[{namespace-name}]/{hostname-match}`** 形式的语法按命名空间显式定义这些引用的范围。在 egress `Sidecar` 中也可以使用相同功能。

- **更新 `ServiceEntry` 资源**。现在支持指定，与双向 TLS 一起使用的服务及相关 SAN 的位置。具有 HTTPS 端口的服务条目不再需要其他虚拟服务来启用基于 SNI 的路由。

- **位置感知路由**。添加了对在选择其他地区的服务之前路由到相同地区的服务的完整支持。请参阅[本地负载均衡器设置](/zh/docs/reference/config/networking/destination-rule#LocalityLoadBalancerSetting)

- **完善多集群路由**。简化了多集群设置并启用了其他部署模式。现在，您可以简单地使用它们的入口网关连接多个集群，而无需 Pod 级的 VPN，针对高可用性情况在每个集群中部署控制平面，并跨多个集群创建命名空间以实现创建全局命名空间。高可用控制平面解决方案默认启用位置感知路由。

- **弃用 Istio Ingress**。删除了以前不推荐使用的 Istio ingress。有关如何在[网关](/zh/docs/concepts/traffic-management/#gateways)中使用 Kubernetes Ingress 资源的更多详细信息，请参考[使用 Cert-Manager 保护 Kubernetes Ingress](/zh/docs/tasks/traffic-management/ingress/ingress-certmgr/) 示例。

- **改进性能和可伸缩性**。调整 Istio 和 Envoy 的性能和可伸缩性。阅读[性能和可伸缩性](/zh/docs/ops/deployment/performance-and-scalability/)获取更多信息。

- **默认关闭访问日志**。默认情况下，禁用所有 Envoy sidecar 的访问日志以提高性能。

### 安全{#security}

- **就绪和存活探针**。添加了对 Kubernetes HTTP [就绪和存活探针](/zh/faq/security/#k8s-health-checks)的支持（启用双向 TLS 时）。

- **群集 RBAC 配置**。用 `ClusterRbacConfig` 资源替换了 `RbacConfig` 资源，以实现正确的集群范围。关于迁移说明，请参见[将 `RbacConfig` 迁移到 `ClusterRbacConfig`](https://archive.istio.io/v1.1/docs/setup/kubernetes/upgrade/steps/#migrating-from-rbacconfig-to-clusterrbacconfig)。

- **通过 SDS 进行身份认证**。添加了 SDS 支持，通过节点密钥生成以及动态证书轮换，来提供更强的安全性，并且无需重启 Envoy。有关更多信息，请参见[通过 SDS 进行身份认证](/zh/docs/tasks/security/citadel-config/auth-sds)。

- **TCP 服务授权**。除了 HTTP 和 gRPC 服务之外，还增加了对 TCP 服务的授权支持。有关更多信息，请参见 [TCP 服务授权](/zh/docs/tasks/security/authorization/authz-tcp)。

- **终端用户组的授权**。添加了基于 `组` 声明或 JWT 中任何列表类型声明的授权。有关更多信息，请参见[组和列表声明的授权](/zh/docs/tasks/security/authorization/rbac-groups/)。

- **Ingress Gateway 控制器的外部证书管理**。添加了一个控制器以动态加载和轮转外部证书。

- **自定义 PKI 集成**。添加了 Vault PKI 集成，并支持受 Vault 保护的签名密钥，并能直接与现有的 Vault PKI 集成。

- **自定义信任域（非`cluster.local`）**。在标识中增加了对特定于组织或群集的信任域的支持。

## 策略和遥测{#policies-and-telemetry}

- **默认关闭策略检查**。默认情况下，修改后的策略检查是关闭的，以提高大多数客户方案的性能。[启用策略执行](/zh/docs/tasks/policy-enforcement/enabling-policy/)详细说明了如何根据需要开启 Istio 策略检查。

- **Kiali**。用 [Kiali](https://www.kiali.io) 替换了 [Service Graph addon](https://github.com/istio/istio/issues/9066)，以提供更丰富的可视化体验。有关更多详细信息，请参见 [Kiali 任务](/zh/docs/tasks/observability/kiali/)。

- **减少开销**。添加了一些性能和规模改进，包括：

    - 大大减少了 Envoy 默认收集生成的统计信息的开销。

    - 为 Mixer 工作负载添加了负载削减功能。

    - 改进了 Envoy 和 Mixer 之间的协议。

- **请求头和路由控制**。添加了创建适配器以影响传入请求 header 和路由的选项。有关更多信息，请参见[请求头和路由控制](/zh/docs/tasks/policy-enforcement/control-headers)任务。

- **进程外适配器**。添加了生产可用的进程外适配器功能。然后，我们在此版本中弃用了进程内适配器模型。所有新的适配器开发都应使用进程外模型。

- **追踪改进**。在我们的总体追踪故事中进行了许多改进：

    - 跟踪 ID 的位宽现在是 128。

    - 现在支持将追踪数据发送到 [LightStep](/zh/docs/tasks/observability/distributed-tracing/lightstep/)。

    - 添加了一个选项，可用于完全禁用由 Mixer 支持的服务的跟踪功能。

    - 添加了策略 decision-aware 跟踪。

- **默认的 TCP 指标**。为追踪 TCP 连接增加默认指标

- **降低插件的负载均衡的要求**。不再通过单独的负载均衡公开插件。而是通过 Istio 网关公开插件。要使用 HTTP 或 HTTPS 协议从外部公开插件，请使用 [Addon Gateway 文档](/zh/docs/tasks/observability/gateways/)。

- **附加安全凭证**。更改了附加凭证的存储。为了提高安全性与合规性，Grafana、Kiali 以及 Jaeger 的用户名密码现在存储在 [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/) 中。

- **更加灵活的 `statsd` 收集器**。删除了内置的 `statsd` 收集器。Istio 现在支持您自己的 `statsd`，以提高现有 Kubernetes 部署的灵活性。

### 配置管理{#configuration-management}

- **Galley**。添加 [Galley](/zh/docs/ops/deployment/architecture/#galley) 作为 Istio 主要的配置收集和分发装置。它提供了一个健壮的模型来验证，转换配置状态并将其分配给 Istio 组件，从而将 Istio 组件与 Kubernetes 详细信息隔离开来。Galley 使用[网格配置协议](https://github.com/istio/api/tree/{{<source_branch_name >}}/mcp) 与组件进行交互。

- **监听端口**。将 Galley 的默认监听端口从 9093 修改为 15014。

## `istioctl` 和 `kubectl`{#Istio-and-Kube}

- **验证命名**。添加 [`istioctl validate`](/zh/docs/reference/commands/istioctl/#istioctl-validate) 命令，用于 Istio Kubernetes 资源的离线验证。

- **安装验证命令**。添加 [`istioctl verify-install`](/zh/docs/reference/commands/istioctl/#istioctl-verify-install) 命令，用于验证指定了 YAML 文件的 Istio 安装的状态。

- **弃用命令**。弃用 `istioctl create`、`istioctl replace`、`istioctl get` 和 `istioctl delete` 命令。
请使用 [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl) 替代。`istioctl gen-deploy` 命令也被弃用。请改用 [`helm template`](/zh/docs/setup/install/helm/#option-1-install-with-helm-via-helm-template)。这些命令将在 1.2 版被删除。

- **短命令**。`kubectl` 包含了一些简短命令，可用于 gateway，虚拟服务，目标规则和服务条目。
