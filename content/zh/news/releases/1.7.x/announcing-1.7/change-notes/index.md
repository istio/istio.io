---
title: 变化说明
description: Istio 1.7 发布说明。
weight: 10
---

## 流量管理{#traffic-management}

- **新增** 配置选项 `values.global.proxy.holdApplicationUntilProxyStarts`，它使 Sidecar 注入器在 Pod 的容器列表的开始处注入 Sidecar，并配置它阻止所有其他容器的启动，直到代理准备好为止。默认情况下禁用此选项。
 ([Issue #11130](https://github.com/istio/istio/issues/11130))
- **新增** SDS 支持客户证书和用于 [TLS/mTLS 从出口网关发起](/zh/docs/tasks/traffic-management/egress/egress-gateway-tls-origination/)的 CA 证书，使用 `DestinationRule`。
  ([Issue #14039](https://github.com/istio/istio/issues/14039))

## 安全{#security}

- **优化** 信任域验证也可以验证 TCP 流量，以前只有 HTTP 流量被验证。
([Issue #26224](https://github.com/istio/istio/issues/26224))
- **优化** 当服务器的 TLS 模式为 `ISTIO_MUTUAL` 时，Istio 网关允许使用基于源委托的授权。
([Issue #25818](https://github.com/istio/istio/issues/25818))
- **优化** VM 安全。VM 的身份现在从一个暂时性的 Kubernetes 服务帐户令牌 Token 中启动。VM 的工作负载证书会自动轮换。
 ([Issue #24554](https://github.com/istio/istio/issues/24554))

## 遥测{#telemetry}

- **新增** Prometheus 指标度量到 Istio 代理。
 ([Issue #22825](https://github.com/istio/istio/issues/22825))
- **新增** 使用 `istioctl` 自定义指标度量。
  ([Issue #25963](https://github.com/istio/istio/issues/25963))
- **新增** TCP 度量标准和到 Stackdriver 的访问日志。
 ([Issue #23134](https://github.com/istio/istio/issues/23134))
- **废弃** 通过 `istioctl` 安装遥测插件。 默认情况下将禁用这些功能，并且在将来的版本中将其完全删除。更多关于安装插件的信息可以在[集成](/zh/docs/ops/integrations/)页面找到。
 ([Issue #22762](https://github.com/istio/istio/issues/22762))
- **启用** 默认情况下是 Prometheus [指标合并](/zh/docs/ops/integrations/prometheus/#option-1-metrics-merging)。
 ([Issue #21366](https://github.com/istio/istio/issues/21366))
- **修复** Prometheus [指标合并](/zh/docs/ops/integrations/prometheus/#option-1-metrics-merging)在应用失败时不删除 Envoy 的指标。
 ([Issue #22825](https://github.com/istio/istio/issues/22825))
- **修复** 修复影响 Kiali 图的不明遥测数据。该修复将默认的出站协议嗅探超时增加到 `5s`，这对 `mysql` 等服务器第一协议有影响。
   ([Issue #24379](https://github.com/istio/istio/issues/24379))
- **移除** `pilot_xds_eds_instances` 和 `pilot_xds_eds_all_locality_endpoints` 的 Istiod 指标度量，不正确。
 ([Issue #25154](https://github.com/istio/istio/issues/25154))

## 安装{#installation}

- **新增** RPM 软件包，用于在发行版的 VM 上运行 Istio Sidecar。
 ([Issue #9117](https://github.com/istio/istio/issues/9117))
- **新增** 实验性[外部 Istiod](/zh/blog/2020/new-deployment-model/)支持。
- **修复** 导致无法将 `NodePort` 服务用作 `meshNetworks` 中的 `registryServiceName` 的问题。
- **优化** 网关部署默认以非 Root 身份运行。
 ([Issue #23379](https://github.com/istio/istio/issues/23379))
- **优化** 默认情况下，操作员以非 Root 用户身份运行。
 ([Issue #24960](https://github.com/istio/istio/issues/24960))
- **优化** 通过指定严格的安全环境来为操作员提供帮助。
 ([Issue #24963](https://github.com/istio/istio/issues/24963))
- **优化** Istiod 默认情况下以非 Root 用户身份运行。
 ([Issue #24961](https://github.com/istio/istio/issues/24961))
- **优化** Kubernetes 战略合并用于覆盖 IstioOperator 用户文件，从而改善了列表项的处理方式。
 ([Issue #24432](https://github.com/istio/istio/issues/24432))
- **升级** CRD 和 Webhook 的版本为 `v1`。
 ([Issue #18771](https://github.com/istio/istio/issues/18771)),([Issue #18838](https://github.com/istio/istio/issues/18838))

## istioctl{#istioctl}

- **新增** 允许 [`proxy-status <pod>` 命令]](/zh/docs/reference/commands/istioctl/#istioctl-proxy-status)用于非 Kubernetes 工作负载，其代理配置由 `--file` 参数传入。
- **新增** 用于保存 Istioctl 默认标志的配置文件。它的默认位置（`$HOME/.istioctl/config.yaml`），可以通过环境变量 `ISTIOCONFIG` 更改。新的命令 `istioctl experimental config list` 显示了默认标志。
 ([Issue #23868](https://github.com/istio/istio/issues/23868))
- **新增** 在 `istioctl operator init` 和 `istioctl operator remove` 命令中加入 `--revision` 标志，可支持多个控制平面的升级。
 ([Issue #23479](https://github.com/istio/istio/issues/23479))
- **新增** `istioctl x uninstall` 命令来卸载 Istio 控制平面。
 ([Issue #24360](https://github.com/istio/istio/issues/24360))
- **优化** 在出现废弃的混合器资源时，`istioctl analyze` 会发出警告。
 ([Issue #24471](https://github.com/istio/istio/issues/24471))
- **优化** 在没有使用 `CaCertificates` 来验证服务器身份时，`istioctl analyze` 会发出警告。
- **优化** 使用 `istioctl validate` 来检查资源中的未知字段。
 ([Issue #24861](https://github.com/istio/istio/issues/24861))
- **优化** 尝试在不支持的旧 Kubernetes 版本中安装 Istio 时，`istioctl install` 会发出警告。
 ([Issue #26141](https://github.com/istio/istio/issues/26141))
- **移除** `istioctl manifest apply`。更简单的 `install` 命令取代了Manifest Apply。
 ([Issue #25737](https://github.com/istio/istio/issues/25737))

## 文档变化{#documentation-changes}

- **新增** 如果一个 istio.io 页面已经被 istio.io 自动测试所测试，还会出现提示。
 ([Issue #7672](https://github.com/istio/istio.io/issues/7672))
