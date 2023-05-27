---
title: Istio 1.6 升级说明
description: 升级到 Istio 1.6 时需要考虑的重要更改。
weight: 20
release: 1.6
subtitle: Minor Release
linktitle: 1.6 Upgrade Notes
publishdate: 2020-05-21
---

当您从 Istio 1.5.x 升级到 Istio 1.6.x 时，
您需要考虑此页面上所描述的变化。
这些说明详细介绍了有意地破坏与 Istio 1.5.x
的向后兼容性所带来的变化。
说明中还提到了在引入新行为的同时保留向后兼容性的变化。
只有当新的行为对 Istio `1.5.x`
的用户来说是意想不到的时候，才会包括这些变化。

目前，Istio 不支持跨版本升级。如果您使用的是 Istio 1.4，
则必须先升级到 Istio 1.5，然后再升级到 Istio 1.6。
如果您从 Istio 1.4 之前的版本升级，
您应该首先禁用 Galley 的配置验证。

使用以下步骤更新 Galley 部署：

1. 要编辑 Galley 部署配置，请运行以下命令：

    {{< text bash >}}
    $ kubectl edit deployment -n istio-system istio-galley
    {{< /text >}}

1. 将 `--enable-validation=false` 选项添加到 `command:` 部分，如下所示：

    {{< text yaml >}}
    apiVersion: extensions/v1beta1
    kind: Deployment
    ...
    spec:
    ...
      template:
        ...
        spec:
          ...
          containers:
          - command:
            ...
            - --log_output_level=default:info
            - --enable-validation=false
    {{< /text >}}

1. 保存并退出编辑器以更新集群中的部署配置。

使用以下命令删除 `ValidatingWebhookConfiguration` 自定义资源（CR）：

    {{< text bash >}}
    $ kubectl delete ValidatingWebhookConfiguration istio-galley -n istio-system
    {{< /text >}}

## 更改网关就绪端口{#change-the-readiness-port-of-gateways}

如果您使用 `15020` 端口通过 Kubernetes
网络负载均衡器检查 Istio 入口网关的健康状况，
请将端口从 `15020` 更改为 `15021`。

## 删除遗留版本 Helm Chart{#removal-of-legacy-helm-charts}

Istio 1.4 引入了一种使用集群内
Operator 或 istioctl install
命令[安装 Istio 的新方法](/zh/blog/2019/introducing-istio-operator/)。
此更改的其中一部分意味着在 1.5
版中弃用旧版本 Helm Chart。
许多新的 Istio 功能依赖于新的安装方法。
因此，Istio 1.6 将不再包含旧版本 Helm Chart 安装方式。

在继续之前，请转到
[Istio 1.5 升级说明](/zh/news/releases/1.5.x/announcing-1.5/upgrade-notes/#control-plane-restructuring)，
因为 Istio 1.5 引入了一些旧安装方法中不存在的更改，
例如 Istiod 和观测 v2 版。

要从使用 Helm Chart 的旧安装方法安全升级，
请执行[控制平面修订](/zh/blog/2020/multiple-control-planes/)。
该操作不支持原地升级。升级可能会导致停机，
除非您执行[金丝雀升级](/zh/docs/setup/upgrade/#canary-upgrades)方式。

## 结束对 `v1alpha1` 版安全策略的支持{#support-ended-for-v1alpha1-security-policy}

Istio 1.6 不再支持以下安全策略 API：

- [身份验证策略 `v1alpha1` 版](https://archive.istio.io/v1.4/zh/docs/reference/config/security/istio.authentication.v1alpha1/)
- [RBAC 策略 `v1alpha1` 版](https://archive.istio.io/v1.4/docs/reference/config/security/istio.rbac.v1alpha1/)

从 Istio 1.6 开始，Istio 将忽略这些
`v1alpha1` 版的安全策略 API。

Istio 1.6 用以下 API
替换了身份验证策略 `v1alpha1` 版：

- [请求身份验证策略 `v1beta1` 版](/zh/docs/reference/config/security/request_authentication)
- [对等身份验证策略 `v1beta1` 版](/zh/docs/reference/config/security/peer_authentication)

Istio 1.6 将 `v1alpha1` 版 RBAC 策略 API
替换为[授权策略 API `v1beta1` 版](/zh/docs/reference/config/security/authorization-policy/)。

可以使用以下命令验证集群中是否存在 `v1alpha1` 版的安全策略：

    {{< text bash >}}
    $ kubectl get policies.authentication.istio.io --all-namespaces
    $ kubectl get meshpolicies.authentication.istio.io --all-namespaces
    $ kubectl get rbacconfigs.rbac.istio.io --all-namespaces
    $ kubectl get clusterrbacconfigs.rbac.istio.io --all-namespaces
    $ kubectl get serviceroles.rbac.istio.io --all-namespaces
    $ kubectl get servicerolebindings.rbac.istio.io --all-namespaces
    {{< /text >}}

如果您的集群中有任何 `v1alpha1` 版的安全策略，
请在升级前迁移到新的 API。

## 安装期间的 Istio 配置{#istio-configuration-during-installation}

在过去的 Istio 版本中会在安装过程中部署配置对象。
这些对象的存在导致了以下问题：

- 升级遇到的问题
- 令人困惑的用户体验
- 不太灵活的安装过程

为了解决这些问题，Istio 1.6
最小化了安装过程中部署的配置对象。

以下配置将受到影响：

- `global.mtls.enabled`：为了避免混淆移除了该配置。
  可以配置对等身份验证策略以开启[严格的 mTLS](/zh/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode)。
- 安装期间不会部署默认的 `Gateway`
  和关联的 `Certificate` 自定义资源。转到
  [Ingress 任务](/zh/docs/tasks/traffic-management/ingress/)来为您的网格配置网关。
- Istio 不再为观测插件创建 `Ingress` 自定义资源。
  访问[远程访问观测插件](/zh/docs/tasks/observability/gateways/)了解如何从外部访问插件。
- 不再通过自动生成的 `Sidecar`
  自定义资源定义默认的 Sidecar 配置。
  默认配置在内部实现，变更该配置应该不会对
  Deployment 产生影响。

## 通过外部工作负载访问 Istiod{#reach-istiod-through-external-workloads}

在 Istio 1.6 中，Istiod 默认配置为 `cluster-local`。
启用 `cluster-local` 后，
只有在同一集群上运行的工作负载才能访问 Istiod。
另一个集群上的工作负载只能通过 Istio 网关访问 Istiod 实例。
此配置可防止主集群的入口网关错误地将服务发现请求转发到远程集群中的 Istiod 实例。
Istio 团队正在积极研究不再需要 `cluster-local` 的替代方案。

如要覆盖默认的 `cluster-local` 行为，
请修改 `MeshConfig` 部分中的配置，如下所示：

    {{< text yaml >}}
    values:
      meshConfig:
        serviceSettings:
          - settings:
              clusterLocal: false
            hosts:
              - "istiod.istio-system.svc.cluster.local"
    {{< /text >}}
