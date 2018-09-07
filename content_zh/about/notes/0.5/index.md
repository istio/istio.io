---
title: Istio 0.5
weight: 96
icon: /img/notes.svg
---

在平淡无奇的问题修复和性能增强之外，这一版本包含了部分全新的功能，以及对现有功能的改进，具体包括以下内容。

{{< relnote_links >}}

## 网络

- **Istio 的渐进式部署（预览）**：现在可以仅安装需要的 Istio 组件，也就是用渐进的方式来采用 Istio（例如仅安装 Pilot+Ingress 这样的最小化组合）。`istioctl` 客户端工具可以生成自定义 Istio 部署的信息。

- **Sidecar 的自动注入**：[Mutating webhook](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.9.md#api-machinery) 是 Kubernetes 1.9 中的新功能，Istio 借助这一功能提供了自动的 Pod 级别的 Sidecar 注入能力。自动注入需要 Kubernetes 1.9 或者更高版本。Alpha 版本中使用的 Initializer 已经过时并不再使用。[参考资料](/zh/docs/setup/kubernetes/sidecar-injection/#sidecar-的自动注入)

- **通信规则的修改**：根据用户反馈，我们对 Istio 的通信管理（路由规则、目标规则等）做出了显著改进。未来几周中我们会持续对这方面的功能进行打磨，欢迎反馈。

## Mixer 适配器

- **Open Policy Agent**：Mixer 实现了一个实现了 [open policy agent](https://www.openpolicyagent.org) 授权模型的适配器，其中实现了有弹性的粒度合理的访问控制机制。[参考资料](https://docs.google.com/document/d/1U2XFmah7tYdmC5lWkk3D43VMAAQ0xkBatKmohf90ICA)

- **Istio RBAC**：Mixer 有了一套基于角色的访问控制适配器。[参考资料](/zh/docs/concepts/security/#授权和鉴权)

- **`Fluentd`**：Mixer 新增了使用 [fluentd](https://www.fluentd.org) 进行日志收集的功能。

- **`Stdio`**：该适配器可以将日志存储到主机的本地文件，并且支持日志的翻转和备份功能。

## 安全

- **自有 CA**：自有 CA 功能有了很多增强。[参考资料](/zh/docs/tasks/security/plugin-ca-cert/)

- **PKCS8**：在 Istio PKI 中加入了 PKCS8 密钥支持。

- **Istio RBAC**：Istio RBAC 为 Istio 服务网格中的服务提供了访问控制能力。[参考资料](/zh/docs/concepts/security/#授权和鉴权).

## 其它

- **发布模式**：二进制文件以及安装缺省参数都设置为发布模式，从而提供更好的性能和安全性。

- **组件日志**：Istio 组件提供了一系列丰富的命令行参数，可以对包括日志翻转等功能的本地日志行为进行定制。

- **一致的版本报告**：Istio 组件提供了一致的命令行接口用来报告版本信息。

- **可选的 Instance 字段**：定义 Mixer Instance 的时候不再需要包含相关 Template 中的所有字段了，被省略掉的资源会被赋值为 0 或空值。

## 已知问题

- Helm chart 安装方式目前不可用。

- Sidecar 自动注入功能只在 1.9 或更新的 Kubernetes 上支持。
