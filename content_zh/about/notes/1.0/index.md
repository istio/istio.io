---
title: Istio 1.0
weight: 92
---

我们很自豪地发布了 Istio 1.0！ Istio 至今已经开发了近两年，1.0 版本对我们来说是一个重要的里程碑。我们所有的[核心功能](/about/feature-stages/)现在都可以用于生产。

这些发行说明描述了 Istio 1.0 与 Istio 0.8 之间的不同之处。 Istio 1.0 只有一些相对于 0.8 的新功能，因为此版本的大部分工作都用于修复错误和提高性能。

## 网络

- **使用 Virtual Service 进行 SNI 路由**。[`VirtualService`](/docs/reference/config/istio.networking.v1alpha3/#VirtualService) 中新引入的 TLS 部分可用于根据 SNI 值路由 TLS 流量。名为 TLS/HTTPS 的服务端口可与虚拟服务 TLS 路由一起使用。没有附带虚拟服务的 TLS/HTTPS 端口将被视为不透明 TCP。
- **流式 gRPC 恢复**。Istio 0.8 导致长时间运行的流 gRPC 连接的周期性终止。这已在 1.0 中修复。
- **旧版本（v1alpha1）的网络 API 被移除**。 已删除对旧的 `v1alpha1` 流量管理模型的支持。
- **Istio Ingress 被弃用**。Istio Ingress 已弃用。默认情况下，旧的 Istio ingress 已被弃用和禁用。我们鼓励用户使用 [gateway](/docs/concepts/traffic-management/#gateways)。

## 策略和遥测

- **属性更新**。用于描述流量来源和目的地的一组[属性](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)已经完全改进，以便更加精确和全面。
- **缓存策略检查**。Mixer 现在具有用于策略检查的大型 2 级缓存，补充了 sidecar 代理中存在的 1 级缓存。这进一步减少了外部强制执行的策略检查的平均延迟。
- **遥测缓冲**。Mixer 现在在调度到适配器之前缓冲报告调用，这使适配器有机会以更大的块处理遥测数据，从而减少了 Mixer 及其适配器的总体计算开销。
- **进程外适配器**。Mixer 现在包括对进程外适配器的初始支持。这是与 Mixer 集成的推荐方法。关于如何构建进程外适配器的初始文档见[进程外 个PRC 适配器开发指南](https://github.com/istio/istio/wiki/Out-Of-Process-gRPC-Adapter-Dev-Guide)和 [gRPC 适配器开发解析](https://github.com/istio/istio/wiki/gRPC-Adapter-Walkthrough)。
- **客户端遥测**。除了服务器端遥测之外，现在可以从交互的客户端收集遥测。

### 适配器

- **SignalFX**。这是新的 [`signalfx`](/docs/reference/config/policy-and-telemetry/adapters/signalfx/) 适配器。

- **Stackdriver**。此版本中的 [`stackdriver`](/docs/reference/config/policy-and-telemetry/adapters/stackdriver/) 适配器已得到充分增强，以添加新功能并提高性能。

## 安全

- **授权**。我们重新实现了[授权功能](/docs/concepts/security/#authorization)。现在可以在不需要 Mixer 和 Mixer 适配器的情况下实现 RPC 级授权策略。
- **改进的相互 TLS 认证控制**。现在，在服务之间[控制相互 TLS 身份验证](/docs/concepts/security/#authentication)变得更加容易。我们提供 “PERMISSIVE” 模式，以便您可以逐步为您的服务启用相互 TLS。我们删除了服务注解，并采用了[一种独特的方法来启用相互 TLS](/docs/tasks/security/authn-policy/)，以及客户端[目标规则](/docs/concepts/traffic-management/#destination-rules)。
- **JWT Authentication**. We now support [JWT authentication](/docs/concepts/security/#authentication) which can
  be configured using [authentication policies](/docs/concepts/security/#authentication-policies).
- **JWT 认证**。我们现在支持可以使用[身份验证策略](/docs/concepts/security/#authentication-policies)配置的 [JWT身份验证](/docs/concepts/security/#authentication)。

## `istioctl`

- 添加了 [`istioctl authn tls-check`](/docs/reference/commands/istioctl/#istioctl-authn-tls-check) 命令。

- 添加了 [`istioctl proxy-status`](/docs/reference/commands/istioctl/#istioctl-proxy-status) 命令。

- 添加了 `istioctl experimental convert-ingress` 命令。

- 移除了 `istioctl experimental convert-networking-config` 命令。

- 增强和 bug 修复：

    - `istioctl` 和 `kubectl` 对 `kubeconfig` 的使用相同。
    - `istioctl get all`  返回网络和身份验证配置的所有类型。
    - 在 `istioctl get` 命令中添加 `--all-namespaces` 标志，可用于检索所有 namespace 中的资源。

## 1.0 的已知问题

- 亚马逊的 EKS 服务尚未实现自动 sidecar 注入。通过使用 [Helm 参数](/docs/setup/kubernetes/helm-install) `--set galley.enabled=false` [手动注入](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection) sidecar 并关闭 galley，可以在亚马逊的 EKS 中使用 Istio。
- 在[多集群部署](/docs/setup/kubernetes/multicluster-install)中，mixer-telemetry 和 mixer-policy 组件不会连接到任何远程集群的 Kubernetes API 端点。这将导致遥测保真度受损，因为与远程集群上的工作负载相关联的一些元数据不完整。
- 当前有 Kubernetes 清单文件可用于独立启用 Citadel 或执行 Citadel 运行状况检查。这些模型还没有通过 Helm 实现。有关详细信息，请参见 [Issue 6922](https://github.com/istio/istio/issues/6922)。
