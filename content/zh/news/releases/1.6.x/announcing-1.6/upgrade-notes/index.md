---
title: Istio 1.6 更新说明
description: 升级到Istio 1.6 时需要考虑的重要变化。
weight: 20
release: 1.6
subtitle: Minor Release
linktitle: 1.6 Upgrade Notes
publishdate: 2020-05-21
---

当您从 Istio 1.5.x 升级到 Istio 1.6.x 时，需要考虑本页面所列的更改。这些注释详细说明了会破坏与 Istio 1.5.x 向后兼容性的更改。注释还提到了保留向后兼容性同时引入新行为的更改。包含的更改仅在新行为对 Istio 1.5.x 的用户产生意外效果。

目前，Istio 不支持跳级升级。如果您正在使用 Istio 1.4，您必须先升级到 Istio 1.5，然后再升级到 Istio 1.6。如果您从早于 Istio 1.4 的版本进行升级，则应首先禁用 Galley 的配置验证。

请按以下步骤更新 Galley 部署：

1. 要编辑 Galley 部署配置，请运行以下命令：

{{< text bash >}}
$ kubectl edit deployment -n istio-system istio-galley
{{< /text >}}

2. 在 `command:` 部分中添加 `--enable-validation=false` 选项，如下所示：

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

3. 保存并退出编辑器，更新集群中的部署配置。

使用以下命令删除 `ValidatingWebhookConfiguration` 自定义资源（CR）：

{{< text bash >}}
$ kubectl delete ValidatingWebhookConfiguration istio-galley -n istio-system
{{< /text >}}

## 更改网关的端口

如果您正在使用 `15020` 端口通过 Kubernetes 网络负载均衡器检查 Istio 入口网关的状态，请将端口从 `15020` 更改为 `15021`。

## 移除旧版 Helm Chart

Istio 1.4 引入了一种[安装 Istio 的新方法](/blog/2019/introducing-istio-operator/)，使用集群内的 Operator 或 `istioctl install` 命令。这种变化意味着在 1.5 版本中弃用了旧版 Helm Chart。许多新的 Istio 功能依赖于新的安装方法，因此 Istio 1.6 不包括旧版 Helm Chart。

在继续之前，请查看 [Istio 1.5 升级说明](/news/releases/1.5.x/announcing-1.5/upgrade-notes/#control-plane-restructuring)，因为 Istio 1.5 引入了几个在旧版安装方法中不存在的更改，例如 Istiod 和 Telemetry v2。

要从使用 Helm Chart的旧版安装方法安全升级，请执行[控制平面修订](/blog/2020/multiple-control-planes/)。不支持原地升级。升级可能会导致停机时间，除非您执行 [金丝雀升级](/docs/setup/upgrade/#canary-upgrades)。

## 不再支持 `v1alpha1` 安全策略

Istio 1.6 不再支持以下安全策略 API：

- [`v1alpha1` 认证策略](https://archive.istio.io/v1.4/docs/reference/config/security/istio.authentication.v1alpha1/)
- [`v1alpha1` RBAC 策略](https://archive.istio.io/v1.4/docs/reference/config/security/istio.rbac.v1alpha1/)

从 Istio 1.6 开始，Istio 忽略这些 `v1alpha1` 安全策略 API。

Istio 1.6 使用以下 API 替换了 `v1alpha1` 认证策略：

- [`v1beta1` 请求认证策略](/docs/reference/config/security/request_authentication)
- [`v1beta1` 对等方认证策略](/docs/reference/config/security/peer_authentication)

Istio 1.6 使用 [`v1beta1` 授权策略 API](/docs/reference/config/security/authorization-policy/) 替换了 `v1alpha1` RBAC 策略 API。

请使用以下命令验证集群中是否存在 `v1alpha1` 安全策略：

{{< text bash >}}
$ kubectl get policies.authentication.istio.io --all-namespaces
$ kubectl get meshpolicies.authentication.istio.io --all-namespaces
$ kubectl get rbacconfigs.rbac.istio.io --all-namespaces
$ kubectl get clusterrbacconfigs.rbac.istio.io --all-namespaces
$ kubectl get serviceroles.rbac.istio.io --all-namespaces
$ kubectl get servicerolebindings.rbac.istio.io --all-namespaces
{{< /text >}}

如果集群中存在任何 `v1alpha1` 安全策略，请在升级之前迁移到新的 API。

## 安装期间的 Istio 配置

早期的 Istio 版本在安装期间部署配置对象。这些对象的存在导致以下问题：

- 升级问题
- 令人困惑的用户体验
- 安装不够灵活

为解决这些问题，Istio 1.6 最小化了安装期间部署的配置对象。

以下配置受到影响：

- `global.mtls.enabled`：配置已删除，避免混淆。已启用配置对等身份验证策略[严格的 mTLS](/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode)。
- 在安装期间不会部署默认的 `Gateway` 和相关的 `Certificate` 自定义资源。请转到 [Ingress 任务](/docs/tasks/traffic-management/ingress/)，为您的网格配置网关。
- Istio 不再为遥测插件创建 `Ingress` 自定义资源。访问[远程访问遥测插件](/docs/tasks/observability/gateways/)，了解如何从外部访问插件。
- 默认的 sidecar 配置不再通过自动生成的 `Sidecar` 自定义资源来定义。默认配置在内部实现，更改对部署没有影响。

## 通过外部工作负载访问 Istiod

在 Istio 1.6 中，Istiod 默认配置为 `cluster-local`。启用 `cluster-local` 后，仅在同一集群中运行的工作负载才能访问 Istiod。其他集群上的工作负载只能通过 Istio 网关访问 Istiod 实例。此配置可防止主控制面的入口网关错误地将服务发现请求转发到远程集群中的 Istiod 实例。Istio 团队正在积极研究替代方案，以不再需要 `cluster-local`。

要覆盖默认的 `cluster-local` 行为，请修改 `MeshConfig` 部分中的配置，如下所示：

{{< text yaml >}}
values:
  meshConfig:
    serviceSettings:
      - settings:
          clusterLocal: false
        hosts:
          - "istiod.istio-system.svc.cluster.local"
{{< /text >}}
