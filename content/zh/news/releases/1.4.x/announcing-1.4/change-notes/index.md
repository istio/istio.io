---
title: 变更说明
description: Istio 1.4 发行版说明.
weight: 10
---

## 流量管理{#traffic-management}

- **新增了** 对 [mirroring](/zh/docs/tasks/traffic-management/mirroring/) 百分比的流量支持。
- **改进了**  `Envoy sidecar`。当 `Envoy sidecar` 崩溃退出时，可以更轻松地查看 `Envoy sidecar` 的状态。
- **改进了** `Pilot` 的功能，当无需修改时，即可跳过向 `Envoy` 发送冗余配置的操作。
- **改进了** `headless` 服务，以避免与同一端口上的不同服务发生冲突。
- **禁用了** 默认的 [circuit breakers](/zh/docs/tasks/traffic-management/circuit-breaking/)。
- **更新了** 正则表达式引擎为 `re2`。有关详细信息，请参阅[升级说明](/zh/news/releases/1.4.x/announcing-1.4/upgrade-notes)。

## 安全{#security}

- **新增了**  [`v1beta1` authorization policy model](/zh/blog/2019/v1beta1-authorization-policy/) 用于执行访问控制。 最终将取代 [`v1alpha1` RBAC policy](/zh/docs/reference/config/security/istio.rbac.v1alpha1/)。
- **新增了** [automatic mutual TLS](/zh/docs/tasks/security/authentication/auto-mtls/) 的实验性支持，以启用 `mutual TLS`，而无需配置目标规则。
- **新增了** 对 [authorization policy trust domain migration](/zh/docs/tasks/security/authorization/authz-td-migration/) 的实验性支持。
- **新增了** 实验性的 [DNS certificate management](/zh/blog/2019/dns-cert/) 以安全地配置和管理 `Kubernetes CA` 签名的 `DNS` 证书。
- **改进了** `Citadel` ，以在自签名 `CA` 模式下运行时定期检查和更换过期的根证书。

## 遥测{#telemetry}

- **新增了** 在 [Stackdriver](https://github.com/istio/proxy/blob/{{< source_branch_name >}}/extensions/stackdriver/README.md) 中的实验性的代理遥测报告。
- **改进了** 对 `HTTP` 服务指标监控的[代理](/zh/docs/ops/configuration/telemetry/in-proxy-service-telemetry/) `Prometheus` ，(从实验到 `alpha`)。
- **改进了** 遥测收集功能，用于[阻止和传递外部流量](/zh/blog/2019/monitoring-external-service-traffic/)。
- **新增了** 为 `Envoy` [静态模式](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig)配置的选项。
- **新增了** `inbound` 和 `outbound` 对 `Envoy HTTP stats` 特定通信方向的描述。
- **改进了** 对通过出口网关流量的遥测报告。

## 配置管理{#configuration-management}

- **新增了** 多个验证和检查在 [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 子命令中。
- **新增了** 实验性选项，以启用 `Istio` [resource statuses](/zh/docs/ops/diagnostic-tools/istioctl-analyze/#enabling-validation-messages-for-resource-status) 的验证消息。
- **新增了** 对自定义资源 (`CRDs`) 的 `OpenAPI v3` 模式验证，有关详细信息，请参阅[升级说明](/zh/news/releases/1.4.x/announcing-1.4/upgrade-notes)。
- **新增了** [client-go](https://github.com/istio/client-go) 存储库来访问 `Istio APIs`。

## 安装{#installation}

- **新增了** 对 `Istio` 动态安装更新的实验性 [operator controller](/zh/docs/setup/install/standalone-operator/)。
- **移除了** `proxy_init` 镜像，`istio-init` 容器重新使用 `proxyv2` 镜像。
- **更新了** 基础镜像为 `ubunutu:bionic`。

## `istioctl`

- **新增了** 子命令 [`istioctl proxy-config logs`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-config-log)，检索和更新 `Envoy` 日志记录级别。
- **更新了** 子命令 [`istioctl authn tls-check`](/zh/docs/reference/commands/istioctl/#istioctl-authn-tls-check)，以显示正在使用的策略。
- **新增了** 实验性子命令 [`istioctl experimental wait`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-wait)，以使 `Istio` 等待，直到它已将配置推送到所有的 `Envoy sidecars`。
- **新增了** 实验性子命令 [`istioctl experimental multicluster`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-multicluster)，以帮助跨集群管理 `Istio`。
- **新增了** 实验性子命令 [`istioctl experimental post-install webhook`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-post-install-webhook) 去 [安全配管 webhook](/zh/blog/2019/webhook/)。
- **新增了** 实验性子命令 [`istioctl experimental upgrade`](/zh/docs/setup/upgrade/istioctl-upgrade/) 去执行 `Istio` 的升级。
- **改进了** 子命令 [`istioctl version`](/zh/docs/reference/commands/istioctl/#istioctl-version)，它现在显示的是 `Envoy proxy` 的版本。
