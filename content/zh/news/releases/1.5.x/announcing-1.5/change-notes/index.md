---
title: 变更说明
description: Istio 1.5 发行版说明。
weight: 10
---

## 流量管理{#traffic-management}

- **改进** 通过避免不必要的完全推送 [#19305](https://github.com/istio/istio/pull/18164)，提高 `ServiceEntry` 性能。
- **改进** Envoy sidecar 就绪状态探测，可以更加准确地确定就绪状态 [#18164](https://github.com/istio/istio/pull/18164)。
- **改进** 在可能的情况下，通过 xDS 发送部分更新，以增强 Envoy 代理配置更新性能 [#18354](https://github.com/istio/istio/pull/18354)。
- **新增** 可通过目标规则为每个目标服务配置本地负载均衡设置 [#18406](https://github.com/istio/istio/pull/18406)。
- **修复** Pod 崩溃会触发过多 Envoy 代理配置推送的问题 [#18574](https://github.com/istio/istio/pull/18574)。
- **修复** 应用程序（如 headless 服务）无需通过 Envoy 代理即可直接调用自己的问题 [#19308](https://github.com/istio/istio/pull/19308)。
- **新增** 当使用 Istio CNI 时，支持 `iptables` 故障检测 [#19534](https://github.com/istio/istio/pull/19534)。
- **新增** 在目标规则中添加 `consecutiveGatewayErrors` 和 `consecutive5xxErrors` 作为异常检测选项 [#19771](https://github.com/istio/istio/pull/19771)。
- **改进** `EnvoyFilter` 的匹配性能 [#19786](https://github.com/istio/istio/pull/19786)。
- **新增** `HTTP_PROXY` 协议支持 [#19919](https://github.com/istio/istio/pull/19919)。
- **改进** `iptables` 默认设置使用 `iptables-restore`[#18847](https://github.com/istio/istio/pull/18847)。
- **改进** 通过过滤未使用的集群，提高网关性能。默认情况下禁用该设置 [#20124](https://github.com/istio/istio/pull/20124)。

## 安全{#security}

- **毕业** SDS 稳定，并默认启用。它为 Istio Envoy 代理提供身份配置。
- **新增** Beta 身份认证 API。新的 API 将对等体（即双向 TLS）和源（JWT）身份验证分别分离到 [`PeerAuthentication`](https://github.com/istio/api/blob/master/security/v1beta1/peer_authentication.proto) 和 [`RequestAuthentication`](https://github.com/istio/api/blob/master/security/v1beta1/request_authentication.proto) 中。
两个新 API 都是面向工作负载的，在 alpha 版本的 `AuthenticationPolicy` 中它们是面向服务的。
- **新增** 在授权策略中添加[拒绝语义](https://github.com/istio/api/blob/master/security/v1beta1/authorization.proto#L28)。
- **毕业** [自动双向 TLS](/zh/docs/tasks/security/authentication/authn-policy/#auto-mutual-TLS) 从 alpha 转到 beta。该特性现在默认启用。
- **改进** 通过将 Node Agent 与 Pilot Agent 作为 Istio Agent 合并，并删除跨 Pod UDS，从而提高了 [SDS 安全性](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret) ，不再需要用户为 UDS 连接部署 Kubernetes Pod 安全策略。
- **改进** 通过在 istiod 中包含证书来改进 Istio。
- **新增** [`first-party-jwt`](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/authentication/#service-account-tokens) 在 [`third-party-jwt`](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection) 不支持的集群中添加了支持 Kubernetes 作为 CSR 身份验证的后备令牌。
- **新增** 支持 Istio CA 和 Kubernetes CA 为控制平面提供证书，可以通过 `values.global.pilotCertProvider` 进行配置。
- **新增** Istio Agent 为 Prometheus 设置了密钥和证书。

## 遥测{#telemetry}

- **新增** 对 v2 版本遥测的 TCP 协议支持。
- **新增** 在指标、日志中添加 gRPC 响应状态码。
- **新增** 支持 Istio Canonical Service。
- **改进** v2 遥测管道的稳定性。
- **新增** 对 v2 遥测中可配置性的 alpha 级支持。
- **新增** 对在 Envoy 节点元数据中填充 AWS 平台元数据的支持。
- **改进** 用于 Mixer 的 Stackdriver 适配器，以通过可配置的刷新间隔跟踪数据。
- **新增** 在 Jaeger 插件中增加了对 headless 收集器服务的支持。
- **修复** `kubernetesenv` 适配器可为名字中包含点的 Pod 提供适当支持。
- **改进** 用于 Mixer 的 Fluentd 适配器，以在导出的时间戳中提供毫秒级支持。

## 配置管理{#configuration-management}

## Operator

- **替换** 将 Alpha `IstioControlPlane` API 替换为新的 [`IstioOperator`](/zh/docs/reference/config/istio.operator.v1alpha1/) API，以便与现有的 `MeshConfig` API 保持一致。
- **新增** `istioctl operator init` 和 `istioctl operator remove` 命令。
- **改进** 使用缓存 [`operator#667`](https://github.com/istio/operator/pull/667) 提高协调速度。

## `istioctl`

- **毕业** [`Istioctl Analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/)。
- **新增** 各种分析器：双向 TLS、JWT、`ServiceAssociation`、Secret、sidecar 镜像、端口名称和不建议使用的分析器。
- **更新** 支持更多针对 `RequestAuthentication` 的验证规则。
- **新增** [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 添加新参数 `-A|--all-namespaces` 以分析整个集群。
- **新增** [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 对标准输入流传递的内容进行分析的支持。
- **新增** [`istioctl analyze -L`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 打印全部分析变量。
- **新增** 功能抑制来自 [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 的消息。
- **新增** [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 添加结构化格式选项。
- **新增** [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 输出中添加指向相关内容的链接。
- **更新** Istio API 在 [`Istioctl Analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 中提供的更新注释方法。
- **更新** [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 现在可从目录加载文件。
- **更新** [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 以尝试将消息与其源文件名关联。
- **更新** [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 打印正在分析的命名空间。
- **更新** [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 默认情况下分析群集内资源。
- **修复** [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 抑制群集级资源消息的错误。
- **新增** `istioctl manifest` 对多个输入文件的支持。
- **替换** 使用 `IstioOperator` API 替换 `IstioControlPlane` API。
- **新增** [`istioctl dashboard`](/zh/docs/reference/commands/istioctl/#istioctl-dashboard) 选择器。
- **新增** [`istioctl manifest --set`](/zh/docs/reference/commands/istioctl/#istioctl-manifest) 支持切片和列表。
- **新增** `docker/istioctl` Docker 镜像（#19079）。
