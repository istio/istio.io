---
title: Istio 0.5 发布公告
linktitle: 0.5
subtitle: 重大更新
description: Istio 0.5 发布公告。
publishdate: 2018-02-02
release: 0.5.0
aliases:
    - /zh/about/notes/older/0.5
    - /zh/about/notes/0.5/index.html
    - /zh/news/2018/announcing-0.5
    - /zh/news/announcing-0.5
---

除了常规的 bug 修复和性能改进，该版本还新增或更新了以下特性。

{{< relnote >}}

## 网络{#networking}

- **渐进式部署 Istio**。（预览）现在，通过仅安装所需的组件（例如，仅 Pilot + Ingress 作为最小化的 Istio 安装），您可以比以前更轻松地逐步采用 Istio。请参考 `istioctl` CLI 工具，以生成有关自定义 Istio 部署的信息。

- **自动注入 Proxy**。我们利用 Kubernetes 1.9 的新 [muting webhook 特性](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.9.md#api-machinery) 提供 Pod 级的自动注入。自动注入需要 Kubernetes 1.9 或更高版本，因此不适用于旧版本。不再支持 alpha 初始化机制。[了解更多](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)

- **改进流量规则**。根据用户反馈，我们对 Istio 的流量管理（路由规则，目标规则等）进行了重大更改。在接下来的几周中，我们会不断完善您的反馈，希望我们能继续为您提供帮助。

## Mixer 适配器{#mixer-adapters}

- **Open Policy Agent**。现在，Mixer 有一个实现了 [open policy agent](https://www.openpolicyagent.org) 模型的适配器，可提供灵活的细粒度访问控制机制。[了解更多](https://docs.google.com/document/d/1U2XFmah7tYdmC5lWkk3D43VMAAQ0xkBatKmohf90ICA)

- **Istio RBAC**。现在，Mixer 有了一个基于角色的访问控制适配器。[了解更多](/zh/docs/concepts/security/#authorization)

- **Fluentd**。现在，Mixer 提供了一个通过 [Fluentd](https://www.fluentd.org) 收集日志的适配器。[了解更多](/zh/docs/tasks/observability/logs/fluentd/)

- **Stdio**。现在，Stdio 适配器使您可以将日志记录到文件，并支持日志轮转、备份以及大量控件。

## 安全{#security}

- **使用你自己的 CA**。多项针对 ‘使用你自己的 CA’ 特性的改进。[了解更多](/zh/docs/tasks/security/citadel-config/plugin-ca-cert/)

- **PKCS8**。将 PKCS8 密钥的支持添加到 Istio PKI。

- **Istio RBAC**。Istio RBAC 为 Istio 网格中的服务提供了访问控制。[了解更多](/zh/docs/concepts/security/#authorization)

## 其它{#other}

- **发行版二进制文件**。我们已将版本和安装默认值切换至发行版，以提高性能和安全性，

- **组件日志**。Istio 组件现在提供了一组丰富的命令行选项来控制本地日志记录，包括对日志轮换的通用支持。

- **一致的版本报告**。Istio 组件现在提供了一致的命令行界面来报告其版本信息。

- **可选的实例字段**。在配置中，Mixer 实例的定义不再需要包含关联模板的每个字段。缺省字段的值将为零或空值。

## 已知问题{#known-issues}

- Helm charts 安装目前无法使用。

- sidecar 自动注入仅支持 Kubernetes 1.9 及以后的版本。
