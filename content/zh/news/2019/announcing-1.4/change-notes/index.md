---
title: 更新说明
description: Istio 1.4 发布说明。
weight: 10
---

## 流量管理{#traffic-management)

- **新增** 支持[镜像](/zh/docs/tasks/traffic-management/mirroring/)一定百分比的流量。
- **改进** Envoy sidecar。Envoy sidecar 现在在崩溃时会退出。这个更改让对 Envoy sidecar 是否健康的观察更加轻松。
- **改进** Pilot 以在没有必需的改变时避免向 Envoy 发送重复的配置。
- **改进** headless 服务以防止同一端口的不同服务发生冲突。
- **禁用** 默认的[熔断](/zh/docs/tasks/traffic-management/circuit-breaking/)。
- **更新** 默认的正则表达式引擎为 `re2`。详情请参考[升级说明](/zh/news/2019/announcing-1.4/upgrade-notes)。

## 安全{#security}

- **新增** 用于执行访问控制的[`v1beta1` 授权策略模型](/zh/blog/2019/v1beta1-authorization-policy/)。这最终将取代[`v1alpha1` RBAC 策略](/zh/docs/reference/config/security/istio.rbac.v1alpha1/)。
- **新增** 对[自动双向 TLS](/zh/docs/tasks/security/authentication/auto-mtls/) 的实验性支持，以启用双向 TLS ，而无需配置目标规则。
- **新增** 对[授权策略信任域迁移](/zh/docs/tasks/security/authorization/authz-td-migration/)的实验性支持。
- **新增** 实验性 [DNS 证书管理](/zh/blog/2019/dns-cert/)，以安全地配置和管理 Kubernetes CA 签名的 DNS 证书。
- **改进** Citadel，以在自签名 CA 模式下运行时定期检查和轮换过期的根证书。

## 遥测{#telemetry}

- **新增** 发往 [Stackdriver](https://github.com/istio/proxy/blob/{{< source_branch_name >}}/extensions/stackdriver/README.md) 的实验性代理内遥测报告。
- **改进** 对[代理内](/zh/docs/ops/telemetry/in-proxy-service-telemetry/) Prometheus HTTP 服务指标生成（从实验到Alpha）的支持。
- **改进** 遥测收集功能，以[阻止和传递外部服务流量](/zh/blog/2019/monitoring-external-service-traffic/)。
- **新增** 为 Envoy 统计配置[统计模式](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig)的选项。
- **新增** `inbound` 和 `outbound` 前缀以在 Envoy HTTP 统计中指定流量方向。
- **改进** 对通过出口网关的流量的遥测报告。

## 配置管理{#configuration-management}

- **新增** [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 子命令的多项验证检查。
- **新增** 实验性选项以启用 Istio [资源状态](/zh/docs/ops/diagnostic-tools/istioctl-analyze/#enabling-validation-messages-for-resource-status)的验证消息。
- **新增** 自定义资源定义（CRDs）的 OpenAPI v3 模式验证。详情请参考[升级说明](/zh/news/2019/announcing-1.4/upgrade-notes)。
- **新增** [client-go](https://github.com/istio/client-go) 库以访问 Istio APIs。

## 安装{#installation}

- **新增** 实验性 [operator 控制器](/zh/docs/setup/install/standalone-operator/)，用于动态更新 Istio 安装。
- **移除** `proxy_init` Docker 镜像。`istio-init` 容器重用了 `proxyv2` 镜像。
- **更新** 基础镜像为 `ubunutu:bionic`。

## `istioctl`

- **新增** [`istioctl proxy-config logs`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-config-log) 子命令以检索和更新 Envoy 日志级别。
- **更新** [`istioctl authn tls-check`](/zh/docs/reference/commands/istioctl/#istioctl-authn-tls-check) 子命令以显示正在使用哪条策略。
- **新增** 实验性 [`istioctl experimental wait`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-wait) 子命令以让 Istio 等待，直到它将配置推送到所有的 Envoy sidecars。
- **新增** 实验性 [`istioctl experimental mulitcluster`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-multicluster) 子命令以协助跨多集群管理 Istio。
- **新增** 实验性 [`istioctl experimental post-install webhook`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-post-install-webhook) 子命令以[安全地管理 webhook 配置](/zh/blog/2019/webhook/)。
- **新增** 实验性 [`istioctl experimental upgrade`](/zh/docs/setup/upgrade/istioctl-upgrade/) 子命令以执行 Istio 更新。
- **改进** [`istioctl version`](/zh/docs/reference/commands/istioctl/#istioctl-version) 子命令。它现在可以显示 Envoy 代理的版本。
