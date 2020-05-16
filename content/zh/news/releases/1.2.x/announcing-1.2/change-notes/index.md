---
title: 变更说明
description: Istio 1.2 发布说明。
weight: 10
aliases:
    - /zh/about/notes/1.2
---

## 通用功能 {#general}

- **增加** `traffic.sidecar.istio.io/includeInboundPorts` 标注可以让服务所有者不需要在 deployment yaml 文件中配置 `containerPort` 字段。这会是未来版本中的默认做法。
- **增加** 对 Kubernetes 集群的 IPv6 试验性支持。

## 流量管理 {#traffic-management}

- **改进** 在多集群环境中[基于位置的路由](/zh/docs/ops/configuration/traffic-management/locality-load-balancing/)功能。
- **改进** [`ALLOW_ANY` 模式](/zh/docs/reference/config/installation-options/#global-options)出站流量策略。在一个已存在端口上的未知 HTTP/HTTPS 主机流量将会被[按原样转发](/zh/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services)。未知流量会被记录在 Envoy 的访问日志中。
- **增加** 支持为上游服务设置 HTTP 空闲超时时间。
- **改进** Sidecar 支持 [NONE 模式](/zh/docs/reference/config/networking/sidecar/#CaptureMode) （不用 iptables）。
- **增加** 给 Envoy sidecar 配置 [DNS 刷新频率](/zh/docs/reference/config/installation-options/#global-options)的能力。减轻 DNS 服务的压力。
- **毕业** [Sidecar API](/zh/docs/reference/config/networking/sidecar/) 从 Alpha 版本发展到 Alpha API 和 Beta 运行时。

## 安全 {#security}

- **改进** 将自签名 Citadel 根证书的默认生存期延长到 10 年。
- **增加** 通过 [标注](/zh/docs/ops/configuration/mesh/app-health-check/#use-annotations-on-pod) `PodSpec` 中`sidecar.istio.io/rewriteAppHTTPProbers: "true"` 字段，Kubernetes 的健康检查探测器会重写每个 deployment。
- **增加** 支持给 Istio 双向 TLS 证书配置密钥路径。更多信息请看[这里](https://github.com/istio/istio/issues/11984)。
- **增加** 通过启用 Citadel 上的 `pkcs8-keys` 来支持 workload 使用 [PKCS 8](https://en.wikipedia.org/wiki/PKCS_8) 私钥。
- **改进** JWT 公钥获取逻辑在网络失败的时候更可靠。
- **修复** workload 证书中的 [SAN](https://tools.ietf.org/html/rfc5280#section-4.2.1.6) 字段设置为 `critical`。这是修复了一些自定义证书验证服务无法验证 Istio 证书的问题。
- **修复** 重写了 HTTPS 的双向 TLS 探测。
- **毕业** [入口网关多证书支持的 SNI](/zh/docs/reference/config/networking/gateway/) 从 Alpha 版本发展到了稳定版。
- **毕业** [入口网关证书管理](/zh/docs/tasks/traffic-management/ingress/secure-ingress-sds/)从 Alpha 版本发展到了 Beta 版。

## 遥测 {#telemetry}

- **增加** 通过用户标注统计字段前缀、后缀和正则表达式的方式，全面支持对 Envoy 统计生成的控制。
- **修改** Prometheus 产生的流量排除在统计度量之外。
- **增加** 支持发送追踪信息到 Datadog。
- **毕业** [分布式追踪](/zh/docs/tasks/observability/distributed-tracing/)从 Beta 版本发展到了稳定版。

## 策略 {#policy}

- **修复** [基于 Mixer](https://github.com/istio/istio/issues/13868) 的 TCP 策略执行。
- **毕业** [认证 (RBAC)](/zh/docs/reference/config/security/istio.rbac.v1alpha1/) 从 Alpha 版本发展到 Alpha API 和 Beta 运行时。

## 配置管理 {#configuration-management}

- **改进** 对策略和 CRD 遥测的验证。
- **毕业** 基本资源配置验证从 Alpha 版本发展到了 Beta 版。

## 安装和升级 {#installation-and-upgrade}

- **更新** 默认代理内存大小限制 (`global.proxy.resources.limits.memory`) 从 `128Mi` 扩大到 `1024Mi`，以此保证代理有充足的内存。
- **增加** pod 的[反亲和性](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)和[容错](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)功能支持了所有的控制平面组件。
- **增加** `sidecarInjectorWebhook.neverInjectSelector` 和 `sidecarInjectorWebhook.alwaysInjectSelector` 配置，通过标签选择器让用户可以进一步控制 workload 是否应该自动注入 sidecar。
- **增加** `global.logging.level` 和 `global.proxy.logLevel` 配置，允许用户方便的给控制平面和数据平面组件全局的配置日志。
- **增加** 支持通过设置 [`global.tracer.datadog.address`](/zh/docs/reference/config/installation-options/#global-options) 来配置 Datadog 的地址。
- **移除** 默认情况下禁止使用早期[被弃用](https://discuss.istio.io/t/deprecation-notice-custom-mixer-adapter-crds/2055)的适配器和 CRD 模版。可以使用 `mixer.templates.useTemplateCRDs=true` 和 `mixer.adapters.useAdapterCRDs=true` 安装配置项来重新启用这两个功能。

要看全部的变动，请参阅[安装选项变动页面](/zh/news/releases/1.2.x/announcing-1.2/helm-changes/)。

## `istioctl` 和 `kubectl` {#Istio-control-and-Kube-control}

- **毕业** `istioctl verify-install` 走出实验标签。
- **改进** `istioctl verify-install` 可以验证给定的 Kubernetes 环境是否满足 Istio 的要求。
- **增加** `istioctl` 支持自动完成功能。
- **增加** `istioctl experimental dashboard` 允许用户方便的打开任意 Istio 插件的 web UI。
- **增加** `istioctl x` 别名可以方便的运行 `istioctl experimental` 命令。
- **改进** `istioctl version` 默认展示 Istio 控制平面和 `istioctl` 自己的版本信息。
- **改进** `istioctl validate` 验证 Mixer 配置，并且支持完整关联的深度验证。

## 杂项 {#miscellaneous}

- **增加** [Istio CNI 支持](/zh/docs/setup/additional-setup/cni/)以设置 sidecar 网络重定向，并移除需要 `NET_ADMIN` 功能的 `istio-init` 容器。
- **增加** 新实验功能 ['a-la-carte' Istio 安装器](https://github.com/istio/installer/wiki)可以让用户以所希望的独立和安全的方式安装和升级 Istio。
- **增加** 除了命令行参数外，[支持以环境变量和配置文件](https://docs.google.com/document/d/1M-qqBMNbhbAxl3S_8qQfaeOLAiRqSBpSgfWebFBRuu8/edit)的方式来配置 Galley。
- **增加** [ControlZ](/zh/docs/ops/diagnostic-tools/controlz/) 支持在 Galley 中可视化 MCP 服务的状态。
- **增加** 在 Galley 中通过 [`enableServiceDiscovery` 命令行参数](/zh/docs/reference/commands/galley/#galley-server)来控制服务发现模块。
- **增加** Galley 和 Pilot 中的 `InitialWindowSize` 和 `InitialConnWindowSize` 参数允许微调 MCP (gRPC) 的链接设置。
- **毕业** Galley 的配置处理从 Alpha 版本发展到了 Beta 版。
