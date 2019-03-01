---
title: Istio 1.1
publishdate: 2018-03-01
icon: notes
---

TBD

{{< relnote_links >}}

## 策略与遥测

- **Kiali**。Service Graph 已经被[弃用](https://github.com/istio/istio/issues/9066)，推荐使用 [Kiali](https://www.kiali.io)。查看 [Kiali 任务](/zh/docs/tasks/telemetry/kiali/)了解更多关于 Kiali 的信息。

## 安全

- 弃用的 `RbacConfig` 被 `ClusterRbacConfig` 代替，以正确实现针对集群范围。
  参考我们的指南 [迁移 `RbacConfig` 到 `ClusterRbacConfig`](/zh/docs/setup/kubernetes/upgrade/#迁移-rbacconfig-到-clusterrbacconfig) 中的迁移说明。

## `istioctl`

- 弃用 `istioctl create`，`istioctl replace`， `istioctl get` 和 `istioctl delete`。使用 `kubectl` 代替（参考<https://kubernetes.io/docs/tasks/tools/install-kubectl>）。下个版本（1.2）将删除这些弃用的命令。
- 弃用 `istioctl gen-deploy`。使用 [`helm template`](/zh/docs/setup/kubernetes/install/helm/#方案-1-使用-helm-template-进行安装) 代替。下个版本（1.2）将删除这些弃用的命令。

- 为 Istio Kubernetes 资源的离线校验增加 [`istioctl validate`](/docs/reference/commands/istioctl/#istioctl-validate)。其目的是代替已经弃用的 `istioctl create` 命令。

- 增加 [`istioctl experimental verify-install`](/docs/reference/commands/istioctl/#istioctl-experimental-verify-install)。这个实验命令验证给的 Istio 安装 YAML 文件的安装状态。

## 配置

- 你现在可以使用 Galley 作为 Kubernetes 和其他 Istio 组件（Pilot 和 Mixer）的 Kubernetes 接触点。这个功能处于  [alpha](/zh/about/feature-stages/#功能阶段定义) 版本。后续的 Istio 版本将使用 Galley 作为 Istio 默认的配置管理机制。


